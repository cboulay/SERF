$(document).ready(function () {
	$.get("http://127.0.0.1:8000/eerfd/my_session/", {}, function(result) {
		result = JSON.parse(result);
		if (result.hasOwnProperty('monitor')) {
			$(".monitor")[0].checked = result['monitor'];
		}
		if (result.hasOwnProperty('trial_start')) {
			$(".trial_start")[0].value = result['trial_start'];
		}
		if (result.hasOwnProperty('trial_stop')) {
			$(".trial_stop")[0].value = result['trial_stop'];
		}
	});
	
	var n_trials;
	$.get("http://127.0.0.1:8000/eerfd/subject/" + subject_pk + "/count_trials/", {}, function(resp) {
		//TODO: Get rid of the hard-coded URL.
		n_trials = resp;
	});
	
	//Bind the defaults button to reset the times. 2012-09-11T22:54:00
	$(".reset_trial_settings").click( function(){
		$(".monitor")[0].checked = true;
		var now = new Date();
		var now_string = now.toISOString();
		var future = new Date(now.getTime() + 1000*60*60*12);
		var future_string = now.toISOString();
		$(".trial_start")[0].value = now_string.substring(0,now_string.length-5);
		$(".trial_stop")[0].value = future_string.substring(0,future_string.length-5);
	} );
	
	setInterval(
    	function () {
    		if ($(".monitor")[0].checked) {
    			$.get("http://127.0.0.1:8000/eerfd/subject/" + subject_pk + "/count_trials/", {}, function(resp) {
	    			if (resp != n_trials){ window.location.reload(); }
				});
    		}
    	}
	, 700);//milliseconds
});