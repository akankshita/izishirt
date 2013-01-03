var preview_scale = 0.85;

$j(document).ready(function() { 
    add_banner_events();
}); 

// ****************************************************************************************
// Add events used to display and update banner and banner screens
// ****************************************************************************************
function add_banner_events() {

  $j(document).ready(function(){
    if ($j("#image_upload").length > 0) {
      new AjaxUpload('image_upload', {
        action: '/myizishirt/customize_boutique/upload_image/'+$j('#shop_section_id').val(),
        name: 'image_upload',
        autoSubmit: true,
        onSubmit: function(file, extension) {
          $j("#spinner_image_upload").show();
          $j("#edit_banner_done_button").hide();
          $j("#edit_banner_image_uploaded_msg").hide();
          hide_design_options();
          hide_banner_bank();
        },
        onComplete: function(file, response) {
          $j("#spinner_image_upload").hide();
          $j("#edit_banner_done_button").show();
          $j("#edit_banner_image_uploaded_msg").show();
          clear_preview();
          $j("#preview").css("background-image", "url('"+response+"')");
          $j("#shop_section_shop_bank_banner_id").val("");
        }
      });
    }
  });

  // ****************************************************************************************
  // Banner Bank Browse button click
  // ****************************************************************************************
  $j("a#banner_bank_link").click(function() {
    if ( $j(this).html() == browse_lbl ){
      hide_design_options();
      show_banner_bank();
    }
    else{
      hide_banner_bank();
    }

    //Return false, don't want the link redirecting to anywhere
    return false;
  });

  // ****************************************************************************************
  // Banner Bank Image Click
  // ****************************************************************************************
  $j("a.banner_bank_link img").click(function() {
    $j("#preview").css("background-image", "url('"+$j(this).attr("src").replace("thumb", "preview")+"')");
    $j("#shop_section_shop_bank_banner_id").val($j(this).attr('alt'));

    return false;
  });

  // ****************************************************************************************
  // Banner Design Button Click
  // ****************************************************************************************
  $j("a#banner_design_link").click(function(){
    hide_banner_bank();
    if ( $j(this).html() == design_lbl )
      show_design_options();
    else 
      hide_design_options();

    return false; 
  });

}


// ****************************************************************************************
// Show the design your banner options
// ****************************************************************************************
function show_design_options(){
  $j("#save_background").val("true");
  $j("a#banner_design_link").html(cancel_lbl);
  $j("#background").slideDown("slow");
  $j("#border").slideDown("slow");
  $j("#height").slideDown("slow");
  $j("#bank").addClass("disabled");
  $j("#upload").addClass("disabled");
}

// ****************************************************************************************
// Hide the design your banner options
// ****************************************************************************************
function hide_design_options(){
  if ($j("a#banner_design_link").html() == cancel_lbl) clear_preview();
  $j("#save_background").val("false");
  $j("a#banner_design_link").html(design_lbl);
  $j("a#background_color_link").html(colors_lbl);
  $j("#background").slideUp("slow");
  $j("#border").slideUp("slow");
  $j("#height").slideUp("slow");
  $j("#bank").removeClass("disabled");
  $j("#upload").removeClass("disabled");
  $j("#bg_color").slideUp("slow");
  $j("#edit_border").slideUp("slow");
  hide_font_options();
}


// ****************************************************************************************
// Show the banner bank and related options
// ****************************************************************************************
function show_banner_bank() {
  $j("a#banner_bank_link").html(cancel_lbl);
  $j("#upload").addClass("disabled");
  $j("#design").addClass("disabled");
  $j("#banner_bank").slideDown("slow");
  hide_font_options();
}


// ****************************************************************************************
// Hide the banner bank and related options
// ****************************************************************************************
function hide_banner_bank() {
  if ($j("a#banner_bank_link").html() == cancel_lbl) clear_preview();
  $j("a#banner_bank_link").html(browse_lbl);
  $j("#upload").removeClass("disabled");
  $j("#design").removeClass("disabled");
  $j("#banner_bank").slideUp("slow");
  hide_font_options();
}

function clear_preview() {
  $j("#preview").css("background-image", "none");
  $j("#preview").css("background-color", "#ffffff");
  $j("#preview").css("border", "none");
}
