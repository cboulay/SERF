$(document).ready(function () {
		
    var options = {
        series: {
            lines: { show: true },
            points: { show: false }
        },
        legend: { noColumns: 2 },
        xaxis: { tickDecimals: 0 },
        selection: { mode: "x" }
    };
    
    var placeholder=[];
    var plot=[];
    for (var i=0; i<channel_labels_s.length; i++){
    	placeholder[i] = $(".placeholder."+channel_labels_s[i]);
    	placeholder[i].bind("plotselected", function (event, ranges) {
	        $("#selection").text(ranges.xaxis.from.toFixed(1) + " to " + ranges.xaxis.to.toFixed(1));
	 
	        var zoom = $("#zoom").attr("checked");
	        if (zoom)
	            plot[i] = $.plot(placeholder[i], mydata[channel_labels_s[i]],
	                          $.extend(true, {}, options, {
	                              xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }
	                          }));
	    });
	 
	    placeholder[i].bind("plotunselected", function (event) {
	        $("#selection").text("");
	    });
	    
	    plot[i] = $.plot(placeholder[i], mydata[channel_labels_s[i]], options);
    };
    
    $("#clearSelection").click(function () {
    	for (var i=0; i<channel_labels.length; i++){
    		plot[i].clearSelection();
    	}
    });
    
    setInterval(
    	function () {
    		//oldest_pk is a global giving the oldest_pk on the screen
    		//if the page was loaded without an id, then oldest_pk will be the last trial in the db.
	    	$.get("http://127.0.0.1:8000/eerfd/store_pk_check/" + oldest_pk, {}, function(n_stores) {
	    		n_stores = JSON.parse(n_stores);
	    		n_plotted = channel_labels_s.length>0 ? mydata[channel_labels_s[0]].length : 0;
	    		if (n_stores>n_plotted){
	    			window.location = "http://127.0.0.1:8000/eerfd/monitor/" + oldest_pk;
	    			//this url will always give us the most recent 5 trials, and set oldest_pk to the oldest displayed
	    		}
			});
    	}
	, 700);//milliseconds
});