<?php

#Do jobs realtime:
$wgRunJobsAsync = false;

#$wgReadOnly = 'MediaWiki Upgrade';
#deprecated $wgLegacyJavaScriptGlobals in 1.35. Will be removed in a later upgrade. Default value is false.
//$wgLegacyJavaScriptGlobals = true;

#Added so importStyleSheet doesn't throw an error
$wgIncludeLegacyJavaScript = true;

#For testing ONLY. do not leave active:
#$_GET['debug'] = true;
#$wgDebugToolbar = true;
#$wgShowSQLErrors = true;
#$wgDebugDumpSql  = true;
#$wgEnableJavaScriptTest = true;

/**
 * The debug log file must never be publicly accessible because it
 * contains private data. But ensure that the directory is writeable by the
 * PHP script running within your Web server.
 * The filename is with the database name of the wiki.
 */
# Testing for 1.35.2 install
$wgDebugLogFile = "/home/clicklaw/wiki.clicklaw.bc.ca/logs/debug-{$wgDBname}.log";

# Protect against web entry
if ( !defined( 'MEDIAWIKI' ) ) {
	exit;
}

## Uncomment this to disable output compression
# $wgDisableOutputCompression = true;

$wgSitename      = "Clicklaw Wikibooks";

## The URL base path to the directory containing the wiki;
## defaults for all runtime URL paths are based off of this.
## For more information on customizing the URLs
## (like /w/index.php/Page_title to /wiki/Page_title) please see:
## http://www.mediawiki.org/wiki/Manual:Short_URL
$wgScriptPath       = "";

# $wgScriptExtension is deprecated and removed as of 1.31
$wgScriptExtension  = ".php";

#$wgUsePathInfo = false;

$wgServer = "http://mediawiki/";

## The relative URL path to the skins directory
$wgStylePath        = "$wgScriptPath/skins";
$wgFavicon = "/images/clicklaw_wikibook_favicon.ico";										  

## The relative URL path to the logo.  Make sure you change this from the default,
## or else you'll overwrite your logo when you upgrade!
$wgLogo = "$wgScriptPath/images/clicklaw_logo_wiki.png";

## UPO means: this is also a user preference option

$wgEnableEmail      = true;
$wgEnableUserEmail  = true; # UPO
$wgSMTP = array(
                'host'     => "smtp.office365.com",
                'IDHost'   => "wiki.clicklaw.bc.ca",
                'port'     => 587,
                'auth'     => true,
                'username' => "wikisupport@clicklaw.bc.ca",
                'password' => "%D3f@ult0%"
                );

// NEW: Use PHP default
$wgSMTP = true;

$wgUserEmailUseReplyTo = "wikisupport@clicklaw.bc.ca";
$wgEmergencyContact = "wikisupport@clicklaw.bc.ca";
$wgPasswordSender   = "wikisupport@clicklaw.bc.ca";

#$wgUserEmailUseReplyTo = "wikisupport@courthouselibrary.ca";
#$wgEmergencyContact = "wikisupport@courthouselibrary.ca";
#$wgPasswordSender   = "wikisupport@courthouselibrary.ca";
$wgEnotifUserTalk      = true; # UPO
$wgEnotifWatchlist     = true; # UPO
$wgEmailAuthentication = false;

## Database settings
$wgDBtype           = "mysql";
$wgDBserver         = "localhost";
$wgDBuser           = "clicklaw";
$wgDBpassword = 'Oim8eeSh1niexoh';

# Blue / Green Deployment
if ($blueGreen == "blue") {
    $wgDBname           = "clicklaw_blue";
} elseif ($blueGreen == "green") {
    $wgDBname           = "clicklaw_green";
} elseif ($blueGreen == "black") {
    $wgDBname           = "clicklaw_black";
}

# MySQL specific settings
$wgDBprefix         = "";

# MySQL table options to use during installation or update
$wgDBTableOptions   = "ENGINE=InnoDB, DEFAULT CHARSET=binary";

