<cftry>
	
	<cfsetting requestTimeout="3600">
	
	<cfsetting enablecfoutputonly="true">
	<cfsetting showDebugOutput="No">

	<cfparam name="form.name" type="string" default="" /> <!--- name on client --->
	<cfparam name="form.file" type="string" default="" /> <!--- location of binary tmp --->
	<cfparam name="form.chunk" type="numeric" default=0 />
	<cfparam name="form.chunks" type="numeric" default=0 />
	
	<cfparam name="url.uploadPath" type="string" /> 
	<cfparam name="url.type" type="string" />
	<cfparam name="url.filename" type="string" />
	
	<cfset cms_environment =  getEnvironmentCode()>
	
	<cfset ccuploadpath = 'nps-audiovideo/closed-caption/'>
	<cfset akamai_s3_path = 'https://www.nps.gov/nps-audiovideo/'>
	
	<cfif cms_environment neq 'PROD'>
		<cfset ccuploadpath = 'npsdev-audiovideo/closed-caption/'>
		<cfset akamai_s3_path = 'https://www.nps.gov/npsdev-audiovideo/'>
	</cfif>
	
	<cfset response = {}>/
	
	<cfset asset_type = url.type>
	
	<cfset relativeFileName = ''>
	<cfset returnString = ''>
	
	<cfset sleep( 1000 ) /> <!--- Sleep for a brief period to allow UI a chance to show. --->
	
	<cfset response['serverFilename'] = ''>
	<cfset response['totalChunks'] = 0>
	
	<cfset AccessKeyId="[AWSAccessKeyID]">
	<cfset awsSecretKey="[AWSSecretKey">
	<cfset audio_video_filename = url.filename>
	
	<cftry>

		<cfif form.chunks gt 0>
						
			<cfset fileExtension = listLast( form.name, '.' )>
			
			<cfset filePath = 's3://#accessKeyid#:#awsSecretKey#@#url.uploadPath#' & audio_video_filename & '.CHUNK' & form.chunk>
			<cfset response[ 'chunk' ] = form.chunk>
			<cfset response['totalChunks'] = form.chunks>
			
			<cffile action="upload" result="result" filefield="file" destination="#filePath#" nameconflict="makeunique" allowedExtensions="*" />						
			
			<cfscript>

			if ( not directoryExists( "s3://#accessKeyid#:#awsSecretKey#@#url.uploadPath#" ) ) {
				directoryCreate( "s3://#accessKeyid#:#awsSecretKey#@#url.uploadPath#" );
			}
		
			// reassemble chunked file
			if ( form.chunk + 1 EQ form.chunks) {
				
				filePath = 's3://#accessKeyid#:#awsSecretKey#@#url.uploadPath#' & audio_video_filename & '.#fileExtension#'; // file name for reassembled file - if using a temp directory then this should be the final output path/file
				
				//if (fileExists( filePath )){
					
				//	filePath = findUniqueFilename( filePath ); // make it unique
					
				//}
				
				// threading the action which reassebles the chunked files to avoid timeout				
				thread action='run' name='thread_#audio_video_filename#' {
				
					tempFile = fileOpen(filePath,'append');
					
					for ( i = 0; i lt form.chunks; i++) {
						chunkData = fileReadBinary('s3://#accessKeyid#:#awsSecretKey#@#url.uploadPath##audio_video_filename#.CHUNK#i#');
						fileDelete('s3://#accessKeyid#:#awsSecretKey#@#url.uploadPath##audio_video_filename#.CHUNK#i#');
						fileWrite(tempFile, chunkData);
					}
					fileClose(tempFile);

					newPath = tempFile.path;
					
					//run cleanup, for good measure
					cleanOutChunkFiles(GetFileFromPath(newPath),GetDirectoryFromPath(newPath));
				
				}
				
				if ( fileExtension neq 'mp3' ) {
					
					response['cleanedName'] = audio_video_filename & '.mp4';
					
				}
				else {
				
					response['cleanedName'] = audio_video_filename & '.mp3';
					
				}
				
			}
			
			
			</cfscript>
			
		<cfelseif asset_type neq 'thumbnail'>
			
			<cfset closed_caption_file_name = createUUID()>			
			
			<cfset fileExtension = listLast( form.name, '.' )>
			
			<cfif fileExtension eq 'vtt'>
			
				<cffile
					result="uploadedFile"
					action="upload" 
					filefield="file" 
					destination="s3://#accessKeyid#:#awsSecretKey#@#ccuploadpath##closed_caption_file_name#.#fileExtension#"  
					nameconflict="makeunique"
					/>
			
			<cfelse>
			
				<cffile
					result="uploadedFile"
					action="upload"
					filefield="file"
					destination="#GetTempDirectory()#"
					nameconflict="makeunique"
					/>
				
				<!--- <cffile action="read" file="#uploadedFile.serverDirectory#\#uploadedFile.serverFileName#.#uploadedFile.serverFileExt#" variable="nonVTTCaptionFile"> --->

				<cfset line_break = Chr(13) & Chr(10)>
				<cfset vtt_file = "WEBVTT" & line_break & line_break>				

					<!--- This is the easiest conversion as VTT is based on SRT with the only difference being the milisecond separator --->
					<!--- SRT was developed in France and thus the miliseconds separator is a comma, VTT uses a period --->
					<!--- VTT files start with "WEBVTT" and we don't use line numbers, but SRT does --->
					<!--- Begin by looping over the file line by line --->
					<cfloop file="#uploadedFile.serverDirectory#\#uploadedFile.serverFileName#.#uploadedFile.serverFileExt#" index="line" charset="utf-8">
						<!--- Remember, we don't care for SRT line numbers, so let's drop them --->
						<cfif NOT isNumeric(line)>
							<!--- Are we on a time duration line? --->
							<cfif line CONTAINS ':' AND line CONTAINS '-->'>
								<!--- We are on a duration line, so let's replace the comma with a period --->
								<cfset vtt_file = vtt_file & ReplaceNoCase(line, ",", ".", "All") & line_break>
							<cfelse>
								<cfset vtt_file = vtt_file & line & line_break>
							</cfif>
						</cfif>
					</cfloop>

					<cffile
						action="write" 
						file="s3://#accessKeyid#:#awsSecretKey#@#ccuploadpath##closed_caption_file_name#.vtt" 
						output="#vtt_file#" 						 
						nameconflict="overwrite"
						charset="utf-8"
						/>
				
			</cfif>
			
			<cfset relativeFileName = '#akamai_s3_path#closed-caption/#closed_caption_file_name#'>
			
			<cfset response.serverFilename= "#relativeFileName#.vtt">
		
		<cfelse>
			
			<!--- Test Image Size --->
			<cfset testImage = imageNew( form.file )>
			<cfset imageData = imageInfo( testImage )> 

			<cfif ( imageData.width lt 1280 OR imageData.width gt 1600 ) OR ( imageData.height lt 720 OR imageData.height gt 1200 )>
				
				<cfset return_json = {}>
				<cfset return_json.data = {"error":"fileSizeError"}>
				<cfset response = return_json>
				
			<cfelse>

				<!--- Save the file to the uploads directory. --->
				<cffile
					result="uploadedFile"
					action="upload"
					filefield="file"
					destination="#GetTempDirectory()#"
					nameconflict="makeunique"
					/>
					
				<cfset fileUniqueID = createUUID()>
				
				<cfset uploadURL = '#url.uploadPath#\#fileUniqueID#\'>
				<cfset filePath = '#uploadURL##fileUniqueID#.#lCase( uploadedFile.serverFileExt )#'>
				<cfset thumbPath = '#uploadURL##fileUniqueID#-thumbnail.#lCase( uploadedFile.serverFileExt )#'>
				<cfset largePath = '#uploadURL##fileUniqueID#-large.#lCase( uploadedFile.serverFileExt )#'>
				<cfset smallPath = '#uploadURL##fileUniqueID#-small.#lCase( uploadedFile.serverFileExt )#'>
				
				<cfdirectory action="create" directory="#expandPath( url.uploadPath & fileUniqueID )#">
				
				<cfimage
					action="write" 
					source="#uploadedFile.serverDirectory#\#uploadedFile.serverFileName#.#uploadedFile.serverFileExt#"  
					destination="#expandPath( filePath )#" 
					overwrite="yes" />
				
				<cfset originalImageInfo = getFileInfo( expandPath( filePath ) )>
				
				<cfset thumbnailImage = ImageNew( expandPath( filePath ) )>
				<cfset ImageResize( thumbnailImage, 160, 90, "blackman", 1 )>
				<cfset imageWrite( thumbnailImage, expandPath( thumbPath ) )>					
				<cfset thumbImageInfo = getFileInfo( expandPath( thumbPath ) )>
				
				<cfset smallImage = ImageNew( expandPath( filePath ) )>
				<cfset ImageResize( smallImage, 160, 90, "blackman", 1 )>
				<cfset imageWrite( smallImage, expandPath( smallPath ) )>
				<cfset smallImageInfo = getFileInfo( expandPath( smallPath ) )>
				
				<cfset largeImage = ImageNew( expandPath( filePath ) )>
				<cfset ImageResize( largeImage, 1280, 720, "blackman", 1 )>
				<cfset imageWrite( largeImage, expandPath( largePath ) )>				
				<cfset largeImageInfo = getFileInfo( expandPath( largePath ) )>
					
				
				<cfscript>
					return_json = {};
					
					return_json.data = {
						alttext = "",		
						caption = "",
						credit = "",
						description = "",
						title = "",
						location = "",
						image = {
							"CPIMAGE": "",
							"ERRORS": [],
							"SMALLIMAGEFILESIZE": #smallImageInfo.size#,
							"THUMBFILENAME": "#fileUniqueID#-thumbnail.#lCase( uploadedFile.serverFileExt )#",
							"ORIGINALFILESIZE": #originalImageInfo.size#,
							"FQIMAGE": "",
							"SMALLIMAGEWIDTH": 160,
							"SERVERRELATIVEURL": "",
							"SMALLIMAGEFILENAME": "#fileUniqueID#-small.#lCase( uploadedFile.serverFileExt )#",
							"TEMPUPLOADPATH": "/common/uploads/",
							"THUMBFILESIZE": #thumbImageInfo.size#,
							"THUMBHEIGHT": 90,
							"PAGEID": 0,
							"THUMBURL": "#thumbPath#",
							"DESCRIPTION": "",
							"LARGEIMAGEFILENAME": "#fileUniqueID#-large.#lCase( uploadedFile.serverFileExt )#",
							"THUMBWIDTH": 160,
							"SMALLIMAGEURL": "#smallPath#",
							"IMAGEHEIGHT": 720,
							"DOCTYPE": "#uploadedFile.serverFileExt#",
							"FILENAME": "#fileUniqueID#.#lCase( uploadedFile.serverFileExt )#",
							"IMAGEURL": "#filePath#",
							"UPLOADURL": "#uploadURL#",
							"SUBSITEID": 0,
							"ORIGINALHEIGHT": 720,
							"SMALLIMAGEHEIGHT": 90,
							"SMALLIMAGEFILEPATH": "#expandPath( smallPath )#",
							"DATEADDED": "",
							"FQTHUMB": "",
							"LARGEIMAGEHEIGHT": 720,
							"THUMBEXISTS": true,
							"LARGEIMAGEFILESIZE": #largeImageInfo.size#,
							"ORIGINALWIDTH": 1280,
							"LARGEIMAGEWIDTH": 1280,
							"PAGENAME": "",
							"IMAGEFILESIZE": 10.9248046875,
							"LARGEIMAGEFILEPATH": "#expandPath( largePath )#",
							"IMAGEWIDTH": 1280,
							"LARGEIMAGEEXISTS": true,
							"LARGEIMAGEURL": "#largePath#",
							"SMALLIMAGEEXISTS": true,
							"IMAGEDIR": "#expandPath( uploadURL )#",
							"THUMBDIR": "#expandPath( uploadURL )#",
							"IMAGEEXISTS": true
						}
					};
					
					response = return_json;
					
				</cfscript>
				
			</cfif>
			
		</cfif>
		
	<cfcatch type="any">	

		<cfdump var="#cfcatch#">
			
	</cfcatch>
	</cftry>

