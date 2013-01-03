$j(document).ready(function() { 
    add_menu_events();
    hideLoadingComponent();
}); 

function add_menu_events(){
  // ****************************************************************************************
  // Menu Bank Browse button click
  // ****************************************************************************************
  $j("a#button_bank_link").click(function() {
    if ( $j(this).html() == browse_lbl ){
      hide_menu_design_options();
      show_menu_bank();
    }
    else{
      hide_menu_bank();
    }
  });

  // ****************************************************************************************
  // Menu Design Button Click
  // ****************************************************************************************
  $j("a#button_design_link").click(function(){
    hide_menu_bank();
    if ( $j(this).html() == design_lbl )
      show_design_options();
    else 
      hide_menu_design_options();

    return false; 
  });

  // ****************************************************************************************
  // Button Bank Image Click
  // ****************************************************************************************
  $j("a.button_bank_link").click(function() {
    $j("#shop_section_shop_bank_menu_id").val($j(this).attr('rel'));
    $j.each( $j(this).parent().children(), function(){
      $j("#preview_"+$j(this).attr("name")).css("background-image", "url('"+$j("img:first",this).attr("src").replace("small", "normal")+"')");
      $j("#preview_"+$j(this).attr("name")).css("border", "none");
      $j("#preview_"+$j(this).attr("name")).children().css("display","none");
    });

    return false;
  });
}

function hide_menu_design_options(){
  $j("a#button_design_link").html(design_lbl);
  hide_background_color();
  hide_font_options();
  hide_border();
  $j("#background").slideUp();
  $j("#border").slideUp();
  $j("#text").slideUp();
  $j("#bank").removeClass("disabled");
}

function show_design_options(){
  $j("a#button_design_link").html(cancel_lbl);
  $j("#background").slideDown();
  $j("#border").slideDown();
  $j("#text").slideDown();
  $j("#bank").addClass("disabled");
  hide_menu_bank();
}

function hide_menu_bank(){
  $j("#shop_section_shop_bank_menu_id").val("");
  $j("#button_bank").slideUp("slow");
  $j("a#button_bank_link").html(browse_lbl);
  $j("#design").removeClass("disabled");
  $j("#preview_menu").children().css("background-image","none");
  $j("#preview_menu").children().children().css({'display' : 'block'});
}

function show_menu_bank(){
  $j("#button_bank").slideDown("slow");
  $j("a#button_bank_link").html(cancel_lbl);
  $j("#design").addClass("disabled");
}