# Experimental charset support for MySQL 5.0.
# Deprecated in 1.31, removed in 1.33
//$wgDBmysql5 = false;

## Shared memory settings
#$wgMainCacheType    = CACHE_ACCEL;
#$wgMessageCacheType = CACHE_ACCEL;
#$wgParserCacheType = CACHE_ACCEL;						 

$wgShowExceptionDetails = true;
$wgMemCachedServers = array();
$wgUseGzip = true;
$wgEnableSidebarCache = false;
#removed $wgDisableCounters in 1.35 upgrade
//$wgDisableCounters = true;
$wgMiserMode = true;
$wgMaxShellMemory = 0;
## Set $wgCacheDirectory to a writable directory on the web server
## to make your wiki go slightly faster. The directory should not
## be publically accessible from the web.
$wgCacheDirectory = "/tmp/mediawiki-cache";

## To enable image uploads, make sure the 'images' directory
## is writable, then set this to true:
$wgEnableUploads  = true;
$wgVerifyMimeType = false;
$wgFileExtensions = array_merge($wgFileExtensions, array('svg', 'doc', 'xls', 'mpp', 'pdf','ppt','pptx','xlsx','jpg','tiff','odt','odg','ods','odp','docx','epub'));
$wgAllowJavaUploads = true;
$wgUseImageMagick = true;
$wgImageMagickConvertCommand = "/usr/bin/convert";
$wgImageMagickTempDir = "/tmp";
$wgSVGConverter = 'ImageMagick';

# InstantCommons allows wiki to use images from http://commons.wikimedia.org
$wgUseInstantCommons  = false;

## If you use ImageMagick (or any other shell command) on a
## Linux server, this will need to be set to the name of an
## available UTF-8 locale
$wgShellLocale = "en_US.utf8";

## If you want to use image uploads under safe mode,
## create the directories images/archive, images/thumb and
## images/temp, and make them all writable. Then uncomment
## this, if it's not already uncommented:
#$wgHashedUploadDirectory = false;

# Site language code, should be one of the list in ./languages/Names.php
$wgLanguageCode = "en";

$wgSecretKey = "75470a28a164494221bdc4900c1f7293e0ed7346106d1cb94829da36c5dfd9ad";

# Site upgrade key. Must be set to a string (default provided) to turn on the
# web installer while LocalSettings.php is in place
$wgUpgradeKey = "005dfac93a27afd7";

## Default skin: you can change the default skin. Use the internal symbolic
## names, ie 'standard', 'nostalgia', 'cologneblue', 'monobook', 'vector':
$wgDefaultSkin = "vector";
wfLoadSkin( 'Vector' );

$wgExternalLinkTarget = '_blank';

// CLWB-235
#wfLoadSkin( 'MinervaNeue' );
#$wgMFDefaultSkinClass = "SkinMinerva";							 

# Mobile experience skin (load by MoibleFrontEnd)
wfLoadSkin( 'Timeless' );
$wgMFDefaultSkinClass = "SkinTimeless";
#$wgDefaultSkin = 'minerva';

#$wgMFDefaultSkinClass = "SkinClicklaw";

## For attaching licensing metadata to pages, and displaying an
## appropriate copyright notice / icon. GNU Free Documentation
## License and Creative Commons licenses are supported so far.

$wgRightsPage = ""; # Set to the title of a wiki page that describes your license/copyright
$wgRightsUrl  = "";
$wgRightsText = "";
$wgRightsIcon = "";

# Path to the GNU diff3 utility. Used for conflict resolution.
$wgDiff3 = "/usr/bin/diff3";

# Query string length limit for ResourceLoader. You should only set this if
# your web server has a query string length limit (then set it to that limit),
# or if you have suhosin.get.max_value_length set in php.ini (then set it to
# that value)
$wgResourceLoaderMaxQueryLength = -1;


/* Added in 1.24.1 upgrade */
//require_once("$IP/skins/clicklaw/clicklaw.php");

