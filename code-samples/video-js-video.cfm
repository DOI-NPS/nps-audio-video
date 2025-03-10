<cfscript>
/**
 * @file video-js-video.cfm
 */

param name="attributes.id" type="string" default="";
param name="attributes.siteCode" type="string" default="";
param name="attributes.regionCode" type="string" default="";
param name="attributes.containerID" type="string" default="";
param name="attributes.s3Path" type="string" default="nps-audiovideo";
param name="attributes.embedURL" type="string" default="";
param name="attributes.splashImage" type="string" default="";
param name="attributes.sources" type="array" default=[];
param name="attributes.ad_sources" type="array" default=[];
param name="attributes.asl_sources" type="array" default=[];
param name="attributes.closedCaptionFiles" type="struct" default="#StructNew()#";
param name="attributes.title" type="string" default="";
param name="attributes.linkToOriginal" type="boolean" default="FALSE";
param name="attributes.fileSize" type="string" default="";
param name="attributes.fileURLAD" type="string" default="";
param name="attributes.hideInfoButton" type="string" default="FALSE";
param name="attributes.fileURLASL" type="string" default="";

// writeDump( attributes.sources );
// writeDump( attributes.ad_sources );
// writeDump( attributes.asl_sources );
containerID = len(attributes.containerID) ? attributes.containerID : "vjs_" & createUUID();
</cfscript>

<cfoutput>

