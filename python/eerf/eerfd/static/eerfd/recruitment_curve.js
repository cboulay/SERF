$(document).ready(function () {
	
	var recruitment_options = {
        series: {
            lines: { show: false },
            points: { show: true }
        },
        legend: { show: true },
        xaxis: { tickDecimals: 0 },
        selection: { mode: "x" }
    };
    
    //Populate the x selector with detail names
    $.get("http://127.0.0.1:8000/eerfd/detail_types/", {}, function(response){
    	response = JSON.parse(response);
    	for (var j=0; j<response.length; j++){
			var new_option = $('<option value='+response[j]+'>'+response[j]+'</option>');
			$('select.x_name')[0].appendChild(new_option[0]);
		}
		if (response.indexOf("TMS_powerA") != -1){
			$('select.x_name').val('TMS_powerA');
		}
    });
    
    //Populate the y selector with feature names
    $.get("http://127.0.0.1:8000/eerfd/feature_types/", {}, function(response){
    	response = JSON.parse(response);
    	for (var j=0; j<response.length; j++){
			var new_option = $('<option value='+response[j]+'>'+response[j]+'</option>');
			$('select.y_name')[0].appendChild(new_option[0]);
		}
		if (response.indexOf("MEP_p2p") != -1){
			$('select.y_name').val('MEP_p2p');
		}
    });
    
    //Define a function to fetch the data and refresh the plot.
    var plot_xy = function(){
    	$.get("http://127.0.0.1:8000/eerfd/get_xy/"
    	, {"subject_pk": subject_pk, "x_name": $('select.x_name').val(), "y_name": $('select.y_name').val()}
    	, function(result){
    		result = JSON.parse(result);
    		var last_xy = result[0].data[result[0].data.length-1];
    		result[1] = {"label": "Last", "data": [last_xy]};
    		$.plot($('div.recruitment_wrapper'), result, recruitment_options);
    	});
    };
    
    var recalculate = function() {
    	if ($('input.recalculate')[0].checked){
    		$.get("http://127.0.0.1:8000/eerfd/subject/" + subject_pk + "/recalculate_feature/" + $('select.y_name').val()
	    	, {}, function(result){
	    		plot_xy();
	    	});
    	} else {plot_xy();}
    };
    
    //Bind to the refresh button
    $('input:button.refresh_plot').click(recalculate);
    $(window).on("new_data", recalculate);
    
    //Can't do an initial plot because we don't know which x and y values to get.
});