# End of automatically generated settings.
# Add more configuration options below.

# Enabled Extensions. Most extensions are enabled by including the base extension file here
# but check specific extension documentation for more details
// For 1.28.0 removed 'Gadets' from the list											
wfLoadExtensions(array(
    'Collection',
	'HeadScript',
	'ConfirmEdit', 
    'WikiEditor',
	//'Nuke', 		
    'ParserFunctions', 
    'Renameuser', 
    'Lingo', 
	//'CollapsibleVector',
    //'ArticleFeedbackv5',					  
    'EmbedVideo',
    'Quiz',
    'MobileFrontend',
	//'ChangeWording',				  
    'UserMerge',
	'Lockdown',
	'EditAccount',
)); // NOTE: Configs are now handled in Lingo/extension.json

//disable some extensions for staging sites
//if ($stageLive == "live") {
    //wfLoadExtension( 'ArticleFeedbackv5' );
	wfLoadExtension( 'CommentStreams' );
	$wgAllowDisplayTitle = true;
	$wgRestrictDisplayTitle = false;
	wfLoadExtension( 'Echo' );
	$wgCommentStreamsEnableVoting =  true;
	$wgDefaultUserOptions["echo-subscriptions-email-commentstreams-notification-category"] = true; // enable email notifications
	$wgDefaultUserOptions["echo-subscriptions-web-commentstreams-notification-category"] = true; // enable web notifications
	$wgGroupPermissions['*']['cs-comment'] = true;
	//csmoderators to be able to edit comments
	$wgGroupPermissions['csmoderator']['cs-moderator-edit'] = true;
	//able to quick delete entire comment threads
	$wgCommentStreamsModeratorFastDelete = true;
	//collapsible comments	
	$wgCommentStreamsInitiallyCollapsedNamespaces[] = NS_CATEGORY;
	$wgCommentStreamsInitiallyCollapsedNamespaces[] = NS_MAIN;//array(NS_MAIN,NS_CATEGORY);//array(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,-1,-2);
	
	
	wfLoadExtension( 'WhoIsWatching' );
	# $whoiswatching_nametype = "RealName";
	# $whoiswatching_allowaddingpeople = false;
	$whoiswatching_showifzero = false;
	# $whoiswatching_showwatchingusers = false;
	# $whoiswatching_maxPicklistUsers = 10;
	# $wgGroupPermissions['sysop']['addpagetoanywatchlist'] = true;
	# $wgGroupPermissions['sysop']['seepagewatchers'] = true;
	
	#$wgGroupPermissions['user']['addpagetoanywatchlist'] = true;
	#$wgGroupPermissions['user']['seepagewatchers'] = true;
//}

//Block access to no logged users to all comments page
$wgSpecialPageLockdown['CommentStreamsAllComments'] = [ 'user' ];

// UserMerge turned on for bureaucrat
$wgGroupPermissions['bureaucrat']['usermerge'] = true;

// EditAccount turned on for bureaucrat
$wgGroupPermissions['bureaucrat']['editaccount'] = true;

// CLWB-217 - Prevent access and reading to blocked users
$wgBlockDisablesLogin=true;

#require_once( "$IP/extensions/Vector/Vector.php" );													
// THESE SHOULD BE ACTIVE 2018 08 09
//require_once( "$IP/extensions/UserDailyContribs/UserDailyContribs.php" );
//require_once( "$IP/extensions/EventLogging/EventLogging.php" );
//require_once( "$IP/extensions/EmailCapture/EmailCapture.php" );

# Custom Feedback Admin Tool
//require_once( "$IP/extensions/FeedbackAdmin/FeedbackAdmin.php" );

//require_once( "$IP/extensions/CollectionSecure/CollectionSecure.php" );

// The extensions below require configuration and are either not composer based or composer doesn't have relevant config options in extension.json.

# Change loading funtion in 1.35
//require_once( "$IP/extensions/Collection/Collection.php" );
#added by nate may 15 2013
$wgCollectionFormats = array(
    'rl' => 'PDF', # enabled by default
    'odf' => 'ODT',
    'epub' => 'ebook (EPUB)',
);

