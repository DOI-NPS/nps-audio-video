	<!--- *********** DISPLAY/OUTPUT FUNCTIONS *********** --->
	<cffunction name="embedAVPlayer" output="no" returntype="string" description="RETURNS the embed code for the AV Player.">
		<cfargument name="playerConfig" type="struct" required="yes" default="#StructNew()#">
		<cfargument name="s3_path" type="string" required="yes" default="">
		<cfargument name="download_original_url" type="string" required="yes" default="">
		<cfargument name="site_code" type="string" required="yes" default="">
		<cfargument name="region_code" type="string" required="yes" default="">

		<cfset local.playerConfig = arguments.playerConfig>
		<cfset local.s3_path = arguments.s3_path>
		<cfset local.download_original_url = arguments.download_original_url>
		<cfset local.site_code = arguments.site_code>
		<cfset local.region_code = arguments.region_code>

		<cfscript>
			local.videoJSVideoAttributes = {
				id = local.player_config['uniqueID'],
				siteCode = local.site_code,
				regionCode = local.region_code,
				containerID = local.player_config['playerDivID'],
				s3Path = local.s3_path,
				downloadOriginalURL = local.download_original_url,
				embedURL = '<iframe src="https://www.nps.gov/media/video/embed.htm?id=#local.playerConfig['uniqueID']#" width="480" height="306" frameborder="0" scrolling="auto" allowfullscreen></iframe>',
				splashImage = local.player_config['splashImage'],
				sources = local.player_config.sources,
				closedCaptionFiles = local.player_config['closedCaptionFiles'],
				title = local.player_config['title'],
				linkToOriginal = local.player_config['linkToOriginal'],
				fileSize = local.player_config['file_size'],
				fileURLAD = local.player_config['fileUrlAD']
			};
		</cfscript>

		<cfsavecontent variable="local.avEmbedCode">
			<cfmodule template="/nps/theme/views/partials/video-js-video.cfm"
				attributecollection="#local.videoJSVideoAttributes#">
		</cfsavecontent>

		<cfreturn "#local.avEmbedCode#">
		
	</cffunction>