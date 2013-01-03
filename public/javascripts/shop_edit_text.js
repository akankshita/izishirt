var preview_scale = 0.85;

$j(document).ready(function() { 
    add_text_events();
    hideLoadingComponent();
}); 

// ****************************************************************************************
// Add events used to display and update text options and previews
// ****************************************************************************************
function add_text_events() {

  // ****************************************************************************************
  // Text Edit Font click
  // ****************************************************************************************
  $j("a[name=font_link]").click(function() {

    for (i=1;i<5;i++) {
      if ($j(this).attr("rel") == i) 
        $j("#font_"+i).slideDown("slow");
      else
        $j("#font_"+i).slideUp("slow");
    }
    $j("#banner_bank").slideUp("slow");
    $j("#bg_color").slideUp("slow");
    $j("a#background_color_link").html(colors_lbl);
    $j("#edit_border").slideUp("slow");
    hide_line();
    //Return false, don't want the link redirecting to anywhere
    return false;
  });

  for (i=1;i<5;i++) {
    $j("#shop_texts_"+i+"_text").focus(function() { 
      if ( $j(this).val() == type_text_lbl ){
        $j(this).val("");
      }
    });
  }
  // ****************************************************************************************
  // Text Preview Click
  // ****************************************************************************************
  $j("a[name=preview_text_link]").click(function(){
    update_text_preview($j(this));
    return false;
  });

  // ****************************************************************************************
  // Text Ok Click
  // ****************************************************************************************
  $j("a[name=close_text_link]").click(function(){
    update_text_preview($j(this));
    hide_font_options();
    
    return false;
  });

  // ****************************************************************************************
  // Text Bold Click
  // ****************************************************************************************
  $j("img[name=bold]").click(function() {
      var index = $j(this).attr('index');
      if ($j(this).attr('src').indexOf('bold_up') != -1)
        $j(this).attr("src", "/images/create_boutique/bold_down.png");
      else
        $j(this).attr("src", "/images/create_boutique/bold_up.png");
      if ( $j("#shop_texts_"+index+"_bold").attr("checked") )
        $j("#shop_texts_"+index+"_bold").attr("checked",false);
      else
        $j("#shop_texts_"+index+"_bold").attr("checked",true);
  });

  // ****************************************************************************************
  // Text Italic Click
  // ****************************************************************************************
  $j("img[name=italic]").click(function() {
      var index = $j(this).attr('index');
      if ($j(this).attr("src").indexOf('italic_up') != -1)
        $j(this).attr("src","/images/create_boutique/italic_down.png");
      else
        $j(this).attr("src","/images/create_boutique/italic_up.png");
      if ( $j("#shop_texts_"+index+"_italic").attr("checked") )
        $j("#shop_texts_"+index+"_italic").attr("checked",false);
      else
        $j("#shop_texts_"+index+"_italic").attr("checked",true);
  });

  // ****************************************************************************************
  // Text Underlined Click
  // ****************************************************************************************
  $j("img[name=underlined]").click(function() {
      var index = $j(this).attr('index');
      if ($j(this).attr("src").indexOf('underlined_up') != -1)
        $j(this).attr("src", "/images/create_boutique/underlined_down.png");
      else
        $j(this).attr("src", "/images/create_boutique/underlined_up.png");
      if ( $j("#shop_texts_"+index+"_underlined").attr("checked") )
        $j("#shop_texts_"+index+"_underlined").attr("checked",false);
      else
        $j("#shop_texts_"+index+"_underlined").attr("checked",true);
  });

}

function update_text_preview(element){
  var index = element.attr("rel");
  var text  = $j("#shop_texts_"+index+"_text").val();
  var font  = $j("#shop_texts_"+index+"_font").val();
  var size  = $j("#shop_texts_"+index+"_size").val();
  var color = $j("#shop_texts_"+index+"_color").val();
  var xpos  = $j("#shop_texts_"+index+"_xpos").val();
  var ypos  = $j("#shop_texts_"+index+"_ypos").val();
  var bold = $j("#shop_texts_"+index+"_bold").attr("checked");
  var italic = $j("#shop_texts_"+index+"_italic").attr("checked");
  var underlined = $j("#shop_texts_"+index+"_underlined").attr("checked");

  if ($j("#shop_texts_"+index+"_text_type").length == 0)
    $j("#line_"+index+", .line_"+index).html(text);
  $j("#line_"+index+", .line_"+index).css("font-family",font);
  $j("#line_"+index+", .line_"+index).css("font-size",size+"px");
  $j("#line_"+index+", .line_"+index).css("color",color);
  $j("#line_"+index+", .line_"+index).css("left",xpos*preview_scale+"px");
  $j("#line_"+index+", .line_"+index).css("top",ypos*preview_scale+"px");


  if (bold) 
    $j("#line_"+index+", .line_"+index).css("font-weight","bold");
  else
    $j("#line_"+index+", .line_"+index).css("font-weight","normal");

  if (italic) 
    $j("#line_"+index+", .line_"+index).css("font-style","italic");
  else
    $j("#line_"+index+", .line_"+index).css("font-style","normal");

  if (underlined) 
    $j("#line_"+index+", .line_"+index).css("text-decoration","underline");
  else
    $j("#line_"+index+", .line_"+index).css("text-decoration","none");

  $j("#save_text_"+index).val(true);
}



function hide_font_options(){
  //Hide Text
  $j("#font_1").slideUp("slow");
  $j("#font_2").slideUp("slow");
  $j("#font_3").slideUp("slow");
  $j("#font_4").slideUp("slow");
}
