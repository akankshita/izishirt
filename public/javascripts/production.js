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
function update_tracking(url){
  url+="/production/order/update_tracking";
  $('orders_form').action = url;
  $('orders_form').submit();
}

function reorder(garment,from,to){
  new Ajax.Updater($('garments_ordered'),'/production/ordered_garments/update_garment',{
    parameters: {garment: garment,attribute: 'garments_ordered', from: from, to: to},
    onComplete: function(){
      new Effect.Highlight($('garments_ordered'), { startcolor: '#ffff99',endcolor: '#ffffff' });
    }
  });
}

function in_stock(garment,from,to){
  new Ajax.Updater($('garments_in_stock_'+garment),'/production/ordered_garments/update_garment',{
    parameters: {garment: garment,attribute: 'garment_in_stock_at_printer', from: from, to: to},
    onComplete: function(){
      new Effect.Highlight($('garments_in_stock_'+garment), { startcolor: '#ffff99',endcolor: '#ffffff' });
    }
  });
}