<cfcatch type="any">
	<cfdump var="#cfcatch#">
</cfcatch>
</cftry>

<cfset dtExpires = (Now() - 1) /> <!--- we never want it to be cached --->
<cfheader statuscode="201" statustext="Created" /><!--- Return a success message. --->
<cfheader name="expires" value="#GetHTTPTimeString( dtExpires )#" />
<cfheader name="Last-Modified" value="#GetHTTPTimeString( now() )#" />
<cfheader name="cache-control" value="no-cache, no-store, must-revalidate, post-check=0, pre-check=0">
<cfheader name="Pragma" value="no-cache">

<!--- this content is automagically available in the response object on the plupload client --->
<cfoutput>#serializeJSON( response )#</cfoutput>

<!--- Supporting Functions --->
	<cffunction name="cleanOutChunkFiles" returntype="struct" returnformat="json" output="false"
		description="Cleans out current file chunks and old ones (cleanup). Called on error, when a user cancels, and when a chunkset finishes uploading.">

		<cfargument name="rootFilename" required="true" 
			hint="Filename to search for" />
		<cfargument name="uploadPath" required="true"
			hint="File path" />	
	
		<cfscript>

			local.rootFilename = arguments.rootFilename;
			local.uploadPath = arguments.uploadPath;
		
			local.d = '';
			local.i = '';
		
			try {		
		
				local.d = directoryList('#local.uploadPath#',false,'name','*.CHUNK*');
				
				if (arrayLen(local.d) != 0){
					for (local.i = 1; local.i lte arrayLen(local.d); local.i++){
						if(
							isNumeric(listLast(listLast(local.d[local.i],"."),"CHUNK")) //extension is .CHUNK*
							AND(
								local.d[local.i] CONTAINS "#local.rootFilename#.CHUNK" //filename matches
								OR
								DateDiff("d",getFileInfo("#local.uploadPath##local.d[local.i]#").lastmodified,Now()) GT 4 // four days old
							)
						){
							fileDelete('#local.uploadPath##local.d[local.i]#');
						}
					}
				}
								
			}
			
			catch(any err){
				
				return {success = false, errorMessage = err.detail, errorDetail = err.detail};
			}	
			
			return { success=true };
			
		</cfscript>
		
	</cffunction>

	<cffunction name="cleanFilename" returntype="string" output="false"
		description="Cleans out messy filename. Removes characters that cause issues. Renames the file (if applicable)">
		
		<cfargument name="fullPath" required="true"
			hint="Full path to the file">
		<cfargument name="autoRename" default="false"
			hint="If true, the file will be automatically renamed.">		
		<cfargument name="prependToFileName" default="" 
			hint="Text to prepend to filename. eg. yose-" />
		<cfargument name="appendToFileName" default="" 
			hint="Text to append to filename. eg. -yose" />			
		
		<cfscript>
		
			// localize vars
			local.fullPath = arguments.fullPath;
			local.autoRename = arguments.autoRename;		
			local.prependToFileName = arguments.prependToFileName;
			local.appendToFileName = arguments.appendToFileName;
			
			// setup vars
			local.fullPath_cl = local.fullPath;
			local.fileName = getFileFromPath(local.fullPath);
			local.fileName_cl = local.fileName;
			local.thisExt = ListLast(local.fileName_cl,".");
			
			// trim filename
			local.fileName_cl = trim(local.fileName);
			
			// if file extension is uppercase, make it lowercase [otherwise we get apache issues] & escape the good period
			local.fileName_cl = replace(local.fileName_cl,".#local.thisExt#","[[[imagoodperiod]]]#lCase(local.thisExt)#","all");

			// replace bad .'s with dashes and reassemble filename
			local.fileName_cl = replace(local.fileName_cl,".","_","all");
			local.fileName_cl = replace(local.fileName_cl,"[[[imagoodperiod]]]",".","all");		
			
			// remove all bad chars
			local.fileName_cl = reReplace(local.fileName_cl,"[^a-zA-Z0-9\.-]","","all");
			
			// handle appends and prepends 
			if(len(local.prependToFilename) AND (len(local.prependToFilename) GT len(local.fileName_cl) OR local.prependToFilename NEQ left(local.fileName_cl,len(local.prependToFilename)))) {
				local.fileName_cl = trim(local.prependToFilename) & local.fileName_cl;
			}	
			if(len(local.appendToFileName)){
				local.fileName_cl = replaceNoCase(local.fileName_cl,".#local.thisExt#","#local.appendToFileName#.#local.thisExt#");
			}

			// reassemble path
			local.fullPath_cl = replaceNoCase(local.fullPath_cl,fileName,local.fileName_cl);

			// rename file, if appropriate
			if(local.autoRename AND compare(local.fileName,local.fileName_cl) NEQ 0){
				local.fullPath_cl = renameFile(local.fullPath,local.fileName_cl);
			}
			
			return local.fullPath_cl;
	
		</cfscript>
						

		
			
	</cffunction>

	<cffunction name="renameFile" returntype="string" output="false"
		description="Renames file. Ensures unique filename.">
		
		<cfargument name="fullPath" required="true"
			hint="Full path to file">
		<cfargument name="newFileName" required="true"
			hint="New Filename">
		
		<cfscript>
		
			// localize vars
			local.fullPath = arguments.fullPath;
			local.newFileName = arguments.newFileName;

			// setup vars
			local.newFullPath = local.fullPath;
			
		</cfscript>
		
		<cfif compareNoCase(getFileFromPath(local.fullPath),local.newFileName) NEQ 0>

			<cfset local.newFullPath = findUniqueFilename("#getDirectoryFromPath(local.fullPath)##local.newFileName#")>
		
			<cffile action="rename"
				source="#local.fullPath#" 
				destination="#local.newFullPath#">

		</cfif>
				
		<cfreturn local.newFullPath />
		
	</cffunction> 

	<cffunction name="findUniqueFilename" returntype="string" output="false"
		description="Does the legwork to find a nice unique filename for a new file.">
		
		<cfargument name="fullPath" required="true"
			hint="Full path to file">

		<cfscript>

			// localize vars
			local.fullPath = arguments.fullPath;
			
			// setup vars
			local.newFullPath = local.fullPath;	
			local.newFileName_adj = getFileFromPath(local.fullPath);
			local.thisExt = ListLast(local.newFileName_adj,".");
			local.i = 0;
		
		</cfscript>
			
		<cfif fileExists("#getDirectoryFromPath(local.fullPath)##local.newFileName_adj#")>
						
			<cfloop index="i" from="1" to="99">
				<cfset local.newFileName_adj_tmp = replaceNoCase(local.newFileName_adj,".#local.thisExt#","#local.i#.#local.thisExt#")>
				<cfif NOT fileExists("#getDirectoryFromPath(local.fullPath)##local.newFileName_adj_tmp#")>
					<cfset local.newFileName_adj = local.newFileName_adj_tmp>
					<cfbreak />
				</cfif>
			</cfloop>
				
		</cfif>
		
		<cfset local.newFullPath = "#getDirectoryFromPath(local.fullPath)##local.newFileName_adj#">

		<cfreturn local.newFullPath />
			
	</cffunction>

<cffunction name="getEnvironmentCode" displayname="getEnvironmentCode" returntype="string" output="false" access="public" 
	description="Guess the code for the current environment (DEV,TEST,TRAINING,PROD)"
	hint="">
			
	<cfscript>
		
		local.hostFirst = "";

		if(len(cgi.http_host)){

			local.hostFirst = listFirst(cgi.http_host, ".");

			if(
				local.hostFirst EQ "cms" 
				OR local.hostFirst EQ "www"
				OR local.hostFirst CONTAINS "delivery"
				OR local.hostFirst EQ "home"){
				return "PROD";
			}else if(local.hostFirst CONTAINS "test"){
				return "TEST";
			}else if(local.hostFirst CONTAINS "training"){
				return "TRAINING";	
			}else if(local.hostFirst CONTAINS "dev"){
				return "DEV";										
			}else{
				return uCase(replaceNoCase(local.hostFirst,"cms","","all"));	
			}
		}else{
			return "";
		}

	</cfscript>
		
</cffunction>
	