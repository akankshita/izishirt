$j=jQuery.noConflict();
$j.blockUI.defaults.css.border = '2px solid #0099cc'; 

function buy_now_old_themes(){
  if ($('model_size_id').value != '0' ){ 
    document.form.submit();
  }
  else {
    $j.blockUI({ message: $j("#select_size"), css: {width: '320px'}, centerX: true, centerY: true, allowBodyStretch: false }); 
  }
}

function add_cookie_banner(){
	username_url = window.document.URL.replace("http://www.", "").replace("http://", "").split("/")[0].split(".")/*[0]*/
	
	/*pour test*/
	if (username_url[0] == "localhost:3000" || username_url[0] == "192"){
		username = "localhost_test"; domain = "";
	}
	else{
		domain = "; domain=.izishirt.ca";
	}
	
	if(username_url[1] == "com"){username = ""}
	else{username = username_url[0]}
	
	document.cookie="last_banner="+username+"; path=/"+domain;
}

function add_cookie_before_link(){
	this.add_cookie_banner();
}

function buy_now(){
  this.add_cookie_banner();

  if ($('model_size_id').value != '0' ){ 
    if ($('in_stock').value == "true") {
		document.form.submit();
    }
    else{
      $j.blockUI({ message: $j("#fail"), css: {width: '440px'}, centerX: true, centerY: true, allowBodyStretch: false }); 
      center_block();
    }
  }
  else {
    $j.blockUI({ message: $j("#select_size"), css: {width: '320px'}, centerX: true, centerY: true, allowBodyStretch: false }); 
    center_block();
  }
}

function add_to_cart(){
  this.add_cookie_banner();
	
  url="/my/add_product_from_boutique/";
  url+=$("product_id").value;
  url+='?model_size_id='+$("model_size_id").value;
  url+='&quantity='+$("quantity").value;
  url+='&add_to_cart=true';

  if ($('model_size_id').value != '0') {
    new Ajax.Request( url,{asynchronous:true, 
      evalScripts:true,
      onSuccess: function(transport) {
        if ($('in_stock').value == "true") {
          $("cart_details").innerHTML = transport.responseText; 
          $j.blockUI({ message: $j("#success"), css: {width: '400px'}, centerX: true, centerY: true, allowBodyStretch: false }); 
        }
        else{
          $j.blockUI({ message: $j("#fail"), css: {width: '440px'}, centerX: true, centerY: true, allowBodyStretch: false }); 
        }
        center_block();
      }
    });

  }
  else {
    $j.blockUI({ message: $j("#select_size"), css: {width: '320px'}, centerX: true, centerY: true, allowBodyStretch: false });
    center_block();
  }
}

function update_cart(){
  new Ajax.Request( "/my/get_cart_details",{asynchronous:true, 
    evalScripts:true,
    onSuccess: function(transport) {
      $("cart_details").innerHTML = transport.responseText; 
    }
  });
}

function center_block(){
  var width = $j(window).width();
  var height = $j(window).height();
  width = width/2-$j('.blockPage').width()/2
  height = 50
 
  $j('.blockPage').css('left',width);
  $j('.blockPage').css('top',height);
}

function resize_banner(){
  $j('#banner_div').height($j('#hidden_image').height());
}

function show_preview(id){

  if ( $j("#over_"+id).attr("src") == $j("#preview_"+id).attr("src") ){
    $j("#over_"+id).css("width",$j("#preview_"+id).css("width"));
    $j("#over_"+id).css("height",$j("#preview_"+id).css("height"));
  }
    
  $j("#preview_"+id).css("display", "none");
  $j("#over_"+id).css("display", "inline");

  //$j("#preview_"+id).css("vertical-align", "middle");
  //$j("#over_"+id).css("vertical-align", "middle");
}
function hide_preview(id){
  $j("#preview_"+id).css("display", "inline");
  $j("#over_"+id).css("display", "none");

  //$j("#preview_"+id).css("vertical-align", "middle");
  //$j("#over_"+id).css("vertical-align", "middle");
}
function toggle_preview(id, preview, original){
  if ( $j("#"+id).attr("src") == preview )
    $j("#"+id).attr("src", original);
  else
    $j("#"+id).attr("src", preview);
} 

function open_apparel_popup(id){
  window.open('http://www.izishirt.ca/popup/apparel/'+id,'copyright','width=615,height=500,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,copyhistory=no,resizable=yes');
}

function open_apparel_popup_with_lang(id, lang){
  window.open('http://www.izishirt.ca' + lang + '/popup/apparel/'+id,'copyright','width=615,height=500,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,copyhistory=no,resizable=yes');
}

function toPositiveInteger(value)
{
  var toInt = parseInt(value);

  if (isNaN(toInt))
  {
    toInt = 1;
  }

  if (toInt <= 0)
  {
    toInt = 1;
  }

  return toInt;
}

function checkGoToCheckout2(product_id, print_force_lang)
{
  if ($("model_size_id").value == "0")
  {
    $j("#link_please_choose_a_size").click();
  }
  else
  {
    document.getElementById("link_popup_cart").href = print_force_lang + "my/add_product_from_boutique_popup?product="+product_id+"&model_size_id=" + $('model_size_id').value + "&quantity=" + $('quantity').value+"&color_id="+$('color_id').value + "&marketplace_affiliate_id="+$('marketplace_affiliate_id').value;

    $j("#link_popup_cart").click();
  }

}

function checkGoToCheckout2FromIframe(product_id, print_force_lang)
{

  if ($("model_size_id").value == "0")
  {
    $j("#link_please_choose_a_size").click();
  }
  else
  {
    document.getElementById("link_popup_cart").href = print_force_lang + "my/add_product_from_boutique_popup?product="+product_id+"&model_size_id=" + $('model_size_id').value + "&quantity=" + $('quantity').value+"&color_id="+$('color_id').value + "&iframe=true&marketplace_affiliate_id="+$('marketplace_affiliate_id').value;
;

    $j("#link_popup_cart").click();
  }

}
