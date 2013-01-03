
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>

<meta name="Description" content="Javascript file combinationalizer and minifier" />
<meta name="Keywords" content="Javascript file combinationalizer and minifier" />
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" />
<meta name="Distribution" content="Global" />
<meta name="Robots" content="index,follow" />

<link rel="stylesheet" href="/images/HarvestField.css" type="text/css" />
<link rel="shortcut icon" type="image/png" href="/images/ScriptalizerIcon.png" />



	
	
	
	
	

		
		
		
		
		
		
<script type="text/javascript" src="/js/scriptalizer_0ADA14DD-C46D-06D0-F2690B8237D3D3BE.js"></script>


<title>Scriptalizer.com: Combine and Minify Your Javascript and CSS!</title>
<script type="text/javascript">
$(document).ready(function() {
	$('#Upload').MultiFile();
	$('#UploadCss').MultiFile();
});
function hideDownloadLink(type){
	if (type =='js')
	{
		$('#downloadLink').hide();$("#downloadComplete").show()
	}
	else
	{
		$('#downloadLinkCss').hide();$("#downloadCompleteCss").show()
	}
}
</script>
</head>

<body>
<!-- wrap starts here -->
<div id="wrap">

	<!--header -->
	<div id="header">			
				
		<h1 id="logo-text"><a href="/" title="">Script<span>alizer</span></a></h1>		
		<h2 id="slogan">putting the "alizer" after "script"...</h2>		
			
		<div id="header-links">
			<p>
			 Scriptalizer.com has saved the world:<br />
			<div align="center">
				<div style="font-size:25px;font-weight:bold;margin-bottom:5px;">78207.31 KB</div>
				of bloated javascript and CSS
			</div> 
			</p>
			
		</div>				
				
	<!--header ends-->					
	</div>
		
	<!-- navigation starts-->	
	<div  id="nav">
		
		<div id="light-brown-line"></div>	
		

		<div style="float:right;padding-top:25px">
			<script type="text/javascript"><!--
			google_ad_client = "pub-1882591018362100";
			/* scriptalizer topnav, created 7/9/08 */
			google_ad_slot = "2840347906";
			google_ad_width = 468;
			google_ad_height = 15;
			//-->
			</script>
			<script type="text/javascript"
			src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
			</script>
		</div>

	<!-- navigation ends-->	
	</div>	
		
	<!-- content-wrap starts -->
	<div id="content-wrap">
				
		<div id="sidebar">
			
			
					
			<ul class="sidemenu">				
				<li><a href="/">Home</a></li>
			</ul>	
			
			<h1>Like Scriptalizer.com?</h1>
			<div align="center">
				<div style="background-color:white;text-align:center;width:90px;padding:10px;margin:10px;border:1px solid #6C4F2F">
					<script type="text/javascript">
					digg_url = 'http://digg.com/programming/Free_website_to_combine_and_minify_javascript_files';
					</script>
					<script src="http://digg.com/tools/diggthis.js" type="text/javascript"></script> 			
				</div>
				<br />
				
				<script type="text/javascript"><!--
				google_ad_client = "pub-1882591018362100";
				/* scriptalizer 200x90, created 7/9/08 */
				google_ad_slot = "9438416796";
				google_ad_width = 200;
				google_ad_height = 90;
				//-->
				</script>
				<script type="text/javascript"
				src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
				</script>

			</div>
	
					
			
						
		<!-- sidebar ends -->		
		</div>
				
		<div id="main">
			
			
				<h1>Add your scripts</h1>
			
			<form method="post" action="/index.cfm/do/submitScripts/" enctype="multipart/form-data">
				<label for="jsfile">Add Javascript Files:</label>
				<div style="margin:2px"><input type="checkbox" name="AddJSComments" value="true" /> Include file list in comments?</div>
			
				<input type="file" id="Upload" name="jsfile" class="multi" accept="js" value="">	
			
				<br />
			
			
				<label for="cssfile">Add CSS Files:</label>
				<div style="margin:2px"><input type="checkbox" name="AddCSSComments" value="true" /> Include file list in comments?</div>
				<input type="file" id="UploadCss" name="cssfile" class="multi" accept="css" value="">	
				<input class="button" type="submit" value="Go!" >
			</form>	
			
			
			
			<h1>What does it do?</h1>
				
			<h3>Turn this...</h3>				
			<p><code>
				
				
					&lt;script type=&quot;text/javascript&quot; src=&quot;/js/jquery/jquery.js&quot;&gt;&lt;/script&gt;
					&lt;script type=&quot;text/javascript&quot; src=&quot;/js/jquery/jquery.form.js&quot;&gt;&lt;/script&gt;
					&lt;script type=&quot;text/javascript&quot; src=&quot;/js/myOwnScriptFile.js&quot;&gt;&lt;/script&gt;
					
				</code>	
				<code>
				
					&lt;link rel=&quot;stylesheet&quot; href=&quot;/style/longstylesheet.css&quot; type=&quot;text/css&quot; /&gt;
					&lt;link rel=&quot;stylesheet&quot; href=&quot;/style/anotherlongstylesheet.css&quot; type=&quot;text/css&quot; /&gt;
				
				
	
			</code></p>	
				
			<h3>Into this...</h3>				
			<p><code>
				
				
					&lt;script  type=&quot;text/javascript&quot;   src=&quot;/js/scriptalizer.js&quot; &gt;&lt;/script&gt;	
				
				
				</code><code>
				
				
					&lt;link  rel=&quot;stylesheet&quot;  href=&quot;/style/scriptalizer.css&quot; type=&quot;text/css&quot; /&gt;	
				
				
				</code>
			
			</p>	
						
			<h3>What?! It minifies too?!??!</h3>
			<p>Yep, thats right.  The combined javscript file is minfied.  How bout them apples?</p>
			
			<h3>OMG IT COMPRESSES CSS?!!!!!!!!!11</h3>
			<p>Yes, calm down.  The generated CSS file is compressed.  It's going to be ok...really.</p>
			
			
				
			<div align="center">
			<br />
			<script type="text/javascript"><!--
			google_ad_client = "pub-1882591018362100";
			/* scriptalizer 468x60, created 7/9/08 */
			google_ad_slot = "2387166806";
			google_ad_width = 468;
			google_ad_height = 60;
			//-->
			</script>
			<script type="text/javascript"
			src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
			</script>	
			</div>

			<br />
			<h3>What is this "Minify" thing?</h3>
			<blockquote>
			<p>"Minify, in computer programming languages, is the process of removing all unnecessary characters from source code, without changing its functionality.</p> 
			
			<p>These unnecessary characters usually include white space characters, new line characters, comments and sometimes block delimiters; which are used to add readability to the code, but are not required for it to execute.</p>
			
			<p>Minified source code is specially useful for interpreted languages deployed and transmitted on the Internet (such as JavaScript), because it reduces the amount of data that needs to be transferred.</p> 
			
			<p>Minified source code may also be used as a kind of obfuscation."</p>
			</blockquote>
			<div style="text-align:right;margin-right:25px">
				<a class="readmore" href="http://en.wikipedia.org/wiki/Minify">>>source wikipedia<<</a>
			</div>				
		<!-- main ends -->	
		</div>
		
	<!-- content-wrap ends-->	
	</div>
	
	<!-- column starts -->		
	<div id="column-wrap">
		
		<div id="columns">
	
			
			<div align="center">
				<script type="text/javascript"><!--
				google_ad_client = "pub-1882591018362100";
				/* scriptalizer footer 468x60, created 7/10/08 */
				google_ad_slot = "3684306881";
				google_ad_width = 468;
				google_ad_height = 60;
				//-->
				</script>
				<script type="text/javascript"
				src="http://pagead2.googlesyndication.com/pagead/show_ads.js">
				</script>
			</div>
		<!-- footer-columns ends -->

		</div>	
		
	<!-- column-wrap ends-->
	</div>
	
	<!-- footer starts -->
	<div id="footer">		
			
		<p>
		&copy; 2009 <strong>Scriptalizer.com</strong> | 
		Design by: <a href="http://www.styleshout.com/">styleshout</a> | 
		Valid <a href="http://jigsaw.w3.org/css-validator/check/referer">CSS</a>
			
   	&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			
		<a href="/">Home</a>&nbsp;
   	</p>		

	<!-- footer ends -->		
	</div>	

<!-- wrap ends here -->
</div>
<script type="text/javascript">
var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
var pageTracker = _gat._getTracker("UA-4954019-1");
pageTracker._initData();
pageTracker._trackPageview();
</script>
</body>
</html>

		
	
		
		
		

		
		
		

		

		

		
			
		
	
	
		
		
			
		
	
		
		
		

		
		
		

		

		

		
			
		
	
		
		
	
			
			
	
		
		
		
		
		
		
		
		

		
		
		

		

		

		
			
		
	
		
		
		
		
		
		
		
	
	
	
		


	