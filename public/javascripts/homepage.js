$(document).ready(function() {
	
//MENU OF BANNERS
  $("#banners_menu ul li").click(function(){
	//Hide all the banners
	$("#banners_left #banner_1").css("display", "none");
	$("#banners_left #banner_2").css("display", "none");
	$("#banners_left #banner_3").css("display", "none");
	$("#banners_left #banner_4").css("display", "none");
	$("#banner_right").css("display", "none");
	
	//Show the banner selected
	current_banner = $(this).attr("id").replace("banner_", "");

	if (current_banner != "5"){
		$("#banners_left #banner_"+current_banner).css("display", "inline");
	}else{
		$("#banner_right").css("display", "inline");
	}
  });
});

function changeLang(){
	$("#lang_ul").css("visibility", "visible");
	$("#lang_ul").css("display", "block");
	$("#lang_ul").css("background-color", "#fff");
}

function hideLang(){
	$("#lang_ul").css("visibility", "hidden");
	$("#lang_ul").css("display", "none");
	$("#lang_ul").css("background-color", "#fff");
}

function remoteTmp(){
	var file_src = $("#file_src").attr("value");

	$.ajax({ 
		url: "/admin/homepage/delete_tmp?file_remove='"+file_src+"'",
		type: "post",
		dataType: "text", 
		success: function(data){
			if(data == "ok"){
				window.location.href='/admin/homepage/banners'
			}	
	}});
}

/*function saveOrder() {
	var serialStr = "";
	$("#list1 li").each(function(i, elm) { serialStr += (i > 0 ? "|" : "") + $(elm).children().html(); });
	$("input[name=list1SortOrder]").val(serialStr);
}*/

function save_order(){
	order_1_val = $('.banners_order li')[0].className;
	order_2_val = $('.banners_order li')[1].className;
	order_3_val = $('.banners_order li')[2].className;
	order_4_val = $('.banners_order li')[3].className;

	$.ajax({ 
		url: "/admin/homepage/save_order",
		type: "post",
		data: ({order_1 : order_1_val, order_2 : order_2_val, order_3 : order_3_val, order_4 : order_4_val}),
		dataType: "text", 
		success: function(data){
			$("#order_notice").css("display", "inline");
	}});
}