// Remove a4 option
$wgCollectionRendererSettings['papersize'] = array(
    'type' => 'select',
    'label-message' => 'coll-setting-papersize',
    'default' => 'Letter',
    'options' => array(
            'coll-setting-papersize-letter' => 'Letter',
    ),
);

$wgCollectionRendererSettings['columns'] = array(
    'type' => 'hidden',
    'label-message' => 'coll-setting-columns',
    'default' => '1',
    'options' => array(
        'coll-setting-columns-1' => '1',
    ),
);

#$wgCollectionMWServeURL = 'http://10.2.71.41:8899/cache';

// Confirmed working as of Dec 14, 2016
#$wgCollectionMWServeURL = 'http://10.2.71.31:8899/cache';
// New for new server unification as of Aug 27, 2018
#$wgCollectionMWServeURL = 'http://204.187.12.195:8899/cache';
$wgCollectionMWServeURL = 'http://10.22.59.12:8899/cache';
$wgCollectionDisableDownloadSection = false;

$bwScriptsDirectory = 'scripts';

//require_once( "$IP/extensions/GoogleTagManager/GoogleTagManager.php" );


//Change GTM for Head Script code extension in 1,35 upgrade */
// Set GTM appropriately for dev and live
//if ($stageLive == "live") {
    //$wgGoogleTagManagerContainerID = "GTM-KFF3ZQ";
//} 

# GTag extension configuration. "real" tag just for live 
/*if ($stageLive == "live") {
    $wgGTagAnalyticsId = "GTM-KFF3ZQ";
} else {
	$wgGTagAnalyticsId = 'GTM-54HLCV';
}*/

if ($stageLive == "live") {
    $wgHeadScriptCode = <<<'START_END_MARKER'
<!-- Google Tag Manager -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push(
{'gtm.start': new Date().getTime(),event:'gtm.js'}
);var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-KFF3ZQ');</script>
<!-- End Google Tag Manager -->
<!-- Google Tag Manager (noscript) -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-KFF3ZQ"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
<!-- End Google Tag Manager (noscript) -->
START_END_MARKER;
} else {
	$wgHeadScriptCode = <<<'START_END_MARKER'
<!-- Google Tag Manager (noscript) -->
<noscript><iframe src="https://www.googletagmanager.com/ns.html?id=GTM-54HLCV"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>
<!-- End Google Tag Manager (noscript) -->
<!-- Google Tag Manager -->
<script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push(

{'gtm.start': new Date().getTime(),event:'gtm.js'}
);var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-54HLCV');</script>
<!-- End Google Tag Manager -->
START_END_MARKER;
}

#require_once "$IP/extensions/MobileFrontend/MobileFrontend.php";																 
$wgMFAutodetectMobileView = true;
$wgMFCollapseSectionsByDefault = false;
$wgMFRemovableClasses = [ 'base' => [ '.mw-lingo-tooltip' ] ];

$wgArticleFeedbackv5Debug = true;

$wgMFExperiments = [
  // Experiment to prompts users to opt into the beta experience of the skin.
  'betaoptin' => [
    'name' => 'betaoptin',
    'enabled' => false,
    'buckets' => [
      'control' => 1.00,
      'A' => 0.00,
    ],
  ],
];


$wgArticleFeedbackv5CTABuckets = array(
    'buckets' => array(
        '0' => 100, // display nothing
        '1' => 0, // display "Enticement to edit"
        '2' => 0, // display "Learn more"
        '3' => 0, // display "Take a survey"
        '4' => 0, // display "Sign up or login"
        '5' => 0, // display "View feedback"
        '6' => 0, // display "Visit Teahouse"
    ),
    'version' => 4,
    'expires' => 0,
);

