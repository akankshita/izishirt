<?php
// 
// 
// Application: Wordans
// File: 'index.php' 
// 
// 

require_once 'client/facebook.php';

$appapikey = 'e7bada22344a845c6e3984e391cae1db';
$appsecret = '9b9691bda0c8cb18ae6599710640ead4';
$facebook = new Facebook($appapikey, $appsecret);

//$profileId = $facebook->get_loggedin_user(); // If the user is logged in and looks at their own wordans app this is the way to get their profile id


$linkFromFBBanner = $_GET['linkFromFBBanner'];//If the facebook user hasn't installed the wordans app we still want them to see it in a public canvas page

if($linkFromFBBanner == 'true'){//public canvas page

	$user = $facebook->get_loggedin_user();
	
}else{//do a login and configuration or show them the app if they have already installed it

	$user = $facebook->require_login();

	$appcallbackurl = 'http://www.wordans.com/wordans_flash/facebook_callback';

	// catch the exception that gets thrown if the cookie has 
	// an invalid session_key in it
	try {
	  if (!$facebook->api_client->users_isAppAdded()) {
		$facebook->redirect($facebook->get_add_url());
	  }
	} catch (Exception $ex) {
	  // this will clear cookies for your application and 
	  // redirect them to a login prompt
	  $facebook->set_user(null, null);
	  $facebook->redirect($appcallbackurl);
	}

}

?>
<!--<fb:swf swfsrc='http://www.wordans.com.com/flash/facebook/loader.swf?version="1" ' imgsrc='http://www.skeeker.com/sites/facebook/wordans/clickhere.jpg' width='185' height='280' flashvars='asset_path=http://www.skeeker.com/sites/facebook/wordans/' />-->



<script type="text/javascript" src="swfobject.js"></script>
<style type="text/css">
	
	body { 
		background-color: #ffffff;
		font: .8em/1.3em verdana,arial,helvetica,sans-serif;
	}

	#info {
		width: 300px;
		overflow: auto;
	}

	#flashcontent { 
	border: solid 0px #000;
	width: 100%;
	height: 100%;
	float: left;
	margin: 0px 0px;
	text-align:center;
	}
	

</style>
</head>
<body>
	<div id="flashcontent">
		<strong>You need to upgrade your Flash Player</strong>
		This is replaced by the Flash content. 
		Place your alternate content here and users without the Flash plugin or with 
		Javascript turned off will see this. Content here allows you to leave out <code>noscript</code> 
		tags. Include a link to <a href="IEFixTemplateSwfObject.html?detectflash=false">bypass the detection</a> if you wish.
	</div>

	<script type="text/javascript">
		// <![CDATA[
		
		var so = new SWFObject("http://www.wordans.com/flash/facebook/loader.swf?profileId=<?php echo($_GET['profileId']);?>&productId=<?php echo($_GET['productId']);?>&asset_path=http://www.skeeker.com/sites/wordans/&sessionVar=j64rhfuriok78436iashfm&sessionLanguage=en&InterfaceXmlPath=datastorage/Interface_en.xml&InterfaceStaticXmlPath=datastorage/Babel_en.xml&ProductsXmlPath=datastorage/ModelsAndProducts.xml&DesignsXmlPath=datastorage/Designs_multiple.xml&config=datastorage/config.xml&themeColor=1D91C7&mouseOverColor=cfcfcf&bgColor=f4f4f4&bgCornerColor=ffffff&altBtn_themeColor=9E0221&altBtn_mouseOverColor=534C4C&altBtn_textColor=FFFFFF&shop=shopId&currency=currencyId&loadingText=LoadingApplication&versionInfo=versionRC1&inputParam=inputParam", "wordans", "607", "471", "8", "#FFFFFF");
		so.write("flashcontent");
		
		// ]]>
	</script>



