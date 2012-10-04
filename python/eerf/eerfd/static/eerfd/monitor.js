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
 
    var placeholder = $("#placeholder");
 
    placeholder.bind("plotselected", function (event, ranges) {
        $("#selection").text(ranges.xaxis.from.toFixed(1) + " to " + ranges.xaxis.to.toFixed(1));
 
        var zoom = $("#zoom").attr("checked");
        if (zoom)
            plot = $.plot(placeholder, chaddata,
                          $.extend(true, {}, options, {
                              xaxis: { min: ranges.xaxis.from, max: ranges.xaxis.to }
                          }));
    });
 
    placeholder.bind("plotunselected", function (event) {
        $("#selection").text("");
    });
    
    var plot = $.plot(placeholder, chaddata, options);
 
    $("#clearSelection").click(function () {
        plot.clearSelection();
    });
    
    setInterval(
    	function () {
	    	$.get("http://127.0.0.1:8000/eerfd/store_pk_check/" + pk, {}, function(pk_check) {
	    		pk_check = JSON.parse(pk_check);
	    		if (pk_check[1]>=5){
	    			var new_pk = pk_check[0]-5;
	    			window.location = "http://127.0.0.1:8000/eerfd/monitor/" + new_pk;
	    		}
			});
    	}
	, 800);//milliseconds
});