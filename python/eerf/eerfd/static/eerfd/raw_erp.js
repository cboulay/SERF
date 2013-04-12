$(document).ready(function () {

    var erp_options = {
        series: {
            lines: {
                show: true,
                lineWidth: 1
            },
            points: { show: false },
            shadowSize: 0
        },
        legend: { show: false },
        xaxis: { tickDecimals: 0 },
        selection: { mode: "x" }
    };

    //Download the data and plot the ERPs.
    var plot_erps = function() {
        $.get("http://127.0.0.1:8000/eerfd/subject/" + subject_pk + "/erp_data/", {}, function(response) {
            response = JSON.parse(response);

            //Empty the wrappers
            $('div.channel_wrapper').empty();
            $('div.erp_wrapper').empty();

            var opt_extend = {
                    hooks: { drawSeries: [series_hook] },
                    yaxis: {min: miny, max: maxy}
            };
            if ($("#zoom").attr("checked")==="checked" & parseFloat($('input.first_detail').val())){
                $.extend(opt_extend, {
                    xaxis: {
                            min: parseFloat($('input.first_detail').val()),
                            max: parseFloat($('input.second_detail').val())
                        }
                });
            }

            for (var i=0; i<response['channel_labels'].length; i++){
                //Plots
                var new_div = $('<div style="width:680px; height:300px"></div>');
                new_div.addClass(response.channel_labels[i]);
                $('div.erp_wrapper').append(new_div);

                //Hook into plot so we can modify the (last?) series' options
                var ch_data = response.data[response.channel_labels[0]];
                window.newest_label = ch_data[ch_data.length-1].label;
                var series_hook = function(plot, canvascontext, series) {
                    if (series.label==window.newest_label){
                        series.color = "rgb(255,0,0)";
                        series.lines.lineWidth = 1; //TODO: Make this configurable
                        series.shadowSize=1; //TODO: Make this configurable
                    }
                };

                //Get min and max values for the y-axis in a certain range.
                var miny = Infinity;
                var maxy = -Infinity;
                var yst = 3.0;
                for (var tt=0; tt<ch_data.length; tt++){
                    var trial_data = ch_data[tt].data;
                    for (var ss=0; ss<trial_data.length; ss++){
                        if (trial_data[ss][0] >= yst) {
                            miny = Math.min(miny, trial_data[ss][1]);
                            maxy = Math.max(maxy, trial_data[ss][1]);
                        }
                    }
                    /*
                    miny = trial_data.reduce(function(previousValue, currentValue, index, array){
                        return currentValue[0]>= yst ? Math.min(previousValue, currentValue[1]) : previousValue;
                    }, miny);
                    maxy = trial_data.reduce(function(previousValue, currentValue, index, array){
                        return currentValue[0] >= yst ? Math.max(previousValue, currentValue[1]) : previousValue;
                    }, maxy);*/
                }

                var plot = $.plot(new_div,
                    response.data[response.channel_labels[i]],
                    $.extend(erp_options, opt_extend)
                );

                //Checkboxes for channel labels.
                var new_hidden = $('<input type="hidden" value="off" name=' + response.channel_labels[i] + ' />')
                $('div.channel_wrapper').append(new_hidden);
                var new_check = $('<input type="checkbox" name=' + response.channel_labels[i] + ' checked>' + response.channel_labels[i] + '</input>');
                new_check.addClass(response.channel_labels[i]);
                $('div.channel_wrapper').append(new_check);
                $("input."+response.channel_labels[i]).change(function(el){
                    $('div.'+el.srcElement.className).toggle($('input.'+el.srcElement.className)[0].checked);
                });
            };

            //Binding for clicking on the plot
            new_div.bind("plotselected", function (event, ranges) {
                selected_range = [ranges.xaxis.from, ranges.xaxis.to];
                //$("#selection").text(ranges.xaxis.from.toFixed(1) + " to " + ranges.xaxis.to.toFixed(1));
                $('input.first_detail').val(selected_range[0].toFixed(1));
                $('input.second_detail').val(selected_range[1].toFixed(1));
                $('input.channel_detail').val(event.target.className);
            });

            //Get the session values and uncheck boxes that were saved as unchecked.
            $.get("http://127.0.0.1:8000/eerfd/my_session/", {}, function(result) {
                result = JSON.parse(result);
                var checkboxes = $('div.channel_wrapper').children('input:checkbox');
                for (var i=0; i<checkboxes.length; i++){
                    if (result.hasOwnProperty(checkboxes[i].name)){
                        checkboxes[i].checked = result[checkboxes[i].name]=="on";
                        $('div.'+checkboxes[i].className).toggle(checkboxes[i].checked);
                    }
                }
            });
        });
    };
    $(window).on("new_data", plot_erps);

    $("#zoom").click( function(){
        $(window).trigger("new_data");
    });

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