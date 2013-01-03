$j(document).ready(function() { 
    add_border_events();
    hideLoadingComponent();
}); 

// ****************************************************************************************
// Add events used to display and update the border screens
// ****************************************************************************************
function add_border_events() {
  // ****************************************************************************************
  // Custom Border Change
  // ****************************************************************************************
  $j("input[name=save_border]").click(function(){
    if ($j("input[name=save_border]:checked").val() == "true")
      show_border();
    else
      hide_border();
  });

  // ****************************************************************************************
  // Custom Border Edit
  // ****************************************************************************************
  $j("a#border_link").click(function(){
    if ($j("a#border_link").html() == border_lbl)
      show_border();
    else
      hide_border();

  });

  // ****************************************************************************************
  // Banner Custom Border Section(color, style)
  // ****************************************************************************************
  $j("a#border_section_link").click(function(){
    show_border_section($j(this).html());
    return false;
  });
  
  // ****************************************************************************************
  // Banner Custom Border Preview
  // ****************************************************************************************
  $j("a#border_preview_link").click(function(){
    update_border_preview();  
    return false;
  });

  // ****************************************************************************************
  // Banner Custom Border OK
  // ****************************************************************************************
  $j("a#border_ok_link").click(function(){
    update_border_preview();  
    hide_border();
    return false;
  });
}

function replaceCssBorder(div_id, style, color){
	$j(div_id).css("border","0 0 1px 0");
	$j(div_id).css("border-style",style);
	$j(div_id).css("border-color",color);
}

function update_border_preview(){
	var weight=$j("#shop_border_weight").val()+"px";
    var style=$j("input[name=shop_border\\[style\\]]:checked").val();
	var color=$j("#shop_border_color").val();

	if($j(".preview #preview").is(".tshirt_info") == true && $j(".preview #preview label").size() == 2){
		replaceCssBorder("#preview", style, color);
		replaceCssBorder(".previews", style, color);
		replaceCssBorder(".border_preview", style, color);
	}else{
		$j("#preview").css("border",weight+" "+style+" "+color);
	    $j(".previews").css("border",weight+" "+style+" "+color);
	    $j(".border_preview").css("border",weight+" "+style+" "+color);
	}
}

// ****************************************************************************************
// Show border section and hide the other(colors and styles)
// ****************************************************************************************
function show_border_section(section){
  if (section == colors_lbl){
    $j("a#border_section_link").html(styles_lbl);
    $j("#border_color_holder").slideDown("slow");
    $j("#border_styles").slideUp("slow");
  }
  else{
    $j("a#border_section_link").html(colors_lbl);
    $j("#border_styles").slideDown("slow");
    $j("#border_color_holder").slideUp("slow");
  }
}


// ****************************************************************************************
// Show the edit border screen
// ****************************************************************************************
function show_border() {
  $j("#edit_border").slideDown("slow");
  $j("a#border_link").html(cancel_lbl);
  hide_line();
  hide_font_options();
  hide_background_color();
}

// ****************************************************************************************
// Hide the edit border screen
// ****************************************************************************************
function hide_border() {
  $j("#edit_border").slideUp("slow");
  $j("a#border_link").html(border_lbl);
}

