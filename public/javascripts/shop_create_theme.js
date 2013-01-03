

$j=jQuery.noConflict();
$j.blockUI.defaults.css.border = '2px solid #0099cc'; 

//Not so obvious hack
//Text needed by javascript i.e. label that says edit section 
//Is added to the page in hidden variables and set in the dom ready
//function below
var cancel_lbl;
var colors_lbl;
var browse_lbl;
var design_lbl;
var styles_lbl;
var border_lbl;
var lines_lbl; 
var type_text_lbl; 
var edit_section_lbl;

$j(document).ready(function() { 
  add_editable_mouse_events();
  add_link_events();

  cancel_lbl = $j("#cancel_label").val();
  colors_lbl = $j("#colors_label").val();
  browse_lbl = $j("#browse_label").val();
  design_lbl = $j("#design_label").val();
  styles_lbl = $j("#styles_label").val();
  border_lbl = $j("#edit_border_label").val();
  lines_lbl = $j("#edit_lines_label").val();
  type_text_lbl = $j("#type_text_label").val();
  edit_section_lbl = $j("#edit_section_label").val();
}); 


function resize_banner(){
  $j('#banner_div').height($j('#hidden_image').height());
}

function add_link_events(){
  //Save & exit Button
//  $j("a[name=save_and_exit]").click(function() {
//    $j.ajax({
//      url: "/myizishirt/customize_boutique/edit_name/"+$j("#shop_theme_id").val(),
//      cache: false,
//      success: function(html){
//        $j(".edit_block_small").remove();
//        $j(".content_wrapper").append(html);
//        $j.blockUI({ message: $j(".edit_block_small"), css: {width: '400px'}, centerX: true, centerY: true, allowBodyStretch: false });
//        center_block();
//        add_close_events();
//      }
//    });
//  });
  $j("a[name=save]").click(function() {
      showLoadingComponent();
    $j.ajax({
      url: "/myizishirt/customize_boutique/edit_name/"+$j("#shop_theme_id").val(),
      cache: false,
      success: function(html){
          hideLoadingComponent();
        $j(".edit_block_small").remove();
        $j(".content_wrapper").append(html);
        $j.blockUI({ message: $j(".edit_block_small"), css: {width: '400px'}, centerX: true, centerY: true, allowBodyStretch: false }); 
        center_block();
        add_close_events();
      }
    });
  }); 
  //Reset Button
  $j("a[name=reset]").click(function() {
    showLoadingComponent();
    $j.ajax({
      url: "/myizishirt/customize_boutique/reset_theme/"+$j("#shop_theme_id").val(),
      cache: false,
      success: function(html){
          hideLoadingComponent();
        $j(".edit_block_small").remove();
        $j(".content_wrapper").append(html);
        $j.blockUI({ message: $j(".edit_block_small"), css: {width: '400px'}, centerX: true, centerY: true, allowBodyStretch: false }); 
        center_block();
        add_close_events();
      }
    });
  }); 
  //Delete button
//  $j("a[name=delete]").click(function() {
//    $j.ajax({
//      url: "/myizishirt/customize_boutique/delete_theme/"+$j("#shop_theme_id").val(),
//      cache: false,
//      success: function(html){
//        $j(".edit_block_small").remove();
//        $j(".content_wrapper").append(html);
//        $j.blockUI({ message: $j(".edit_block_small"), css: {width: '400px'}, centerX: true, centerY: true, allowBodyStretch: false });
//        center_block();
//        add_close_events();
//      }
//    });
//  });
}

function add_editable_mouse_events(){
  $j('.editable').css("cursor","pointer");
  $j('.editable').mouseenter(function() {
      add_editable_text_and_click(this);
  });
  $j('.editable').mouseleave(function() {
    $j(this).unbind('click');
    $j(".edit_content").remove();
    found=false;
    jQuery.each($j(this).parents(), function() {
      if (!found && $j(this).hasClass("editable")){
        found=true;
        add_editable_text_and_click(this);
      }
    });
  });
  
}

function add_editable_text_and_click(element){
    $j(".edit_content").remove();
    $j(".editable").unbind('click');
    $j(element).append("<label class='edit_content'>"+edit_section_lbl+"</label>"); 
    $j(".edit_content").css("cursor","pointer");
    $j(element).click(function() { 
      $j.ajax({
        url: "/myizishirt/customize_boutique/edit_"+$j(element).attr('name')+"/"+$j("#shop_theme_id").val(),
        cache: false,
        success: function(html){
          $j(".edit_block").remove();
          $j(".content_wrapper").append(html);
          $j('#color_picker_holder').ColorPicker({flat: true});
          $j.blockUI({ message: $j(".edit_block"), css: {width: '770px', position: 'absolute'}, centerX: true, centerY: true, allowBodyStretch: false }); 
          center_block();
          add_close_events();
        }
      });
    }); 

}

// ****************************************************************************************
// Close button in the top left corner click
// ****************************************************************************************
function add_close_events() {
  $j('#close').click(function(){
    $j.unblockUI();
    return false;
  });
}

function center_block(){
  var width = $j(window).width();
  var height = $j(window).height();
  width = width/2-$j('.blockPage').width()/2
  height = height/2-$j('.blockPage').height()/2
 
  $j('.blockPage').css('left',width);
  $j('.blockPage').css('top',height);
}