<script type="text/javascript">
	var original_sources = [];
	var ad_sources = [];
	var asl_sources = [];

	<cfloop from="1" to="#arrayLen( attributes.sources )#" index="idx">
		original_sources[ #idx# - 1 ] = {};
		original_sources[ #idx# - 1 ].src = '#attributes.sources[ idx ].fileURL#';
		original_sources[ #idx# - 1 ].type = 'video/mp4';
		original_sources[ #idx# - 1 ].res = '#attributes.sources[ idx ].res#';
		original_sources[ #idx# - 1 ].label = '#attributes.sources[ idx ].label#';
		<cfif idx eq arrayLen( attributes.sources  )>
			original_sources[ #idx# - 1 ].selected = true;
		<cfelse>
			original_sources[ #idx# - 1 ].selected = false;
		</cfif>
	</cfloop>
	
	<cfloop from="1" to="#arrayLen( attributes.ad_sources )#" index="idx">
		ad_sources[ #idx# - 1 ] = {};
		ad_sources[ #idx# - 1 ].src = '#attributes.ad_sources[ idx ].fileURL#';
		ad_sources[ #idx# - 1 ].type = 'video/mp4';
		ad_sources[ #idx# - 1 ].res = '#attributes.ad_sources[ idx ].res#';
		ad_sources[ #idx# - 1 ].label = '#attributes.ad_sources[ idx ].label#';
		<cfif idx eq arrayLen( attributes.ad_sources  )>
			ad_sources[ #idx# - 1 ].selected = true;
		<cfelse>
			ad_sources[ #idx# - 1 ].selected = false;
		</cfif>
	</cfloop>	

	<cfloop from="1" to="#arrayLen( attributes.asl_sources )#" index="idx">
		asl_sources[ #idx# - 1 ] = {};
		asl_sources[ #idx# - 1 ].src = '#attributes.asl_sources[ idx ].fileURL#';
		asl_sources[ #idx# - 1 ].type = 'video/mp4';
		asl_sources[ #idx# - 1 ].res = '#attributes.asl_sources[ idx ].res#';
		asl_sources[ #idx# - 1 ].label = '#attributes.asl_sources[ idx ].label#';
		<cfif idx eq arrayLen( attributes.asl_sources  )>
			asl_sources[ #idx# - 1 ].selected = true;
		<cfelse>
			asl_sources[ #idx# - 1 ].selected = false;
		</cfif>
	</cfloop>							
</script>

<video id="#containerID#"
	class="video-js vjs-default-skin vjs-big-play-centered vjs-16-9"
	controls
	preload="metadata"
	width="640"
	height="264"
	poster="#attributes.splashImage#">
	<cfloop array="#attributes.sources#" item="source">
		<source src="#source['fileURL']#"
			type="#source['type']#"
			res="#source['res']#"
			label="#source['label']#" />
	</cfloop>
	<cfif NOT StructIsEmpty(attributes.closedCaptionFiles)>
		<cfloop collection="#attributes.closedCaptionFiles#" item="ccKey">
			<cfset thisTrack = attributes.closedCaptionFiles[ccKey]>

			<cfif ListLast(thisTrack, '.') NEQ 'vtt'>
				<cfset thisTrack = ReplaceNoCase(thisTrack, '.srt', '.vtt')>
				<cfset thisTrack = ReplaceNoCase(thisTrack, '.xml', '.vtt')>
				<cfset thisTrack = ReplaceNoCase(thisTrack, '.dfxp', '.vtt')>
			</cfif>

			<cfif thisTrack contains 'avElement' OR NOT thisTrack contains 'nps-audiovideo'>
				<cfset thisTrack = replace(thisTrack, 'avElement/', '')>
				<cfset thisTrack = 'https://www.nps.gov/#attributes.s3Path#/legacy/closed-caption/#attributes.regionCode#/avElement/#getFileFromPath(thisTrack)#'>
			</cfif>

			<track src="#JSStringFormat(thisTrack)#" kind="captions" srclang="<cfif ccKey EQ 'Spanish'>es<cfelseif ccKey EQ 'French'>fr<cfelseif ccKey EQ 'German'>de<cfelseif ccKey EQ 'Russian'>ru<cfelseif ccKey EQ 'Mandarin'>zh<cfelseif ccKey EQ 'Hindi'>hi<cfelseif ccKey EQ 'Arabic'>ar<cfelseif ccKey EQ 'Japanese'>ja<cfelseif ccKey EQ 'Korean'>ko<cfelseif ccKey EQ 'Portuguese'>pt<cfelse>en</cfif>" label="<cfif ccKey EQ 'Spanish'>Espa&ntilde;ol<cfelseif ccKey EQ 'French'>Français<cfelseif ccKey EQ 'German'>Deutsche<cfelseif ccKey EQ 'Russian'>Pусский<cfelseif ccKey EQ 'Mandarin'>普通話<cfelseif ccKey EQ 'Hindi'>हिंदी<cfelseif ccKey EQ 'Arabic'>عربى<cfelseif ccKey EQ 'Japanese'>日本語<cfelseif ccKey EQ 'Korean'>한국어<cfelseif ccKey EQ 'Portuguese'>Português<cfelseif ccKey EQ 'Hawaiian'>&##699;&##332;lelo Hawai&##699;i <!--- ʻŌlelo Hawaiʻi ---><cfelse>English</cfif>">
		</cfloop>
	</cfif>
</video>
<cfif len(attributes.embedURL)>
<button type="button"
	id="#containerID#EmbedButton"
	class="vjs-embed-control vjs-button"
	aria-live="polite"
	aria-disabled="false"
	title="Embed Video"
	data-bs-toggle="modal"
	data-bs-target="###containerID#EmbedModal">Embed</button>
<div class="modal fade VideoJSEmbedModal"
	id="#containerID#EmbedModal"
	tabindex="-1"
	aria-labelledby="#containerID#EmbedModalLabel"
	aria-hidden="true">
	<div class="modal-dialog modal-dialog-centered">
		<div class="modal-content">
			<div class="modal-header">
				<h1 class="modal-title" id="#containerID#EmbedModalLabel">
					Embed Video
				</h1>
				<button type="button"
					class="btn-close"
					data-bs-dismiss="modal"
					aria-label="Close"></button>
			</div>
			<div class="modal-body">
				<!--- This formatting is necessary for the textarea --->
				<textarea class="form-control"
					id="#containerID#EmbedText"
					rows="6"><iframe title="Video Embed" src="#attributes.embedURL#" width="480" height="306" frameborder="0" scrolling="auto" allowfullscreen></iframe></textarea>
			</div>
			<div class="modal-footer">
				<button type="button"
					class="btn btn-secondary"
					data-bs-dismiss="modal">
					Close
				</button>
				<button type="button" class="btn btn-primary" id="#containerID#EmbedCopy">
					Copy
				</button>
			</div>
		</div>
	</div>
</div>
</cfif>
<script type="text/javascript">
	(function ($) {
		$(document).ready(function () {
			var player = videojs('#containerID#', {
				aspectRatio: '16:9',
				fluid: true,
				inactivityTimeout: 700
			});
			player.dock({
				title: "#replace(attributes.title, '"', "''", "ALL")#"
			});
			player.hotkeys({
				volumeStep: 0.1,
				seekStep: 5,
				alwaysCaptureHotkeys: false,
				enableVolumeScroll: false
			});
			var eventCategoryText = '';
			var filetype = player.currentSrc().split('.').pop();
			if (filetype == 'mp3') {
				eventCategoryText = 'Audio';
			} else {
				player.controlBar.addChild('QualitySelector', {}, 14);
				eventCategoryText = 'Video';
			}
			// Initialize Google Analytics and log start, stop, fullscreen and 25% play increments 
			var current_source = player.src();
			player.ga({
				'eventCategory': 'NPS ' + eventCategoryText,
				'eventLabel': '#attributes.siteCode#-' + current_source.split('/').pop(),
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
			// Download Button
			<cfif attributes.linkToOriginal IS TRUE>
				// Create the download button with onClick to download function and place in the dock
				var downloadButtonLabel = "Download Original#(len(attributes.fileSize) ? " (" & attributes.fileSize & ")" : "")#";
				var downloadButton = $('<button></button>').attr({
					"class": "vjs-download-control vjs-button",
					"type": "button",
					"aria-live": "polite",
					"aria-disabled": "false",
					"title": downloadButtonLabel
				}).text("Download").on("click", function () {
					var element = document.createElement('a');
					var current_source = player.src();

					if (typeof gas !== "undefined") {
						// send notification to google analytics
						gas('send', 'event', 'Download', 'mp4', '#attributes.siteCode#-' + current_source, 1, true);
					}
					
					element.setAttribute('href', current_source);
					element.setAttribute('download', current_source.split('/').pop());
					element.style.display = 'none';
					document.body.appendChild(element);
					element.click();
					document.body.removeChild(element);
				});
				setTimeout(function () {
					// Add these in the same callback to avoid a race condition
					$('###containerID# div.vjs-dock-shelf').append(downloadButton);

					if ($('###containerID#EmbedButton').length > 0) {
						$('###containerID# div.vjs-dock-shelf').append($('###containerID#EmbedButton'));
					}
				}, 500);
			<cfelse>
				setTimeout(function () {
					if ($('###containerID#EmbedButton').length > 0) {
						$('###containerID# div.vjs-dock-shelf').append($('###containerID#EmbedButton'));
					}
				}, 500);
			</cfif>
			var Button = videojs.getComponent('Button');
			// AD Button
			<cfif len(trim(attributes.fileURLAD))>
				class AudioDescriptionButtonComponent extends Button {
					constructor( player ) { 
						super( player );
						// Button.apply(this, arguments);
						this.addClass('vjs-audio-description-button-control');
						this.controlText('Turn On Audio Description');
						
						this.on( 'click', function() {
							var player = videojs('#containerID#');
							var currentSource = player.src();
							var currentTime = player.currentTime();
							var isPaused = player.paused();
							var tracks = player.textTracks();						
								
							jQuery('.vjs-asl-button-control').removeClass('vjs-asl-button-control-focus');
								
							// if the current source isn't AD, make it AD
							if (currentSource!="#attributes.fileURLAD#"){
								this.addClass('vjs-audio-description-button-control-focus');
								this.controlText('Turn Off Audio Description');
								player.originalSources = player.currentSources(); 
								player.src( ad_sources );
								player.currentTime(currentTime);
								if(!isPaused){
									player.play();
								}

								// hide caption on switch to AD ( can be turned back on by user )
								for ( var tr = 0; tr < tracks.length; tr++ ) {
									tracks[ tr ].previousMode = tracks[ tr ].mode;
									tracks[ tr ].mode = 'hidden';
								}
							// current source is AD, load non-AD sources
							} else { 
								this.removeClass('vjs-audio-description-button-control-focus');								
								this.controlText('Turn On Audio Description');
								 
								player.src( original_sources );
								player.currentTime(currentTime);
								if (!isPaused) {
									player.play();
								}

								for ( var tr = 0; tr < tracks.length; tr++ ) {
									tracks[ tr ].mode = tracks[ tr ].previousMode;
								}
							}				
						});
					}
				}
				videojs.registerComponent('AudioDescriptionButton', AudioDescriptionButtonComponent);
				player.getChild('controlBar').addChild('AudioDescriptionButton', {}, 10);
				
			</cfif>

			// ASL Button
			<cfif len(trim(attributes.fileURLASL))> 
				class AmericanSignLanguageButton extends Button {
					constructor() {
						super( player );
						// Button.apply(this, arguments);
						this.addClass('vjs-asl-button-control');
						this.controlText('Turn On ASL Version');
					
						this.on( 'click', function() {
							var player = videojs('#containerID#');
							var currentSource = player.src();
							var currentTime = player.currentTime();
							var isPaused = player.paused();
							var tracks = player.textTracks();
							
							jQuery('.vjs-audio-description-button-control').removeClass('vjs-audio-description-button-control-focus');
							
							// if the current source isn't ASL, make it ASL
							if (currentSource!="#attributes.fileURLASL#"){
								this.addClass('vjs-asl-button-control-focus');
								this.controlText('Turn Off ASL Version');
								player.originalSources = player.currentSources();
								player.src( asl_sources );
								player.currentTime(currentTime);
								if(!isPaused){
									player.play();
								}

								// hide caption on switch to ASL ( can be turned back on by user )
								for ( tr = 0; tr < tracks.length; tr++ ) {
									tracks[ tr ].previousMode = tracks[ tr ].mode;
									tracks[ tr ].mode = 'hidden';
								}
							// current source is ASL, load non-ASL sources
							} else {							
								this.removeClass('vjs-asl-button-control-focus');								
								this.controlText('Turn On ASL Version');
								player.src(original_sources);
								player.currentTime(currentTime);
								if (!isPaused) {
									player.play();
								}

								for ( var tr = 0; tr < tracks.length; tr++ ) {
									tracks[ tr ].mode = tracks[ tr ].previousMode;
								}
							}
						});
					}
				}
				videojs.registerComponent('AmericanSignLanguageButton', AmericanSignLanguageButton);
				player.getChild('controlBar').addChild('AmericanSignLanguageButton', {}, 10);
			</cfif>
			
			// Info Button
			class InfoButton extends Button {
				constructor() {
					super( player );
					// Button.apply(this, arguments);
					/* initialize your button */
					this.addClass( 'vjs-info-button-control' );
					this.addClass( 'vjs-info-button' );
					this.controlText(eventCategoryText+' File Info');
					
					this.on( 'click', function() {
						/* do something on click */
						location.href= "/media/video/view.htm?id=#attributes.id#";
					});
				}
			}
			
			<cfif attributes.hideInfoButton eq FALSE>
			videojs.registerComponent('InfoButton', InfoButton);
			player.getChild('controlBar').addChild('InfoButton', {});
			</cfif>
			// Copy button
			var copyButton = document.getElementById('#containerID#EmbedCopy');
			if (copyButton) {
				copyButton.addEventListener('click', function () {
					var copyText = document.getElementById('#containerID#EmbedText');
					if (copyText) {
						var message = document.createElement('span');
						message.setAttribute('class', 'notification');
						message.setAttribute('aria-live', 'polite');
						navigator.clipboard.writeText(copyText.value).then(function () {
							message.textContent = 'Copied.';
							var footer = document.querySelector('###containerID#EmbedModal .modal-footer');
							if (footer) footer.prepend(message);
						}, function () {
							message.textContent = 'Copy failed.';
							var footer = document.querySelector('###containerID#EmbedModal .modal-footer');
							if (footer) footer.prepend(message);
						});
					}
				});
			}
		});
	})(jQuery);
</script>
</cfoutput>
