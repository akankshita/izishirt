/*
Created By: Chris Campbell
Website: http://particletree.com
Date: 2/1/2006

Inspired by the lightbox implementation found at http://www.huddletogether.com/projects/lightbox/
*/

/*-------------------------------GLOBAL VARIABLES------------------------------------*/

var detect = navigator.userAgent.toLowerCase();
var OS,browser,version,total,thestring;

/*-----------------------------------------------------------------------------------------------*/

//Browser detect script origionally created by Peter Paul Koch at http://www.quirksmode.org/

function getBrowserInfo() {
	if (checkIt('konqueror')) {
		browser = "Konqueror";
		OS = "Linux";
	}
	else if (checkIt('safari')) browser 	= "Safari"
	else if (checkIt('omniweb')) browser 	= "OmniWeb"
	else if (checkIt('opera')) browser 		= "Opera"
	else if (checkIt('webtv')) browser 		= "WebTV";
	else if (checkIt('icab')) browser 		= "iCab"
	else if (checkIt('msie')) browser 		= "Internet Explorer"
	else if (!checkIt('compatible')) {
		browser = "Netscape Navigator"
		version = detect.charAt(8);
	}
	else browser = "An unknown browser";

	if (!version) version = detect.charAt(place + thestring.length);

	if (!OS) {
		if (checkIt('linux')) OS 		= "Linux";
		else if (checkIt('x11')) OS 	= "Unix";
		else if (checkIt('mac')) OS 	= "Mac"
		else if (checkIt('win')) OS 	= "Windows"
		else OS 								= "an unknown operating system";
	}
}

function checkIt(string) {
	place = detect.indexOf(string) + 1;
	thestring = string;
	return place;
}

/*-----------------------------------------------------------------------------------------------*/

Event.observe(window, 'load', initialize, false);
Event.observe(window, 'load', getBrowserInfo, false);
Event.observe(window, 'unload', Event.unloadCache, false);

var lightbox = Class.create();

lightbox.prototype = {

	yPos : 0,
	xPos : 0,

	initialize: function(ctrl) {
		this.content = ctrl.href;
		this.extra_class = ctrl.name;
		Event.observe(ctrl, 'click', this.activate.bindAsEventListener(this), false);
		ctrl.onclick = function(){return false;};
        ctrl.style.display = "inline";
	},
	
	// Turn everything on - mainly the IE fixes
	activate: function(){
		if (browser == 'Internet Explorer'){
			this.getScroll();
      this.prepareIE('100%', 'hidden');
			this.setScroll(0,0);
			this.hideSelects('hidden');
		}
		this.displayLightbox("block");
	},
	
	// Ie requires height to 100% and overflow hidden or else you can scroll down past the lightbox
	prepareIE: function(height, overflow){
    $('overlay').setStyle({height:$j(document).height()+'px'});           
    $j(document).scrollTop(0);
		//bod = document.getElementsByTagName('body')[0];
		//bod.style.height = height;
		//bod.style.overflow = overflow;
  
		//htm = document.getElementsByTagName('html')[0];
		//htm.style.height = height;
		//htm.style.overflow = overflow; 
	},
	
	// In IE, select elements hover on top of the lightbox
	hideSelects: function(visibility){
		selects = document.getElementsByTagName('select');
		for(i = 0; i < selects.length; i++) {
			selects[i].style.visibility = visibility;
		}
	},
	
	// Taken from lightbox implementation found at http://www.huddletogether.com/projects/lightbox/
	getScroll: function(){
		if (self.pageYOffset) {
			this.yPos = self.pageYOffset;
		} else if (document.documentElement && document.documentElement.scrollTop){
			this.yPos = document.documentElement.scrollTop; 
		} else if (document.body) {
			this.yPos = document.body.scrollTop;
		}
	},
	
	setScroll: function(x, y){
		window.scrollTo(x, y); 
	},
	
	displayLightbox: function(display){
		$('overlay').style.display = display;
		$('lightbox').style.display = display;
		if(display != 'none') this.loadInfo();
	},
	
	// Begin Ajax request based off of the href of the clicked linked
	loadInfo: function() {
		var myAjax = new Ajax.Request(
        this.content,
        {method: 'post',evalJS: 'true', parameters: "", onComplete: this.processInfo.bindAsEventListener(this)}
		);
		
	},
	
	// Display Ajax response
	processInfo: function(response){
		info = "<div id='lbContent' class='cbb "+this.extra_class+"'>" + response.responseText + "</div>";
		new Insertion.Before($('lbLoadMessage'), info)
		$('lightbox').className = "done";	
    centerLightbox();
		this.actions();			
	},
	
	// Search through new links within the lightbox, and attach click event
	actions: function(){
		lbActions = document.getElementsByClassName('lbAction');

		for(i = 0; i < lbActions.length; i++) {
			Event.observe(lbActions[i], 'click', this[lbActions[i].rel].bindAsEventListener(this), false);
			lbActions[i].onclick = function(){return false;};
		}

	},
	
	// Example of creating your own functionality once lightbox is initiated
	insert: function(e){
	   link = Event.element(e).parentNode;
     if (link.href == undefined) link = Event.element(e);
	   Element.remove($('lbContent'));

	   var myAjax = new Ajax.Request(
			  link.href,
			  {method: 'post', evalJS: 'true', parameters: "", onComplete: this.processInfo.bindAsEventListener(this)}
	   );
	 
	},
	
	// Example of creating your own functionality once lightbox is initiated
	deactivate: function(){
		Element.remove($('lbContent'));
		
		if (browser == "Internet Explorer"){
			this.setScroll(0,this.yPos);
			this.prepareIE("auto", "auto");
			this.hideSelects("visible");
		}
		
		this.displayLightbox("none");
	}
}

