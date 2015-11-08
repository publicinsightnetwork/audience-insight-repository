var pin_mpf_current_fs, pin_mpf_next_fs, pin_mpf_previous_fs; //fieldsets
var pin_mpf_left, pin_mpf_opacity, pin_mpf_scale; //fieldset properties which we will animate
var pin_mpf_animating; //flag to prevent quick multi-click glitches

$(".pin-mpf-next").click(function(){
	pin_mpf_current_fs = $(this).parents("fieldset");
	pin_mpf_next_fs = pin_mpf_current_fs.next(); 
	var pin_mpf_valid = PIN.Form.validatePage(pin_mpf_current_fs.find(".pin-mpf-q-div").attr('id'))
	if(pin_mpf_valid){
		if(pin_mpf_animating) return false;
		pin_mpf_animating = true;
		
		//hide the current fieldset with style
		pin_mpf_current_fs.animate({opacity: 0}, {
			step: function(now, mx) {
				//as the opacity of pin_mpf_current_fs reduces to 0 - stored in "now"
				//1. pin_mpf_scale pin_mpf_current_fs down to 80%
				pin_mpf_scale = 1 - (1 - now) * 0.2;
				//2. bring pin_mpf_next_fs from the right(50%)
				pin_mpf_left = (now * 50)+"%";
				//3. increase opacity of pin_mpf_next_fs to 1 as it moves in
				pin_mpf_opacity = 1 - now;
				pin_mpf_current_fs.css({'transform': 'scale('+pin_mpf_scale+')'});
				pin_mpf_next_fs.css({'left': pin_mpf_left, 'opacity': pin_mpf_opacity});
			}, 
			duration: 800, 
			complete: function(){
				pin_mpf_current_fs.hide();
				pin_mpf_animating = false;
			}, 
			//this comes from the custom easing plugin  
			easing: 'easeInOutBack'
		});

		//show the next fieldset
		pin_mpf_next_fs.show(); 
	}
});

$(".pin-mpf-previous").click(function(){
	if(pin_mpf_animating) return false;
	pin_mpf_animating = true;
	
	pin_mpf_current_fs = $(this).parents("fieldset");
	pin_mpf_previous_fs = pin_mpf_current_fs.prev(); 
	
	//hide the current fieldset with style
	pin_mpf_current_fs.animate({opacity: 0}, {
		step: function(now, mx) {
			//as the opacity of pin_mpf_current_fs reduces to 0 - stored in "now"
			//1. pin_mpf_scale pin_mpf_previous_fs from 80% to 100%
			pin_mpf_scale = 0.8 + (1 - now) * 0.2;
			//2. take pin_mpf_current_fs to the right(50%) - from 0%
			pin_mpf_left = ((1-now) * 50)+"%";
			//3. increase opacity of pin_mpf_previous_fs to 1 as it moves in
			pin_mpf_opacity = 1 - now;
			pin_mpf_current_fs.css({'left': pin_mpf_left});
			pin_mpf_previous_fs.css({'transform': 'scale('+pin_mpf_scale+')', 'opacity': pin_mpf_opacity});
		}, 
		duration: 800, 
		complete: function(){
			pin_mpf_current_fs.hide();
			pin_mpf_animating = false;
		}, 
		//this comes from the custom easing plugin
		easing: 'easeInOutBack'
	});

	//show the previous fieldset
	pin_mpf_previous_fs.show(); 
});
