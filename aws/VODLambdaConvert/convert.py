#!/usr/bin/env python

import glob
import json
import os
import uuid
import boto3
import datetime
import random
from urllib.parse import urlparse
import logging
from pymediainfo import MediaInfo 

from botocore.client import ClientError
from botocore.config import Config

logger = logging.getLogger()
logger.setLevel(logging.INFO)

S3 = boto3.resource('s3')

region = os.environ['AWS_DEFAULT_REGION']
	
def get_signed_url(expires_in, bucket, obj):
	"""
	Generate a signed URL
	:param expires_in:  URL Expiration time in seconds
	:param bucket:
	:param obj:         S3 Key name
	:return:            Signed URL
	"""
	s3_cli = boto3.client("s3", region_name=region, config = Config(signature_version = 's3v4', s3={'addressing_style': 'virtual'}))
	presigned_url = s3_cli.generate_presigned_url('get_object', Params={'Bucket': bucket, 'Key': obj}, ExpiresIn=expires_in)
	return presigned_url
	
def handler(event, context):
	'''
	Watchfolder handler - this lambda is triggered when video objects are uploaded to the 
	SourceS3Bucket/inputs folder.

	It will look for two sets of file inputs:
		SourceS3Bucket/inputs/SourceS3Key:
			the input video to be converted
		
		SourceS3Bucket/jobs/*.json:
			job settings for MediaConvert jobs to be run against the input video. If 
			there are no settings files in the jobs folder, then the Default job will be run 
			from the job.json file in lambda environment. 
	
	Ouput paths stored in outputGroup['OutputGroupSettings']['DashIsoGroupSettings']['Destination']
	are constructed from the name of the job settings files as follows:
		
		s3://<MediaBucket>/<basename(job settings filename)>/<basename(input)>/<Destination value from job settings file>

	'''

	assetID = str(uuid.uuid4())
	sourceS3Bucket = event['Records'][0]['s3']['bucket']['name']
	sourceS3Key = event['Records'][0]['s3']['object']['key']
	sourceS3 = 's3://'+ sourceS3Bucket + '/' + sourceS3Key
	destinationS3 = 's3://' + os.environ['DestinationBucket']
	mediaConvertRole = os.environ['MediaConvertRole']
	application = os.environ['Application']
	#region = os.environ['AWS_DEFAULT_REGION']
	statusCode = 200
	jobs = []
	job = {}
	video_resolution = 1080;
	resolution_outputs = []
	video_metadata = {}
	video_metadata['duration'] = 0
	video_metadata['outputs'] = []
	video_track_found = 0
	
	#########################
	# Get info from Mediainfo
	#########################
	
	if 'CHUNK' in sourceS3Key:
		
		logger.info('Ignoring Chunk')
		
	else:
		SIGNED_URL_EXPIRATION = 300     # The number of seconds that the Signed URL is valid
		
		# Generate a signed URL for the uploaded asset
		signed_url = get_signed_url(SIGNED_URL_EXPIRATION, sourceS3Bucket, sourceS3Key)	
			
		# Launch MediaInfo
		media_info = MediaInfo.parse(signed_url, library_file='/opt/libmediainfo.so.0')
		logger.info(json.dumps(media_info.to_json(),default=str))
		video_resolution = 1080;
		
		for track in media_info.tracks:
			if track.track_type == 'Video':
				if hasattr(track,'height'):
					video_resolution = track.height
					if track.width > track.height:
						video_resolution = track.width
					video_track_found = 1
				elif hasattr(track,'sampled_height'):
					video_resolution = int(track.sampled_height)
					video_track_found = 1
				if hasattr(track,'duration'):
					video_metadata['duration'] = track.duration					
					
		logger.info('video resolution %s', video_resolution)
		
		if video_resolution >= 360:
			resolution = {}
			resolution['Preset'] = '360p - Default Values'
			resolution['NameModifier'] = '360p'
			resolution_outputs.append(resolution)
			video_metadata['outputs'].append( 360 )
			
		if video_resolution >= 480:
			resolution = {}
			resolution['Preset'] = '480p - Default Values'
			resolution['NameModifier'] = '480p'
			resolution_outputs.append(resolution)
			video_metadata['outputs'].append( 480 )
			
		if video_resolution >= 720:
			resolution = {}
			resolution['Preset'] = '720p - Default Values'
			resolution['NameModifier'] = '720p'
			resolution_outputs.append(resolution)
			video_metadata['outputs'].append( 720 )
			
		if video_resolution >= 1080:
			resolution = {}
			resolution['Preset'] = '1080p - Default Values'
			resolution['NameModifier'] = '1080p'
			resolution_outputs.append(resolution)
			video_metadata['outputs'].append( 1080 )
			
		logger.info(json.dumps(resolution_outputs))
		
		# Use MediaConvert SDK UserMetadata to tag jobs with the assetID 
		# Events from MediaConvert will have the assetID in UserMedata
		jobMetadata = {}
		jobMetadata['assetID'] = assetID
		jobMetadata['application'] = application
		jobMetadata['input'] = sourceS3
	
		try:    

			# Build a list of jobs to run against the input.  Use the settings files in WatchFolder/jobs
			# if any exist.  Otherwise, use the default job.
		
			jobInput = {}
			# Iterates through all the objects in jobs folder of the WatchFolder bucket, doing the pagination for you. Each obj
			# contains a jobSettings JSON
			bucket = S3.Bucket(sourceS3Bucket)
			for obj in bucket.objects.filter(Prefix='jobs/'):
				if obj.key != "jobs/":
					jobInput = {}
					jobInput['filename'] = obj.key

					jobInput['settings'] = json.loads(obj.get()['Body'].read())
				
					jobs.append(jobInput)
		
			# Use Default job settings in the lambda zip file in the current working directory
			if not jobs:
				with open('job.json') as json_data:
					jobInput['filename'] = 'Default'

					jobInput['settings'] = json.load(json_data)

					jobs.append(jobInput)
			 
			# get the account-specific mediaconvert endpoint for this region
			mediaconvert_client = boto3.client('mediaconvert', region_name=region)
			endpoints = mediaconvert_client.describe_endpoints()

			# add the account-specific endpoint to the client session 
			client = boto3.client('mediaconvert', region_name=region, endpoint_url=endpoints['Endpoints'][0]['Url'], verify=False)
			
			for j in jobs:
				jobSettings = j['settings']
				jobFilename = j['filename']

				# Save the name of the settings file in the job userMetadata
				jobMetadata['settings'] = jobFilename

				# Update the job settings with the source video from the S3 event 
				jobSettings['Inputs'][0]['FileInput'] = sourceS3
			
				# Update the job settings with the destination paths for converted videos.  We want to replace the
				# destination bucket of the output paths in the job settings, but keep the rest of the
				# path
				destinationS3 = 's3://' + os.environ['DestinationBucket']                 
			
				# job details
				templateDestination = jobSettings['OutputGroups'][0]['OutputGroupSettings']['FileGroupSettings']['Destination']
				templateDestinationKey = urlparse(templateDestination).path
			
				jobSettings['OutputGroups'][0]['OutputGroupSettings']['FileGroupSettings']['Destination'] = destinationS3+templateDestinationKey								
				jobSettings['OutputGroups'][0]['Outputs'] = resolution_outputs
				
				# logger.info(mediaConvertRole)
				# logger.info(jobMetadata)
				logger.info(jobSettings)
				
				if video_track_found == 1:
					# Convert the video using AWS Elemental MediaConvert
					job = client.create_job(Role=mediaConvertRole, UserMetadata=jobMetadata, Settings=jobSettings)
					logger.info('mediaconvert called')
					
                    # Copy uploaded file to original folder
					copy_source_object = {'Bucket': sourceS3Bucket, 'Key': sourceS3Key}
					destinationS3Key = sourceS3Key.replace('inputs/', 'original/')
					S3.meta.client.copy(copy_source_object, 'nps-audiovideo', destinationS3Key)
					
					# Write JSON File based on filename
					logger.info('Convert Filename for JSON file')
					destinationJSON = os.path.splitext(destinationS3Key)[0]+'.json'
					destinationJSON = destinationJSON.replace('original/', 'json/')
					logger.info('writing json file %s',destinationJSON )
					logger.info(json.dumps(video_metadata))
					S3.meta.client.put_object(Body=json.dumps(video_metadata), Bucket='nps-audiovideo', Key=destinationJSON)
					
					logger.info('JSON File Written')
					
					# S3.meta.client.delete_object(Bucket=sourceS3Bucket, Key=sourceS3Key)
					
				else:
					copy_source_object = {'Bucket': sourceS3Bucket, 'Key': sourceS3Key}
					destinationS3Key = sourceS3Key.replace('inputs/', 'audiovideo/')

					S3.meta.client.copy(copy_source_object, 'nps-audiovideo', destinationS3Key)
					S3.meta.client.delete_object(Bucket=sourceS3Bucket, Key=sourceS3Key)
	
		except ClientError as error:
			logger.info(error.response['Error']['Code'])
			logger.info(error.response['Error']['Message'])
		
		except Exception as e:
			exc_type, exc_obj, exc_tb = sys.exc_info()
			logger.error('Exception: %s', e)
			logger.error('Line Number: %s', exc_tb.tb_lineno)
			statusCode = 500
			raise

		finally:
			return {
				'statusCode': statusCode,
				'body': json.dumps(job, indent=4, sort_keys=True, default=str),
				'headers': {'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*'}
			}
				
