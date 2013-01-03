$j(function() {
  $j("#sortable").sortable({
    connectWith: '.connectedSortable',
    receive: receive,
    update: update
  }).disableSelection();

  if ($j("#all_sortable")){
    $j("#all_sortable").sortable({
      connectWith: '.connectedSortable',
      receive: receive,
      stop: stop
    }).disableSelection();
  }

  $j("#scroll_left").mouseover(function(){startScroll('left');})
  $j("#scroll_right").mouseover(function(){startScroll('right');})
  $j("#scroll_left").mouseout(function(){stopScroll();})
  $j("#scroll_right").mouseout(function(){stopScroll();})
});

//Called from other product list and prevents user
//from reordering in that list
function stop(event, ui){
  if (ui.sender == null && 
      ui.item.parent().attr('id') == "all_sortable" )
    $j(this).sortable('cancel');
}

//Called when either list receives an element
function receive(event, ui){
  product=ui.item.attr('id');
  if (ui.sender.attr('id') == "all_sortable") {
    $j('#sortable > *:last').prependTo("#all_sortable");
    sort_order = $j("#sortable").children().index(ui.item)+1;
    sort_order+= items_per_page * (current_page-1);
  }
  else{
    $j('#all_sortable > *:first').appendTo("#sortable");
    sort_order = items_per_page + $j("#all_sortable").children().index(ui.item)+1;
    sort_order+= items_per_page * (current_page-1);
  }
  update_sort_order(product, sort_order);
} 
//Called from first list when updated
function update(event, ui){
  if (event.target.id != "all_sortable" &&
      ui.sender == null && 
      ui.item.parent().attr('id') == "sortable"){
    product=ui.item.attr('id');
    sort_order = $j("#sortable").children().index(ui.item) + 1;
    sort_order+= items_per_page * (current_page - 1);
    update_sort_order(product, sort_order);
  }
} 
//Creates ajax request which updates order
function update_sort_order(product, sort_order){
  url="/myizishirt/products/update_sort/";
  $j.ajax({ url: url + product + "?sort_order="+sort_order,
      success: function(){ $("products").highlight();}
  });
}
var timer;
function startScroll(val){
  if ( val == "left" ){
    $j("#scroll_left_img").attr("src","/images/izishirt2011/left_scroller_light.png");
    timer = setInterval(scrollLeft,2 );
  }
  else{
    $j("#scroll_right_img").attr("src","/images/izishirt2011/right_scroller_light.png");
    timer = setInterval(scrollRight,2 );
  }
}
function stopScroll(){
  $j("#scroll_left_img").attr("src","/images/izishirt2011/left_scroller.png");
  $j("#scroll_right_img").attr("src","/images/izishirt2011/right_scroller.png");
  clearInterval(timer);
}
function scrollLeft(){
  $j("#other_products").scrollLeft($j("#other_products").scrollLeft()-2);
}
function scrollRight(){
  $j("#other_products").scrollLeft($j("#other_products").scrollLeft()+2);
}
