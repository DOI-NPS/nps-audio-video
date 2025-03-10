	var audio_video_upload_directory = jQuery( '#audio_video_upload_directory' ).val();
	var thumbnail_upload_directory = jQuery( '#thumbnail_upload_directory' ).val();
	var s3_path = 'https://www.nps.gov/nps-audiovideo/';
	
	function generateUUID() { // Public Domain/MIT
		var d = new Date().getTime();//Timestamp
		var d2 = (performance && performance.now && (performance.now()*1000)) || 0;//Time in microseconds since page-load or 0 if unsupported
		return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
			var r = Math.random() * 16;//random number between 0 and 16
			if(d > 0){//Use timestamp until depleted
				r = (d + r)%16 | 0;
				d = Math.floor(d/16);
			} else {//Use microseconds since page-load if supported
				r = (d2 + r)%16 | 0;
				d2 = Math.floor(d2/16);
			}
			return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
		});
	}
	
	// initialize the uploader
	var av_uploader = new plupload.Uploader({
		runtimes : 'html5,flash,silverlight,html4',
			 
		browse_button : 'pluSelectFileLoc', // you can pass in id...
		container: document.getElementById('pluContainerFileLoc'), // ... or DOM Element itself
			 
		url : '/customcf/structured_data/uploadHelperFunction.cfm?uploadPath=' + audio_video_upload_directory + '&type=video&filename='+generateUUID(),
			 
		filters : {
			max_file_size : '20000mb',
			mime_types: [
				{title : "Audio/Video files", extensions : "mp3,avi,mov,mp4,m4v,wmv,asf,mpeg,mpg,3gp,3g2,flv"},
			]
		},
		 
		// Flash settings
		flash_swf_url : './js/plupload/js/Moxie.swf',
		 
		// Silverlight settings
		silverlight_xap_url : './js/plupload/js/Moxie.xap',
		
		chunk_size : '50mb',
		max_retries: 3,
		multiple_queues : false,
		multi_selection : false,
		max_file_count : 1,			 
		 
		init: {
			
			PostInit: function() {
				
				jQuery('#pluContainerFileLoc .progress-bar').attr( 'style', 'width:' + 0 + '%' );
				jQuery('#pluContainerFileLoc .progress-bar').html( 0 + '%' );
				
				jQuery( '#pluSelectFileLoc' ).on( 'click', function( event ) { 
					av_uploader.start();
					event.preventDefault();
					event.stopImmediatePropagation();						
					return false;
				});
			},		 
			FilesAdded: function(up, files) {
				
				audio_video_complete = 0;
				updateCompletionStatus();
				
				jQuery('#upload_error_message').html('');
						
				plupload.each(files, function(file) {
					
					thumb = file.name;
					thumb = thumb.replace( '.', '_thumb.' );
							
					jQuery( '#audio_video_filelist' ).children().remove();
					jQuery( '#audio_video_filelist' ).append( '<div id="' + file.id + '">' + file.name + ' (' + plupload.formatSize(file.size) + ') <b></b></div>' );
							
					av_uploader.start();
					
				});				
				
			},		 		
			UploadProgress: function(up, file) { 
			
				jQuery('#pluContainerFileLoc .progress-bar').attr( 'style', 'width:' + file.percent + '%' );
				jQuery('#pluContainerFileLoc .progress-bar').html( file.percent + '% of ' + plupload.formatSize(file.size)+ '/ ' + addCommas(Math.round(av_uploader.total.bytesPerSec/100)/10)+'Kbps' );

			},	
			FileUploaded: function( up, file, response ) {
				
				cleanedName = JSON.parse(response.response).cleanedName;
				totalChunks = JSON.parse(response.response).totalChunks;
			
				jQuery( '#audio_video_filelist' ).val( s3_path + 'audiovideo/' + cleanedName );
																
				document.getElementById( file.id ).innerHTML = '<a href="' + s3_path + 'audiovideo/' + cleanedName + '" id="file_' + file.id + '" target="_blank"> ' + cleanedName + '</a> (' + plupload.formatSize(file.size) + ')<input type="hidden" name="title_' + file.id + '" id="title_' + file.id + '" value="' + file.name + '"> <button type="button" type="button" class="btn btn-default button_remove_video" data-id="' + file.id + '"><span class="glyphicon glyphicon-minus" style="margin: 0 0px; pointer-events:none"></span></button><b></b>';
				
				jQuery( '#audio_video_file_path' ).val( s3_path + 'audiovideo/' + cleanedName );
				
				jQuery( '#pluContainerFileLoc' ).hide();

				// show notification
				if ( totalChunks != 0 ) {
					
					audio_video_complete = 1;
					
					jQuery( '#audio_video_filelist' ).notify(
						"Your video has uploaded and is processing, please allow up to an hour for it to be available.",
						"success",
						{ position: "top left" }
					);	
					
					updateCompletionStatus();
					
				}
					
				jQuery( '.button_remove_video' ).on( 'click', function( event ) {
										
					event.preventDefault();
										
					file_id = jQuery( this ).data( 'file_id' );
										
					jQuery( '#' + file_id ).remove();
					jQuery( '#pluContainerFileLoc' ).show();
					jQuery( '#audio_video_filelist' ).html( '' );
					jQuery( '#audio_video_file_path' ).val( '' );
								
				});
	
			},
			Error: function(up, err) {
				console.log( "\nError #" + err.code + ": " + err.message );	
				
				jQuery( '#pluSelectFileLoc' ).hide();
				
				jQuery( '#audio_video_filelist' ).notify(
					"There was an error uploading your file.",
					"danger",
					{ position: "top left" }
				);
				
				jQuery( '#pluSelectFileLoc' ).show();
				
			}
		}
	});
		 
	av_uploader.init();
	
	function updateCompletionStatus() {
		
		if ( audio_video_complete && audio_description_complete ) {
			
			jQuery( '#button_finish' ).show();
			jQuery( '#button_incomplete' ).hide();			
			
		}
		else {

			jQuery( '#button_finish' ).hide();
			jQuery( '#button_incomplete' ).show();	
			
		}
	}	