$wgArticleFeedbackv5DisplayBuckets = array(
    'buckets' => array(
        '0' => 0, // display nothing
        '1' => 0, // display 1-step feedback form
//      '2' => 0, // abandoned
//      '3' => 0, // abandoned
        '4' => 0, // display encouragement to edit page
//      '5' => 0, // abandoned
        '6' => 100, // display 2-step feedback form
    ),
    'version' => 6,
    'expires' => 0,
);


// FOR TESTING: Forces Mobile to true
#MobileContext::singleton()->setForceMobileView( true );

// Visual Editor code requires MediaWiki 1.23
//require_once("$IP/extensions/VisualEditor/VisualEditor.php");

//// OPTIONAL: Enable VisualEditor in other namespaces
//// By default, VE is only enabled in NS_MAIN
////$wgVisualEditorNamespaces[] = NS_PROJECT;
 
//// Enable by default for everybody
//$wgDefaultUserOptions['visualeditor-enable'] = 1;

//// Don't allow users to disable it
//$wgHiddenPrefs[] = 'visualeditor-enable';

//// URL to the Parsoid instance
//// MUST NOT end in a slash due to Parsoid bug
//$wgVisualEditorParsoidURL = 'http://localhost:9000';

// OPTIONAL: Enable VisualEditor's experimental code features
//$wgVisualEditorEnableExperimentalCode = true;

// TESTING CLWB-221 ChangeWording extension 
#require_once( "$IP/extensions/ChangeWording/ChangeWording.php" );

###Added for upgrade to 1.37
$wgManualRevertSearchRadius = 0;
$wgBrowserFormatDetection=true;
# $wgShowDBErrorBacktrace = true; 

###JUST SET BELOW ONES TO TRUE IN DEBUG MODE (CLWB-393####
$wgShowExceptionDetails=false;
$wgShowHostnames=false;

// WiikiEditor Stuff
# Enables use of WikiEditor by default but still allow users to disable it in preferences
$wgDefaultUserOptions['usebetatoolbar'] = 1;
$wgDefaultUserOptions['usebetatoolbar-cgd'] = 1;
 
# Displays the Preview and Changes tabs
$wgDefaultUserOptions['wikieditor-preview'] = 1;
 
# Displays the Publish and Cancel buttons on the top right side
$wgDefaultUserOptions['wikieditor-publish'] = 1;


$wgArticleFeedbackv5AutoArchiveEnabled = true;
$wgArticleFeedbackv5LotteryOdds  = 100;

# Added April 17 2013 by Nate to disable feedback on navigation and bios
$wgArticleFeedbackv5BlacklistCategories = array( 'Navigation Page','Contributor Bio' );

# Added July 22 2013 by Nate to enable view of dashboard for article feedback
$wgArticleFeedbackDashboard = true;


# Added June 19 2013 by Nate to let confirmed accounts with email post URLs without math capture
$wgGroupPermissions['user']['skipcaptcha'] = true;
$wgCaptchaTriggers['edit'] = true;


# Permissions
$wgGroupPermissions['*']['createaccount']       = false;
$wgGroupPermissions['admin']['createaccount']   = true;
$wgGroupPermissions['*']['edit']                = false;
$wgGroupPermissions['*']['createpage']		      = false;
$wgGroupPermissions['user']['edit']             = true;
$wgGroupPermissions['user']['createpage']       = true;

$wgGroupPermissions['*']['edittalk'] = false;
$wgGroupPermissions['*']['createtalk'] = false;
$wgGroupPermissions['user']['edittalk'] = true;
$wgGroupPermissions['user']['createtalk'] = true;
$wgGroupPermissions['user']['collectionsaveasuserpage'] = true;
$wgGroupPermissions['user']['collectionsaveascommunitypage'] = true;

// CLWB-303 Test
$wgGroupPermissions['oversight']['suppressrevision'] = true;
$wgGroupPermissions['oversight']['suppressionlog'] = true;

$wgGroupPermissions['observer']['viewsuppressed'] = true;
$wgGroupPermissions['sysop']['deletelogentry'] = true;
$wgGroupPermissions['sysop']['deleterevision'] = true;

