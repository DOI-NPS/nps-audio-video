<cfscript>
/**
 * @file video-js-audio.cfm
 */

param name="attributes.id" type="string" default="";
param name="attributes.siteCode" type="string" default="";
param name="attributes.regionCode" type="string" default="";
param name="attributes.containerID" type="string" default="";
param name="attributes.s3Path" type="string" default="nps-audiovideo";
param name="attributes.downloadOriginalURL" type="string" default="";
param name="attributes.source" type="string" default="";
param name="attributes.title" type="string" default="";
param name="attributes.linkToOriginal" type="boolean" default="FALSE";
param name="attributes.fileSize" type="string" default="";

containerID = len(attributes.containerID) ? attributes.containerID : "vjs_" & createUUID();
</cfscript>

<cfoutput>
<audio id="#containerID#"
	class="video-js vjs-default-skin"
	controls
	preload="metadata"
	style="width:100%;height:40px">
	<source src="#attributes.source#"
		type="audio/mp3" />
</audio>
<script type="text/javascript">
	(function ($) {
		$(document).ready(function () {
			var player = videojs('#containerID#', {
				aspectRatio: '1:0',
				fluid: true,
				inactivityTimeout: 0,
				controlBar: {
					'fullscreenToggle': false
				}
			});
			player.hotkeys({
				volumeStep: 0.1,
				seekStep: 5,
				alwaysCaptureHotkeys: false,
				enableVolumeScroll: false
			});
			// Initialize Google Analytics and log start, stop, fullscreen and 25% play increments 
			player.ga({
				'eventCategory': 'NPS Audio',
				'eventLabel': '#attributes.siteCode#-#getFileFromPath(attributes.downloadOriginalURL)#',
				'eventsToTrack': ['start', 'end', 'percentsPlayed', 'fullscreen'],
				'percentsPlayedInterval': 25,
				'debug': true
			});
			// Listener for keypress to capture up/down arrows for volume
			$('###containerID#').keyup(function(event) {
				// is the key pressed the down key (40)?
				if (event.which == 40) {
					// the down key has been pressed, check the volume level
					var volumeLevel = player.volume().toFixed(1);
					if ( volumeLevel < 0.1){
						player.muted(true); // mute the volume
					}
				}
				// is the key pressed the up key (38)
				if (event.which == 38) {
					var isVolumeMuted = player.muted();
					if (isVolumeMuted == true){
						player.muted(false);
					}
				}
			});
			var Button = videojs.getComponent('Button');
			// Download Button
			<cfif attributes.linkToOriginal IS TRUE AND len(trim(attributes.downloadOriginalURL))>
				// Button Required in Control Bar due to how Audio Player differs from Video Player
				var DownloadButton = videojs.extend(Button, {
					constructor: function() {
						Button.apply(this, arguments);
						// initialize your button
						this.addClass( 'vjs-download-button-control' );
						this.addClass( 'vjs-download-button' );
						this.controlText('Download Original#(len(attributes.fileSize) ? " (" & attributes.fileSize & ")" : "")#');
					}, 
					handleClick: function() {
						// do something on click					
						var element = document.createElement('a');

						// send notification to google analytics
						if (typeof gas !== "undefined") {
							gas('send', 'event', 'Download', 'mp3', '#attributes.siteCode#-#attributes.downloadOriginalURL#', 1, true);
						}

						element.setAttribute('href', '#attributes.downloadOriginalURL#');
						element.setAttribute('download', '#ListLast(attributes.downloadOriginalURL, '\/')#');
						element.style.display = 'none';
						document.body.appendChild(element);
						element.click();
						document.body.removeChild(element);
					}
				});
				videojs.registerComponent('DownloadButton', DownloadButton);
				player.getChild('controlBar').addChild('DownloadButton', {});
			</cfif>
			// Info Button
			var InfoButton = videojs.extend(Button, {
				constructor: function() {
					Button.apply(this, arguments);
					/* initialize your button */
					this.addClass( 'vjs-info-button-control' );
					this.addClass( 'vjs-info-button' );
					this.controlText('Audio File Info');
				},
				handleClick: function() {
					/* do something on click */
					location.href= "/media/video/view.htm?id=#attributes.id#";
				}
			});
			videojs.registerComponent('InfoButton', InfoButton);
			player.getChild('controlBar').addChild('InfoButton', {});
		});
	})(jQuery);
</script>
</cfoutput>
