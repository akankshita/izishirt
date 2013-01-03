function rollover(source, target, image, set_master) {
	Event.observe(source, 'mouseover', function() {
		target.old_src = target.src;
		target.src = image;
	});
	Event.observe(source, 'mouseout', function() {
		target.src = target.old_src;
	});

}

function set_field_on_click(source, field, value) {
	Event.observe(source, 'click', function() {
		field.value = value;
	});	
}

function roundNumber(num, dec) {
	digits = Math.round(num-0.5)
	fraction = Math.round((num - digits) * Math.pow(10,dec))
	return '' + digits + '.' + fraction;
}

function toMoney(num) {
	return '$' + roundNumber(num, 2); 
}