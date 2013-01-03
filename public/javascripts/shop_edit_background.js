$j(document).ready(function() { 
    add_background_events();
    hideLoadingComponent();
}); 

// ****************************************************************************************
// Add events used to display and update the main bg screens
// ****************************************************************************************
function add_background_events() {

  // ****************************************************************************************
  // Background Upload Link
  // ****************************************************************************************
  if ($j("#background_upload").length > 0) {
    new AjaxUpload('background_upload', {
      action: '/myizishirt/customize_boutique/upload_background/'+$j('#shop_section_id').val(),
      name: 'background_upload',
      autoSubmit: true,
      onSubmit: function(file, extension) {
          $j("#spinner_background_upload").show();
          $j("#edit_banner_done_button").hide();
          $j("#edit_banner_image_uploaded_msg").hide();
        hide_background_color();
      },
      onComplete: function(file, response) {
          $j("#spinner_background_upload").hide();
          $j("#edit_banner_done_button").show();
          $j("#edit_banner_image_uploaded_msg").show();
        $j("#preview").css("background-image", "url('"+response.replace('banner_preview','original')+"')");
        $j(".previews").css("background-image", "url('"+response.replace('banner_preview','original')+"')");
        $j("#save_background_color").val("false");
      }
    });
  }


  
  // ****************************************************************************************
  // Background Color Link
  // ****************************************************************************************
  $j("a#background_color_link, a#cart_color_link, a#checkout_color_link").click(function(){
    if ( $j(this).html() == colors_lbl || $j(this).attr("rel") != "bg_color")
      show_background_color($j(this).attr("rel"));
    else 
      hide_background_color();

    return false;
  });

  // ****************************************************************************************
  // Background Color Preview Click
  // ****************************************************************************************
  $j("a#preview_background_color_link").click(function(){
    update_preview();  
    return false;
  });

  // ****************************************************************************************
  // Background Cart Color Preview Click
  // ****************************************************************************************
  $j("a#preview_cart_color_link").click(function(){ 
    update_cart_button_preview();
  });

  // ****************************************************************************************
  // Background Menu Color Preview Click
  // ****************************************************************************************
  $j("a#preview_menu_color_link").click(function(){ 
    update_menu_preview();
  });

  // ****************************************************************************************
  // Background Checkout Color Preview Click
  // ****************************************************************************************
  $j("a#preview_checkout_color_link").click(function(){ 
      update_checkout_button_preview();
  });
  
  // ****************************************************************************************
  // Background Color Ok Click
  // ****************************************************************************************
  $j("a#close_background_color_link").click(function(){
    update_preview();  
    hide_background_color()
    return false;
  });

  // ****************************************************************************************
  // Background Cart Ok Click
  // ****************************************************************************************
  $j("a#close_cart_color_link").click(function(){
    update_cart_button_preview();
    hide_background_color()
    return false;
  });
  
  // ****************************************************************************************
  // Background Checkout Ok Click
  // ****************************************************************************************
  $j("a#close_checkout_color_link").click(function(){
    update_checkout_button_preview();
    hide_background_color()
    return false;
  });

  // ****************************************************************************************
  // Background Menu Color Preview Click
  // ****************************************************************************************
  $j("a#close_menu_color_link").click(function(){ 
    update_menu_preview();
  });
}

function update_preview(){
  $j("#preview").css("background-color", $j("#shop_background_color").val());
  $j(".previews").css("background-color", $j("#shop_background_color").val());
  $j("#preview").css("background-image", "none");
  $j("#save_background_color").val("true");
}

function update_cart_button_preview(){
  $j("#cart_button").css("background-color", $j("#shop_button_1_background_color").val());
}

function update_checkout_button_preview(){
  $j("#checkout_button").css("background-color", $j("#shop_button_2_background_color").val());
}
 
function update_menu_preview(){
  $j(".nav_button").css("background-color", $j("#shop_background_color").val());
  $j("#save_background_color").val("true");
}

function show_background_color(div_to_show){
  hide_background_color();
  if (div_to_show == "bg_color"){
    $j("a#background_color_link").html(cancel_lbl);
  }
  $j("#"+div_to_show).slideDown("slow");
  hide_border();
  hide_line();
  hide_font_options();
}
function hide_background_color(){
  $j("a#background_color_link").html(colors_lbl);
  $j("#bg_color").slideUp("slow");
  $j("#cart_color").slideUp("slow");
  $j("#checkout_color").slideUp("slow");
}
