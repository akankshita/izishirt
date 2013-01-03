$j(document).ready(function(){
    $j("#blog").jScrollPane({
        scrollbarWidth: 20,
        showArrows: true
    });
    designInterval = setInterval(designRotate,5000);
})

currentDesign = 0;      
dir = 'forward';

function designRotate() {
    if (dir == 'forward')
        currentDesign ++;
    else
        currentDesign --;
    if (currentDesign >= 20)
        dir = 'backward';
    if (currentDesign <= 0)
        dir = 'forward';
    $j("#topDesignScroller").animate({
        left: -135*currentDesign
        },"slow");
}

// thx to http://www.webdeveloper.com/forum/showthread.php?t=161317
    function fireEvent(obj,evt){

	var fireOnThis = obj;
	if( document.createEvent ) {
	  var evObj = document.createEvent('MouseEvents');
	  evObj.initEvent( evt, true, false );
	  fireOnThis.dispatchEvent(evObj);
	} else if( document.createEventObject ) {
	  fireOnThis.fireEvent('on'+evt);
	}
}

function validate_email(value)
{
    apos=value.indexOf("@");
    dotpos=value.lastIndexOf(".");
    if (apos<1||dotpos-apos<2)
    {
        return false;
    }
    else {
        return true;
    }

}

//Rotate the apparel banners
var first_img  = "apparel1";
var second_img = "apparel2";
var third_img  = "apparel3";
var fourth_img = "apparel4";
var tmp;

function rotate_apparel_banner(){
  $(fourth_img).style.zIndex =96;
  $(third_img).style.zIndex  =97;
  $(second_img).style.zIndex =98; 
  $(first_img).style.zIndex  =99;

  $(second_img).style.display='block'; 

  new Effect.Fade(first_img, {duration:5.0, from:1.0, to:0.0});
  tmp = first_img;
  first_img = second_img;
  second_img = third_img;
  third_img = fourth_img;
  fourth_img = tmp;
}
//
//Rotate the apparel banners
var left_img_one = "left1";
var left_img_two = "left2";

function rotate_left_banner(){
  $(left_img_two).style.zIndex =98; 
  $(left_img_one).style.zIndex =99;

  $(left_img_two).style.display='block'; 

  new Effect.Fade(left_img_one, {duration:3.0, from:1.0, to:0.0});
  tmp = left_img_one;
  left_img_one = left_img_two;
  left_img_two = tmp;
}


function change_color(section,model,color){
  //document.body.style.cursor = 'pointer';
  $(section+"_"+model).src = "/izishirtfiles/models/"+model+"/"+color+"-front.jpg";
}

function fade_to(id,img,styles){
  $j("#model_layer_1").attr('src',img);
  $j('#model_layer_2').animate({opacity:0},
    1000,
    "linear", 
    function () {
      $j("#model_layer_2").attr("src",img);
      $j("#model_layer_2").animate({opacity:1},1);
  });
}

function change_apparel_color(model_id, color_id) {
  //Put the id in the hidden form field
  $("color_id").value = (color_id);
  $("current_color").src = $(model_id+"_"+color_id).src;
  $("current_color_name").innerHTML = $(model_id+"_"+color_id).alt;
 
  //Change Large Model Image
  fade_to('model_layer',"/izishirtfiles/models/"+model_id+"/"+color_id+"-front.jpg", "apparelFader");
}
