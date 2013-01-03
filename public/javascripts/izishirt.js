function showSub(id) {
	document.getElementById('admin_users').style.display = "none";
	document.getElementById('admin_categories').style.display = "none";
	document.getElementById('admin_colors').style.display = "none";
	document.getElementById('admin_images').style.display = "none";
	document.getElementById(id).style.display = "block";
}

active_tab = 1;

function toggle_localization_tabs(id) {
	var tabs = document.getElementsByClassName("localized_tab_content");
	for (i=0; i<tabs.length; i++) {
		tabs[i].style.display = 'none';
	}
	
	document.getElementById("tabs_" + active_tab).className = 'tab_inactive';
	document.getElementById("tabs_" + id).className = 'tab_active';
	document.getElementById("div_localized_" + id).style.display = 'block';
	active_tab = id
}
function toggle_size_type_tabs(id){
	var tabs = document.getElementsByClassName("size_type_tab_content");
	for (i=0; i<tabs.length; i++) {
		tabs[i].style.display = 'none';
	}
	
	document.getElementById("tabs_" + active_tab).className = 'tab_inactive';
	document.getElementById("tabs_" + id).className = 'tab_active';
	document.getElementById("div_size_type_" + id).style.display = 'block';
	active_tab = id
}