/*-----------------------------------------------------------------------------------------------*/

// Onload, make all links that need to trigger a lightbox active
function initialize(){
	addLightboxMarkup();
	lbox = document.getElementsByClassName('lbOn');
	for(i = 0; i < lbox.length; i++) {
		valid = new lightbox(lbox[i]);
	}
  query=window.location.search.substring(1);
  vars = query.split("&");
  for (i=0;i<vars.length;i++) {
    varname = vars[i].split("=");
    if (varname[0] == 'lightbox') {
      link = document.createElement('a'); 
      if (varname[1] == 'login') {
       link.href = '/myizishirt/login/lightbox';
       link.name = 'light_login';
      }
      else if (varname[1] == 'lost') {
       link.href = '/myizishirt/login/lightbox_lost';
       link.name = 'light_login';
      }
      else if (varname[1] == 'account') {
       link.href = '/myizishirt/profile/profile';
       link.name = 'light_account';
      }
      else if (varname[1] == 'design') {
       link.href = '/myizishirt/design/upload';
       link.name = 'light_upload';
      }
     login = new lightbox(link);
     login.activate();
    }
  }

}

function reInitialize(){
	lbox = document.getElementsByClassName('lbOn');
	for(i = 0; i < lbox.length; i++) {
    lbox[i].stopObserving();
		valid = new lightbox(lbox[i]);
	}
}

function centerLightbox(){
  var width = $j(window).width();
  var height = $j(window).height();
  width = width/2-$j('#lbContent').width()/2
  height = height/2-$j('#lbContent').height()/2;
 
  if ( height <= 50 ) height = 50
  else height -= 50

  if ( $j('#lbContent').css('position') != 'fixed' ){
    width += $j(window).scrollLeft();
    height += $j(window).scrollTop();
  }

  $j('#lightbox').css('left',width);
  $j('#lightbox').css('top',height);
}

// Add in markup necessary to make this work. Basically two divs:
// Overlay holds the shadow
// Lightbox is the centered square that the content is put into.
function addLightboxMarkup() {
	bod 				= document.getElementsByTagName('body')[0];
	overlay 			= document.createElement('div');
	overlay.id		= 'overlay';
	lb					= document.createElement('div');
	lb.id				= 'lightbox';
	lb.className 	= 'loading';
	lb.innerHTML	= '<div id="lbLoadMessage">' +
						  '<p>Loading</p>' +
						  '</div>';
	bod.appendChild(overlay);
	bod.appendChild(lb);
}
