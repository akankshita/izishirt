// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults



function limitNbTags(value, max_nb_tags, id_msg_error_div, msg_error)
{
    document.getElementById(id_msg_error_div).innerHTML = "";

    value = value.toString();

    var tags = value.split(",")

    var nbOccs = tags.length-1;

    if (nbOccs >= max_nb_tags)
    {
        var tmp_value = "";

        // Ok we must cut that damn string, let's rebuild the tags
        for (i= 0; i < tags.length && i < max_nb_tags; ++i)
        {
            tmp_value += tags[i] + ",";
        }

        var last = tmp_value.lastIndexOf(",");
        tmp_value = tmp_value.substring(0, last);

        document.getElementById(id_msg_error_div).innerHTML = msg_error;

        return tmp_value;
    }

    return value;
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

function limitPositiveFloatBetween(value, minVal, maxVal)
{
    value = toPositiveFloat(value);

    if (value < minVal)
        value = minVal;

    if (value > maxVal)
        value = maxVal;

    return value;
}

function toPositiveFloat(value)
{
	var tof = parseFloat(value);

	if (isNaN(tof))
	{
		tof = 0.00;
	}

	if (tof <= 0)
	{
		tof = 0.00;
	}

	return tof;
}

function toggle_all(){
  $$('input').each(function(element){
    if (element.type == 'checkbox'){
      element.checked = $("all").checked;
    }
  });
}

var $j = jQuery.noConflict();

function handleResponse(documentObject,stringToEvaluate) {
window.eval(stringToEvaluate);
if (documentObject.location){ // Should be usefull for IE only .. but I cannot test it
if(documentObject.location != "") documentObject.location.replace('about:blank');
}
}

function set_order_color(color_id, model_id) {

 //clear highlighting from other color blocks
 $j('.color_block').css('border', '1px solid #999999');  
  
 //Highlight correct element
 element = "order_color_"+color_id; 
 $(element).setStyle({ 'border': '1px solid rgb(0,0,0)' });

 $("current_color").src = $(element).src;
 $("current_color_name").innerHTML = $(element).alt;
 
 //Put the id in the hidden form field
 $("color_id").value = (color_id);
 
 //Change Large Model Image
 //$("model_layer").src = "/izishirtfiles/models/"+model_id+"/"+color_id+"-front.jpg";
 fade_to('model_layer',"/izishirtfiles/models/"+model_id+"/"+color_id+"-front.jpg", "shop1Fader");

 //Change personalize link url
  old_link = $("personalize_link").href;
 base = old_link.split('?')[0]; 
 new_link = base+'?'+'model='+model_id+'&color='+color_id;
 $("personalize_link").href = new_link;
 
 
}


function shop1_update_price(model,size){
  $j("#model_size_id").val(size);
  new Ajax.Request('/display/update_price/'+model+'/'+size, {asynchronous:true, evalScripts:true});
}

function shop2_update_price(model,size){
  $j("#model_size_id").val(size);
  var quantity = document.getElementById("quantity").value;
  new Ajax.Request('/display/update_price_shop2/'+model+'/'+size + '?quantity=' + quantity, {asynchronous:true, evalScripts:true});
}

//Delete image used on myizishirt account info popup
function do_delete(){
    document.getElementById('delimg').value = "yes";
    $("accountForm").submit();
}


function tab_click(id){
  $j(".tabs .active").addClass('inactive');
  $j(".tabs .active").removeClass('active');
  $j("#"+id+"_tab").addClass("active");
  $j("#"+id+"_tab").removeClass("inactive");
  $j(".tabContent").hide();
  $j("#"+id+"_content").show();
}

function hover_over_design(id){
  $j("#imageWrapper_"+id).removeClass("imageWrapper");
  $j("#imageWrapper_"+id).addClass("imageWrapperSelected");
}

function hover_out_design(id){
  $j("#imageWrapper_"+id).removeClass("imageWrapperSelected");
  $j("#imageWrapper_"+id).addClass("imageWrapper");
}


function sort_by_fix(){
  $('sort_by').observe('change',function() {
    option = $('sort_by').getElementsByTagName("option");
    for(d = 0; d < option.length; d++) {
      if(option[d].selected == true) {
        document.getElementById("select" + $('sort_by').name).childNodes[0].nodeValue = option[d].childNodes[0].nodeValue;
      }
    }
  });
}

function add_to_cart_apparel(){
  add_url="/checkout2/add_product_from_apparel/";
  add_url+='?size='+$("model_size_id").value;
  add_url+='&quantity='+$("quantity").value;
  add_url+='&color='+$("color_id").value;
  add_url+='&model='+$("model_id").value;

  update_url ="/apparel/update_savings";
  update_url+='?size='+$("model_size_id").value;
  update_url+='&qty='+$("quantity").value;
  update_url+='&id='+$('model_id').value;
  update_url+='&color='+$("color_id").value;

  new Ajax.Request( add_url,{asynchronous:true, 
    evalScripts:true,
    onSuccess: function(transport) {
      if ($('in_stock').value == "true"){
        display_small_lightbox('/apparel/added_to_cart');
        new Ajax.Request( update_url,{asynchronous:true, evalScripts:true});
      }
      else{
        display_small_lightbox('/apparel/out_of_stock');
      }
    }
  });

}

function add_to_cart_apparel_checkout(){
  url="/checkout2/add_product_from_apparel/";
  url+='?size='+$("model_size_id").value;
  url+='&quantity='+$("quantity").value;
  url+='&color='+$("color_id").value;
  url+='&model='+$("model_id").value;

  new Ajax.Request( url,{asynchronous:true,
    evalScripts:true,
    onSuccess: function(transport) {
      if ($('in_stock').value == "true")
        document.location.href="/checkout2/show_cart";
      else
        display_small_lightbox('/apparel/out_of_stock');
    }
  });

}


function add_to_cart_shop1(){
  add_url="/checkout2/add_product_from_shop1/";
  add_url+='?size='+$("model_size_id").value;
  add_url+='&quantity='+$("quantity").value;
  add_url+='&color='+$("color_id").value;
  add_url+='&model='+$("model_id").value;
  add_url+='&image='+$("image_id").value;

  update_url = "/display/update_savings";
  update_url+= "?shirt="+$('model_id').value;
  update_url+= "&qty="+$("quantity").value;
  update_url+= "&size="+$("model_size_id").value;
  update_url+= "&color="+$("color_id").value;

  new Ajax.Request( add_url,{asynchronous:true,
    evalScripts:true,
    onSuccess: function(transport) {
      if ($('in_stock').value == "true")
        display_small_lightbox('/display/added_to_cart');
      else
        display_small_lightbox('/display/out_of_stock');
      new Ajax.Request( update_url,{asynchronous:true, evalScripts:true} );
    }
  });
}

function add_to_cart_landing_page(){
  url="/checkout2/add_product_from_landing_products/";
  url+=$("product_id").value;
  url+='?model_size_id='+$("model_size_id").value;
  url+='&quantity='+$("quantity").value;
  url+='&add_to_cart=true';

  new Ajax.Request(url);
}
function landing_page_checkout(){
  if ($('model_size_id').value == '-----') {
    display_small_lightbox('/display/select_size');
    return;
  }
  add_to_cart_landing_page();
  if ($('in_stock').value == "true"){
    new Ajax.Request( "/checkout2/cart_item_count",{asynchronous:true,
      evalScripts:true,
      onSuccess: function(transport) {
          document.location.href="/checkout2/show_cart"
      }
    });
  }
  else{
    display_small_lightbox('/display/out_of_stock');
  }
}

function display_small_lightbox(url){
    alert();
    link = document.createElement('a');
    link.href = url;
    link.name = 'light_login';
    light = new lightbox(link);
    light.activate();
}

function popup_shop_1_apparel_details(){
  new Ajax.Request( "/display/empty",{asynchronous:true,
    evalScripts:true,
    onSuccess: function(transport) {
      link = document.createElement('a');
      link.href = '/display/popup_shop_1_apparel_details/'+$("model_id").value;
      link.name = 'light_apparel_details';
      light = new lightbox(link);
      light.activate();
    }
  });

}

function show_box_hosted_by()
{
	display_small_lightbox('/display/hosted_by');
}

function add_to_cart_shop1_checkout(){
  url="/checkout2/add_product_from_shop1/";
  url+='?size='+$("model_size_id").value;
  url+='&quantity='+$("quantity").value;
  url+='&color='+$("color_id").value;
  url+='&model='+$("model_id").value;
  url+='&image='+$("image_id").value;

  new Ajax.Request( url,{asynchronous:true, 
    evalScripts:true,
    onSuccess: function(transport) {
      if ($('in_stock').value == "true")
        document.location.href="/checkout2/show_cart"
      else
        display_small_lightbox('/display/out_of_stock');
    }
  });

}

function shop1_select_category(id){
 $j(".atab_link").removeClass("active");
 $j("#cat_link_"+id).addClass("active"); 
 $j(".atab_shirts").addClass("none");
 $j("#shirts_"+id).removeClass("none"); 
}

function open_terms_popup(){
    window.open('/popup/terms','terms','width=450,height=470,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,copyhistory=no,resizable=yes');
}

function open_terms_marketplace_popup(){
    window.open('/popup/terms_marketplace','terms','width=450,height=470,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,copyhistory=no,resizable=yes');
}

function open_copyright_popup(){
    window.open('/popup/copyright','copyright','width=632,height=560,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,copyhistory=no,resizable=yes');
}

function open_apparel_popup(id){
    window.open('/popup/apparel/'+id,'Apparel','width=615,height=600,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,copyhistory=no,resizable=yes');
}
function open_apparel_popup_with_lang(id, lang){
    window.open(lang + '/popup/apparel/'+id,'Apparel','width=615,height=600,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=no,copyhistory=no,resizable=yes');
}
function open_decline_popup(){
    window.open('/popup/decline','Decline','width=615,height=600,toolbar=no,location=no,directories=no,status=no,menubar=no,scrollbars=yes,copyhistory=no,resizable=yes');
}



function redirect_to(url){
    window.location = url;
    return false;
}

function checkGoToCheckout2(product_id)
{
  if ($("model_size_id").value == 0)
  {
    $j("#link_please_choose_a_size").click();
  }
  else
  {
    document.getElementById("link_popup_cart").href = "/popup/shop_2_add_to_cart_continue_shopping?product_id="+product_id+"&model_size_id=" + $('model_size_id').value + "&quantity=" + $('quantity').value+"&color_id="+$('color_id').value;
    $j("#link_popup_cart").click();
  }
}

function checkGoToCheckout2Blank(product_id)
{
  if ($("model_size_id").value == 0)
  {
    $j("#link_please_choose_a_size").click();
  }
  else
  {
    document.getElementById("link_popup_cart").href = "/popup/shop_2_add_to_cart_continue_shopping?product_id="+product_id+"&model_size_id=" + $('model_size_id').value + "&quantity=" + $('quantity').value+"&color_id="+$('color_id').value;
    $j("#link_popup_cart").click();
  }
}

function checkGoToCheckout2Store(product_id)
{
  if ($("model_size_id").value == 0)
  {
    $j("#link_please_choose_a_size").click();
  }
  else
  {
    document.getElementById("form_model").submit();
  }
}

function checkGoToCheckout2StoreTransfer(product_id)
{
  if ($("model_size_id").value == 0)
  {
    $j("#link_please_choose_a_size").click();
  }
  else if($("comment_area").value.length == 0)
  {
    $j("#error_section").show();
  }
  else
  {
    document.getElementById("form_model").submit();
  }
}

function checkGoToCheckoutShop2()
{
 if(parseInt($("quantity").value) < 1 || $("quantity").value=="")
 {
     $j("#link_please_choose_quantity").click();
     return false;
 }
  if ($("model_size_id").value == 0)
  {
    $j("#link_please_choose_a_size").click();
    return false;
  }
  return $('shop2Form').submit();
}



