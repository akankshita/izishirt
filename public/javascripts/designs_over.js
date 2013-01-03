
this.designPreview = function(){
    /* CONFIG */

    xOffset = 10;
    yOffset = 30;
    
    /* END CONFIG */
    $j("a.designpreview").hover(function(kmouse){
        injectPreview(this,kmouse);
    },
    function(){
        $j("#preview").remove();
        $j(this).removeClass("preview_over");
    });
    $j("a.preview img").mousemove(function(kmouse){
//        if($j("#preview").length == 0){
//            injectPreview(this,kmouse);
//
//        }
        if($j("#preview").length > 0){
          reposition(kmouse, false);
        }
    });
//    $j("a.preview img").mouseout(function(kmouse){
//      $j("#preview").remove();
//    });
    
}

function injectPreview(elem,kmouse){
    while($j("#preview").length > 0){
            $j("#preview").remove();
        }
        var img = new Hash();
        height = false;
        width = false;

        $j(elem).addClass("preview_over");

        img.set(elem.parentNode.href.toString(), new Image());
        img.get(elem.parentNode.href.toString()).onload=function(){
            height = img.get(this.src.toString()).height;
            width = img.get(this.src.toString()).width;
            style = "style='width:"+width+"px;height:"+height+"px'";
            $j("body").append("<p id='preview' "+ style +"><img src='"+ img.get(this.src.toString()).src + "' alt='Image preview' height="+height+ " width="+ width+ "/>"+"</p>");
            if(!$j(elem).hasClass("preview_over")){
              $j("#preview").remove();
              return;
            }
            reposition(kmouse, "fadeIn");
        }
        img.get(elem.parentNode.href.toString()).src = elem.parentNode.href;
}

function reposition(kmouse, fadeIn){
    var border_top = $j(window).scrollTop();
    var border_right = $j(window).width();
    var left_pos;
    var top_pos;
    var offset = 15;
    if(border_right - (offset *2) >= $j("#preview").width() + kmouse.pageX){
        left_pos = kmouse.pageX+offset;
    } else{
        left_pos = kmouse.pageX-$j("#preview").width()-offset;
    }

    if(border_top + (offset *2)>= kmouse.pageY - $j("#preview").height()){
        top_pos = border_top +offset;
    } else{
        top_pos = kmouse.pageY-$j("#preview").height()-offset;
    }
    $j("#preview").css({
        left:left_pos, 
        top:top_pos
    });
    if(fadeIn == "fadeIn"){
        $j("#preview").fadeIn("fast");
    }
}

// starting the script on page load
$j(document).ready(function(){
    designPreview();
});