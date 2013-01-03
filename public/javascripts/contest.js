window.onload = (function(){
	$j("#popup_vote .p_img .p_before").click(function(){
		$j("#popup_vote .p_description .p_nb_votes #p_nb_votes_txt").css("background-color", "#fff");
		image_order = $j("#design_order").attr("value");
		next_order = parseInt(image_order) - 1;
		if (next_order < 0){
			next_order = $j("#contest_list .c_box ").size() - 1;
		}
		changeInfoPopup(next_order);
	});
	$j("#popup_vote .p_img .p_after").click(function(){
		$j("#popup_vote .p_description .p_nb_votes #p_nb_votes_txt").css("background-color", "#fff");
		image_order = $j("#design_order").attr("value");
		next_order = parseInt(image_order) + 1;
		if(next_order == $j("#contest_list .c_box ").size()){
			next_order = 0;
		}	
		changeInfoPopup(next_order);
	});
	
	$j("#popup_vote .p_vote a").click(function(){
		$j.ajax({ 
			url: $(this),
			context: document.body,
			success: function(data){
				if (data != "error"){
					//change the number of vote of the div#index
					image = $j("#design_order").attr("value");
					$j("#popup_vote .p_description .p_nb_votes #p_nb_votes_txt").html(data+" Votes");
					$j("#design_"+image+" #hidden_votes").attr("value", data);
					$j("#design_"+image+" .c_nb_vote").attr("value", data);
					//display the thanks message
					$j("#popup_vote .p_notice_msg").css("display", "inline");
					$j("#popup_vote .p_description .p_nb_votes #p_nb_votes_txt").css("background-color", "rgb(204,255,204)");
				}else{
					//display the error message if the user have already vote
					$j("#popup_vote .p_error_msg").css("display", "inline");
				}
		}});
		return false;
	});
});

function showPopupVote(image){
	/*Haut de la page*/
	window.location.href='#';
	
	createOpacity();

	changeInfoPopup(image);
	
	$j("#popup_vote .p_img .p_before").css("display", "inline");
	$j("#popup_vote .p_img .p_after").css("display", "inline");
	$j("#popup_opacity").css("visibility", "visible");
	$j("#popup_vote").css("visibility", "visible");
}

function changeInfoPopup(image){
	/*fill the informations with the current design*/
	load_begin = " .c_description";
	/*Title*/
	load_title = $j("#design_"+image+load_begin+" .c_title").html();
	$j("#popup_vote .p_title").html(load_title);
	/*Created by*/
	load_created = $j("#design_"+image+load_begin+" .c_created").html();
	$j("#popup_vote .p_description .p_created").html(load_created);
	/*Number of votes*/
	load_nb_votes = $j("#design_"+image+" input:hidden[name=votes]").val();
	$j("#popup_vote .p_description .p_nb_votes #p_nb_votes_txt").html(load_nb_votes+" Votes");
	/*Link to Votes*/
	load_design_id = $j("#design_"+image+" input:hidden[name=id]").attr("value");
	$j("#popup_vote .p_vote a").attr("href", "/contest/vote/"+load_design_id);
	/*Image*/
	load_image = $j("#design_"+image+" .c_img img").attr("src");
	$j("#popup_vote .p_img #preview_img").attr("src", load_image);
	
	/*Design before*/
	$j("#design_order").attr("value", "");
	$j("#design_order").attr("value", image);
}

function closePopupVote(){
	removeOpacity();
	$j("#popup_vote").css("visibility", "hidden");
	$j("#popup_vote .p_img .p_before").css("display", "none");
	$j("#popup_vote .p_img .p_after").css("display", "none");
}

function newDesignVote(image){
	changeInfoPopup(image);
}

function createOpacity(){
	$j("#popup_opacity").css("display", "block");
	
	$j("#popup_opacity").css("z-index", "1100");
	$j("#popup_vote").css("z-index", "1101");
}

function removeOpacity(){
	$j("#popup_opacity").css("display", "none");
	
	$j("#popup_opacity").css("z-index", "-1");
	$j("#popup_vote").css("z-index", "-1");
}

function show_coord(index){
	alert($j("#design_"+index).pageX);
}