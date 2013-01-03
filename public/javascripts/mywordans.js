$j(document).ready(function(){
  $j("#select_all").click(function(){
    var checked_status = this.checked;    
    $j(".check_all").each(function() {
      this.checked = checked_status;
    });
  }); 

	$j("#myproducts_actions").change(function (){
		var selected_value = $j("#myproducts_actions").val();
		var product_ids = ""
		$j(".check_all:checked").each(function() { product_ids+=$j(this).val()+",";	});
		product_ids=product_ids.substr(0,product_ids.length-1);
		if (selected_value != "nothing"){
			$j("a#"+selected_value).attr("href",$j("a#"+selected_value).attr("href")+"?product_ids="+product_ids);
			$j("a#"+selected_value).fancybox();
			$j("a#"+selected_value).click();
		}
		$j("#myproducts_actions").val("nothing");
	});	
});

function submit_product_form(product){
	var action = $j('#products_form').attr('action');	
	action = action.replace('save_basic_info','save_basic_info/'+product);
	$j('#products_form').attr('action',action);
	return $j('#products_form').submit();
}

function delete_product(product){
	$j("a#delete_selected").attr("href",$j("a#delete_selected").attr("href")+"?product_ids="+product);
	$j("a#delete_selected").fancybox({'autoDimensions':false, 'width':390, 'height':130});
	$j("a#delete_selected").click();
}

function select_all(){
	$j("#select_all").click();
  $j(".check_all").each(function() {
    this.checked = $j("#select_all").attr("checked");
  });
}
