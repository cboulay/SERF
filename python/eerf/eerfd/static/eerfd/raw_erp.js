$(document).ready(function () {
		
    var erp_options = {
        series: {
            lines: { show: true },
            points: { show: false }
        },
        legend: { show: false },
        xaxis: { tickDecimals: 0 },
        selection: { mode: "x" }
    };
    
    //Download the data and plot the ERPs.
    var placeholder=[];
    var checkboxes=[];
    var plot=[];
    var plot_erps = function() {
    	$.get("http://127.0.0.1:8000/eerfd/subject/" + subject_pk + "/erp_data/", {}, function(response) {
	    	response = JSON.parse(response);
	    	
	    	//Empty the wrappers
	    	$('div.erp_wrapper').empty();
	    	$('div.channel_wrapper').empty();
	    	
		    for (var i=0; i<response['channel_labels'].length; i++){
		    	//Plots
		    	var new_div = $('<div style="width:680px; height:300px"></div>');
		    	new_div.addClass(response.channel_labels[i]);
		    	$('div.erp_wrapper').append(new_div);
		    	placeholder[i] = $("."+ response.channel_labels[i]);
			    plot[i] = $.plot(placeholder[i], response.data[response.channel_labels[i]], erp_options);
			    
			    //Checkboxes for channel labels.
		    	var new_check = $('<input type="checkbox" name=' + response.channel_labels[i] + ' checked>' + response.channel_labels[i] + '</input>');
		    	new_check.addClass(response.channel_labels[i]);
		    	$('div.channel_wrapper').append(new_check);
		    	checkboxes[i] = $("input."+response.channel_labels[i]);
		    	checkboxes[i].click(function(el){
		    		$('div.'+el.srcElement.className).toggle($('input.'+el.srcElement.className)[0].checked);
		    	});
		    	
		    	//Binding for clicking on the plot
		    	placeholder[i].bind("plotselected", function (event, ranges) {
		    		selected_range = [ranges.xaxis.from, ranges.xaxis.to];
			        //$("#selection").text(ranges.xaxis.from.toFixed(1) + " to " + ranges.xaxis.to.toFixed(1));
			        $('input.first_detail').val(selected_range[0].toFixed(1));
			        $('input.second_detail').val(selected_range[1].toFixed(1));
			        $('input.channel_detail').val(event.target.className);
			    });
		    };
	    });
    };
    $(window).on("new_data", plot_erps);
    
    var selector_classes = ['first_detail', 'second_detail', 'channel_detail'];
    //Populate the selectors with different options
    $.get("http://127.0.0.1:8000/eerfd/detail_types/", {}, function(response){
    	response = JSON.parse(response);
    	for (var i=0; i<selector_classes.length; i++){
    		for (var j=0; j<response.length; j++){
    			var new_option = $('<option value='+response[j]+'>'+response[j]+'</option>');
    			$('select.'+selector_classes[i])[0].appendChild(new_option[0]);
    		}
    	}
    });
    
    //When the selectors change, the name of the input boxes should change.
    for (var i=0; i<selector_classes.length; i++){
    	$('select.'+selector_classes[i]).change(function(event){
    		var my_class = event.currentTarget.className;
    		$('input.' + my_class).attr('name', $('select.'+my_class).val());
    	});
    }
    
    
    //Plot the erps initially
    plot_erps();
});