//footer links
/*$wgHooks['SkinTemplateOutputPageBeforeExec'][] = function( $sk, &$tpl ) {
	$accessLink = Html::rawelement( 'a', [ 'href' => $wgServer . '/index.php?title=Clicklaw_Wikibooks:Accessibility_statement' ],
        'Accessibility statement' );
	$tpl->set( 'access', $accessLink );	
	$tpl->data['footerlinks']['places'][] = 'access';
	
    $tpl->set( 'footertext', 'Supported by the <a href = "https://www.clicklaw.bc.ca/organization/reformresearch/1002">Law Foundation of BC</a>, the <a href = "https://www.clicklaw.bc.ca/organization/solveproblems/1126">Law Society of BC</a>, and <a href = "https://www.clicklaw.bc.ca/organization/solveproblems/1003">BC Ministry of Attorney General</a>');
	$tpl->data['footerlinks']['places'][] = 'footertext';	
	return true;
};*/


$wgHooks['SkinAddFooterLinks'][] = function ( Skin $skin, string $key, array &$footerlinks ) {
    if ( $key === 'places' ) {
        $footerlinks['accessLink'] = Html::element( 'a',
		[
			'href' => '/index.php?title=Clicklaw_Wikibooks:Accessibility_statement',
			'rel' => 'noreferrer noopener' // not required, but recommended for security reasons
		],
		'Accessibility statement');
		
		$footerlinks['footertext0'] = 'Supported by the <a href = "https://www.clicklaw.bc.ca/organization/reformresearch/1002">Law Foundation of BC</a>, the <a href = "https://www.clicklaw.bc.ca/organization/solveproblems/1126">Law Society of BC</a>, and <a href = "https://www.clicklaw.bc.ca/organization/solveproblems/1003">BC Ministry of Attorney General</a>';
		
		/*$footerlinks['footertext1'] = Html::element( 'a',
		[
			'href' => 'https://www.clicklaw.bc.ca/organization/reformresearch/1002',
			'rel' => 'noreferrer noopener' // not required, but recommended for security reasons
		],
		'Supported by the Law Foundation of BC, ');
		
		$footerlinks['footertext2'] = Html::element( 'a',
		[
			'href' => 'https://www.clicklaw.bc.ca/organization/solveproblems/1126',
			'rel' => 'noreferrer noopener' // not required, but recommended for security reasons
		],
		'the Law Society of BC, ');
		
		$footerlinks['footertext3'] = Html::element( 'a',
		[
			'href' => 'https://www.clicklaw.bc.ca/organization/solveproblems/1003',
			'rel' => 'noreferrer noopener' // not required, but recommended for security reasons
		],
		'and BC Ministry of Attorney General');
		
		*/
		
	};
};


/*Controlling search engine indexing for all Namespace for staging and upgrade (no live)*/
if ($stageLive != "live"){
	$wgNamespaceRobotPolicies[NS_MAIN] = 'noindex';
	$wgNamespaceRobotPolicies[NS_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_USER] = 'noindex';
	$wgNamespaceRobotPolicies[NS_USER_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_PROJECT] = 'noindex';
	$wgNamespaceRobotPolicies[NS_PROJECT_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_FILE] = 'noindex';
	$wgNamespaceRobotPolicies[NS_FILE_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_MEDIAWIKI] = 'noindex';
	$wgNamespaceRobotPolicies[NS_MEDIAWIKI_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_TEMPLATE] = 'noindex';
	$wgNamespaceRobotPolicies[NS_TEMPLATE_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_HELP] = 'noindex';
	$wgNamespaceRobotPolicies[NS_HELP_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_CATEGORY] = 'noindex';
	$wgNamespaceRobotPolicies[NS_CATEGORY_TALK] = 'noindex';
	$wgNamespaceRobotPolicies[NS_SPECIAL] = 'noindex';
	$wgNamespaceRobotPolicies[NS_MEDIA] = 'noindex';
}
