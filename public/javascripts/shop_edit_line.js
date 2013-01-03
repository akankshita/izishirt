$j(document).ready(function() { 
    add_line_events();
    hideLoadingComponent();
}); 

function add_line_events(){
  // ****************************************************************************************
  // Custom Lines Change
  // ****************************************************************************************
  $j("input[name=save_line]").click(function(){
    if ($j("input[name=save_line]:checked").val() == "true")
      show_line();
    else
      hide_line();
  });

  // ****************************************************************************************
  // Custom Line Edit
  // ****************************************************************************************
  $j("a#line_link").click(function(){
    if ($j("a#line_link").html() == lines_lbl)
      show_line();
    else
      hide_line();

  });


  // ****************************************************************************************
  // Custom Line Section(color, style)
  // ****************************************************************************************
  $j("a#line_section_link").click(function(){
    show_line_section($j(this).html());
    return false;
  });
  
  // ****************************************************************************************
  // Custom Line Preview
  // ****************************************************************************************
  $j("a#line_preview_link").click(function(){
    update_line_preview();  
    return false;
  });

  $j("a#line_ok_link").click(function(){
    update_line_preview();  
    hide_line();
    return false;
  });
}

function update_line_preview(){
  var weight=$j("#shop_line_weight").val()+"px";
  var style=$j("input[name=shop_line\\[style\\]]:checked").val();
  var color=$j("#shop_line_color").val();
  $j("#custom_lines").css("border-top", weight+" "+style+" "+color);
  $j("#custom_lines").css("border-bottom", weight+" "+style+" "+color);
}

// ****************************************************************************************
// Show line section and hide the other(colors and styles)
// ****************************************************************************************
function show_line_section(section){
  if (section == colors_lbl){
    $j("a#line_section_link").html(styles_lbl);
    $j("#line_color_holder").slideDown("slow");
    $j("#line_styles").slideUp("slow");
  }
  else{
    $j("a#line_section_link").html(colors_lbl);
    $j("#line_styles").slideDown("slow");
    $j("#line_color_holder").slideUp("slow");
  }
}


// ****************************************************************************************
// Show the edit line screen
// ****************************************************************************************
function show_line() {
  $j("#edit_line").slideDown("slow");
  $j("a#line_link").html(cancel_lbl);
  hide_border();
  hide_font_options();
  hide_background_color();
}

// ****************************************************************************************
// Hide the edit line screen
// ****************************************************************************************
function hide_line() {
  $j("#edit_line").slideUp("slow");
  $j("a#line_link").html(lines_lbl);
}

