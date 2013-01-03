var $j = jQuery.noConflict();

function toggle_garments(name){
  $$(name).each(function(element){
    if (element.getStyle('display') == 'none') 
      element.show();
    else
      element.hide();
  });  
}
function toggle_group(name,parent_checkbox){
  name.split(",").each(function(id){
    $("ordered_product_"+id).checked = $(parent_checkbox).checked;
  });
}
function toggle_all(){
  $$('input').each(function(element){
    if (element.type == 'checkbox'){
      element.checked = $("all").checked;
    }
  });
}

function apply_action(){
  select = $('apply_action');
  if (select.selectedIndex != 0){
    action = select.value;
    text = select.options[select.selectedIndex].text;
    var answer = confirm("Are you sure you wish to apply the follow action?\n\n - "+text);
    if (answer){
      $("orders_form").action += "/" + action;
      $("orders_form").submit();
    }
    else{
      $('apply_action').selectedIndex = 0;
    }
  }
}
function set_order(){
  select = $('apply_action');
  if (select.selectedIndex != 0){
    action = select.value;
    text = select.options[select.selectedIndex].text;
    var answer = confirm("Are you sure you wish to apply the follow action?\n\n - "+text);
    if (answer){
      $("ordered_product_form").action += "/" + action;
      $("ordered_product_form").submit();
    }
    else{
      $('apply_action').selectedIndex = 0;
    }
  }
}
function update_tracking(url,id,track){
  url+="/admin/order/update_tracking/"+id+"/"+track;
  window.location=url;
}

function update_listing(url,id,track,paid_amount,paid){
  
  //rails routing 1.2 does not allow '.' in url params
  //make paid_amount 0.0 if blank
  if (paid_amount == '')
    paid_amount = '0.0';
  paid_amount = paid_amount.replace('.','_')
  track = track.replace('.','_')
      
  //rails routing 1.2 does not allow blank url params eg http://www.izishirt.ca/123//tracking_num/
  if (track == '')
    track = ' ';

  url+=escape("/admin/order/update_listing/"+id+"/"+track+"/"+paid_amount+"/"+paid);
  window.location=url;
}


function set_order(){
  select = $('apply_action');
  if (select.selectedIndex != 0){
    action = select.value;
    text = select.options[select.selectedIndex].text;
    var answer = confirm("Are you sure you wish to apply the follow action?\n\n - "+text);
    if (answer){
      $("ordered_product_form").action += "/" + action;
      $("ordered_product_form").submit();
    }
    else{
      $('apply_action').selectedIndex = 0;
    }
  }
}

/******************** Functions for /admin/image/actions *************************/
function image_toggle(check){ check.checked = !check.checked;}
function image_over(div){ div.style.cursor = 'pointer';}
function image_out(div){ div.style.cursor = '';}

function image_action(){
  select = $('apply_action');
  if (select.selectedIndex != 0){
    action = select.value;
    text = select.options[select.selectedIndex].text;
    var answer = confirm("Are you sure you wish to apply the follow action?\n\n - "+text);
    if (answer){
      new Ajax.Request('/admin/image/bulk_update/'+action, {
        asynchronous:true, 
        evalScripts:true, 
        parameters:Form.serialize($('image_form'))
      });
    }
    $('apply_action').selectedIndex = 0;
  }
}

function move_category(){
  select = $('image_category');
  if (select.selectedIndex != 0){
    action = select.value;
    text = select.options[select.selectedIndex].text;
    var answer = confirm("Are you sure you wish to move selected to\n\n  "+text);
    if (answer){
      new Ajax.Request('/admin/image/category_update/'+action, {
        asynchronous:true, 
        evalScripts:true, 
        parameters:Form.serialize($('image_form'))
      });
    }
    $('image_category').selectedIndex = 0;
  }
  
}
function set_all(value){
  $$('input').each(function(element){if (element.type == 'checkbox'){element.checked = value;}});
}
function all(){set_all(true);}
function none(){set_all(false);}

