<!--- This is not a full working example, just a snippet of what we use to upload a video.
      Similar code can be added to support thumbnail, caption file, and Audio Descriptive Version uploads --->
	  
<cfscript>
	
	// parks use region code, we often use that in the directory structure
	region_code = 'akr|imr|mwr|ncr|ner|pwr|ser'; 
	
	// upload path on aws
	audio_video_upload_directory = 'nps-audiovideo-watchfolder/inputs/';
	
	// local upload path for thumbnail images
	thumbnail_upload_directory = '/common/uploads/#region_code#/';
	
	// variables to be populated if editing a previously uploaded video
	audio_video_id = 0;
	audio_video_file_path = '';

</cfscript>
	
	<cfif len( audio_video_id )>
		<div class="form-group">
			<label class="col-sm-2 control-label">Audio/Video ID</label>							
			<div class="col-sm-10"> 
				<input type="text"  class="form-control" value="#audio_video_id#" readonly>
			</div>
		</div>
	</cfif>
	
	// Video Upload Form
	<div class="form-group">
		<label for="audio_video_file_path" class="col-sm-2 control-label">Audio/Video File *</label>
		<div id="audio_video_filelist">
			<cfif audio_video_file_path gt "">
				<cfset uniqueID = createUUID()>
				<div id="o_#uniqueID#">
					<a href="#audio_video_file_path#" id="file_o_#uniqueID#" target="_blank"> #getFileFromPath( audio_video_file_path )#</a>
					<button type="button" class="btn btn-default button_remove_video" data-file_id="o_#uniqueID#" data-button_id="audio_video_filelist"><span class="glyphicon glyphicon-minus" style="margin: 0 0px; pointer-events:none"></span></button>
				</div>
			</cfif>									
		</div>									
		<div class="col-sm-10" id="pluContainerFileLoc" class="progress" <cfif audio_video_file_path gt "">style="display:none;"</cfif>>
			<button class="btn btn-primary" id="pluSelectFileLoc"> <i class="fa fa-file-image-o fa-fw"></i> Select File</button>
			<p class="help-block">Supported Formats: MP3,AVI,MOV,MP4,M4V,WMV,ASF,MPEG,MPG,3GP,3G2</p>
			<p class="help-block">Minimum resolution: 360p (480 x 360 pixels)</p>
			<div class="progress-bar progress-bar-success" role="progressbar" arial-valuenow="0" arial-valuemin="0" aria-valuemax="100" style="width:0%; display:none;">
				<span class="sr-only"></span>
			</div>
		</div>
		<input type="hidden" name="audio_video_file_path" id="audio_video_file_path" value="#audio_video_file_path#">
	</div>

	
	