/*************** Code for inline edit on ordered garments page ******************/
function initialize_inline_edit(){
  $$('.editable_model').each(function(element){
    element.observe('click',function(){
      make_editable(element,$('models'),"210px",'model');
    });
	element.observe('change',function(){
    });
    element.observe('mouseover',function(){
      element.style.cursor='pointer';
    });
    element.observe('mouseout',function(){
      element.style.cursor='default';
    });
  });

  $$('.editable_color').each(function(element){
    element.observe('click',function(){
      make_editable(element,$('colors_'+element.id.split("_")[0]),"60px",'color');
    });
    element.observe('mouseover',function(){
      element.style.cursor='pointer';
    });
    element.observe('mouseout',function(){
      element.style.cursor='default';
    });
  });

  $$('.editable_size').each(function(element){
    element.observe('click',function(){
      make_editable(element,$('sizes'),"40px",'size');
    });
    element.observe('mouseover',function(){
      element.style.cursor='pointer';
    });
    element.observe('mouseout',function(){
      element.style.cursor='default';
    });
  });
  $$('.editable_qty').each(function(element){
    element.observe('click',function(){
      make_qty_editable(element);
    });
    element.observe('mouseover',function(){
      element.style.cursor='pointer';
    });
    element.observe('mouseout',function(){
      element.style.cursor='default';
    });
  });
  $$('.editable_address').each(function(element){
    element.observe('click',function(){
      make_text_editable(element);
    });
    element.observe('mouseover',function(){
      element.style.cursor='pointer';
    });
    element.observe('mouseout',function(){
      element.style.cursor='default';
    });
  });
}

function make_text_editable(element){
  var order = element.id.split("_")[0];
  var type  = element.id.split("_")[1];
  var attr  = element.id.split("_")[2];
  new_element = document.createElement("input");
  new_element.type = 'text';
  new_element.id = element.id;
  new_element.value = element.innerHTML;
  element.parentNode.appendChild(new_element);

  new_element.observe('blur', function(){
    make_uneditable(element,new_element);
    new Ajax.Updater(element,'/admin/order/update_address',{
      parameters: {order: order,type: type, attribute: attr, val: new_element.value},
      onComplete: function(){
        new Effect.Highlight(element, { startcolor: '#ffff99',endcolor: '#ffffff' });
      }
    });
  });

  element.parentNode.removeChild(element);      
  new_element.focus();

}
function select_to_text(element,original,garment,from){
  new_element = document.createElement("input");
  new_element.type = "text";
  new_element.id = element.id;
  element.parentNode.appendChild(new_element);
  new_element.observe('blur', function(){
    make_uneditable(original,new_element);
    new Ajax.Updater(original,'/admin/ordered_garments/update_garment',{
      parameters: {garment: garment,attribute: 'model_other', from: from, to: new_element.value},
      onComplete: function(){
        new Effect.Highlight(original, { startcolor: '#ffff99',endcolor: '#ffffff' });
      }
    });
  });
  element.parentNode.removeChild(element);      
  new_element.focus();

}

function select_to_text_other_color(element,original,garment,from){
  new_element = document.createElement("input");
  new_element.type = "text";
  new_element.id = element.id;
  element.parentNode.appendChild(new_element);
  new_element.observe('blur', function(){
    make_uneditable(original,new_element);
    new Ajax.Updater(original,'/admin/ordered_garments/update_garment',{
      parameters: {garment: garment,attribute: 'color_other', from: from, to: new_element.value},
      onComplete: function(){
        new Effect.Highlight(original, { startcolor: '#ffff99',endcolor: '#ffffff' });
      }
    });
  });
  element.parentNode.removeChild(element);      
  new_element.focus();

}

function make_qty_editable(element){
  var garment = element.id.split("_")[0];
  var from    = element.id.split("_")[1];

  new_element = document.createElement("input");
  new_element.type = 'text';
  new_element.id = element.id;
  new_element.size = 3;
  new_element.value = element.innerHTML;
  element.parentNode.appendChild(new_element);

  new_element.observe('blur', function(){
    make_uneditable(element,new_element);
    new Ajax.Updater(element,'/admin/ordered_garments/update_garment',{
      parameters: {garment: garment, attribute: 'quantity', from: from, to: new_element.value},
      onComplete: function(){
        $(garment+'_'+from).id = garment+"_"+new_element.value;
        new Effect.Highlight(element, { startcolor: '#ffff99',endcolor: '#ffffff' });
      }
    });
  });

  element.parentNode.removeChild(element);      
  new_element.focus();

}

function make_editable(element,dropDown,width,attr){
  // ID of garment and attribute being changed
  // makes up the id of the element
  var garment = element.id.split("_")[0];
  var from    = element.id.split("_")[1];

  // Clone the dropdown, make it visible and add it to the dom
  new_element = dropDown.cloneNode(true);
  new_element.style.display="block";
  new_element.id = element.id;
  new_element.style.width = width;
  element.parentNode.appendChild(new_element);
  
  for (var i=0; i<dropDown.options.length; i++){
    if (new_element.options[i].innerHTML.toString() == element.innerHTML.toString()){
      new_element.selectedIndex = i;
    }
  }


  // On blur or change send ajax request and 
  // make uneditable
  new_element.observe('change',function(){
    if (new_element.value == "other"){
      select_to_text(new_element, element, garment, from);
    }
	else
	if (new_element.value == "other_color"){
      select_to_text_other_color(new_element, element, garment, from);
    }
    else{
      make_uneditable(element,new_element);
      new Ajax.Updater(element,'/admin/ordered_garments/update_garment',{
        parameters: {garment: garment,attribute: attr, from: from, to: new_element.value},
        onComplete: function(){
          $(garment+'_'+from).id = garment+"_"+new_element.value;
          new Effect.Highlight(element, { startcolor: '#ffff99',endcolor: '#ffffff' });
        }
      });
    }
  });
  new_element.observe('blur',function(){
    if (new_element.value == "other"){
      select_to_text(new_element, element,  garment, from);
    }
	else
	if (new_element.value == "other_color"){
      select_to_text_other_color(new_element, element,  garment, from);
    }
    else{
      make_uneditable(element,new_element,from);
      new Ajax.Updater(element,'/admin/ordered_garments/update_garment',{
        parameters: {garment: garment,attribute: attr, from: from, to: new_element.value},
        onComplete: function(){
          $(garment+'_'+from).id = garment+"_"+new_element.value;
          new Effect.Highlight(element, { startcolor: '#ffff99',endcolor: '#ffffff' });
        }
      });
    }
  });

  element.parentNode.removeChild(element);      
  new_element.focus();
}

function make_uneditable(original,new_element){
	if (new_element.value == "")
	{
		new_element.value = "Other";		
	}
	
  if (new_element.options) {
  	original.innerHTML = new_element.options[new_element.selectedIndex].innerHTML;
  }
  else {
  	original.innerHTML = new_element.value;
  }
	

  new_element.parentNode.appendChild(original);
  new_element.parentNode.removeChild(new_element);
}

function reorder(garment,from,to, nb_to_reorder){
  new Ajax.Updater($('garments_ordered'),'/admin/ordered_garments/update_garment',{
    parameters: {garment: garment,attribute: 'garments_ordered', from: from, to: to, nb_to_reorder: nb_to_reorder},
    onComplete: function(){
      new Effect.Highlight($('garments_ordered'), { startcolor: '#ffff99',endcolor: '#ffffff' });
	  new Effect.Highlight($('garments_ordered_modifier_' + garment), { startcolor: '#ffff99',endcolor: '#ffffff' });
	  $('garments_ordered_modifier_' + garment).innerHTML = "";
	  
	  new Effect.Highlight($('product_in_stock_at_printer_value_' + garment), { startcolor: '#ffff99',endcolor: '#ffffff' });
	  $('product_in_stock_at_printer_value_' + garment).innerHTML = "false";

          new Effect.Highlight($('garments_ordered_qty_not_received_' + garment), { startcolor: '#ffff99',endcolor: '#ffffff' });
          $('garments_ordered_qty_not_received_' + garment).innerHTML = "";
    }
  });
}

function back_order(garment,from,to, nb_to_reorder){
  new Ajax.Updater($('garments_ordered'),'/admin/ordered_garments/update_garment',{
    parameters: {garment: garment,attribute: 'back_order', from: from, to: to, nb_to_reorder: nb_to_reorder},
    onComplete: function(){
      new Effect.Highlight($('garments_ordered'), { startcolor: '#ffff99',endcolor: '#ffffff' });
	  new Effect.Highlight($('garments_back_order_modifier_' + garment), { startcolor: '#ffff99',endcolor: '#ffffff' });
	  $('garments_back_order_modifier_' + garment).innerHTML = "";

	  new Effect.Highlight($('garments_ordered_modifier_' + garment), { startcolor: '#ffff99',endcolor: '#ffffff' });
	  $('garments_ordered_modifier_' + garment).innerHTML = "";
	  
          new Effect.Highlight($('garments_ordered_qty_not_received_' + garment), { startcolor: '#ffff99',endcolor: '#ffffff' });
          $('garments_ordered_qty_not_received_' + garment).innerHTML = "";
    }
  });
}

function toggle_preview_declined(){
  $("decline_reason").toggle(); 
  if ($("decline_reason").style.display == "none")
    $("product_preview_declined_reason").value = ""
}
