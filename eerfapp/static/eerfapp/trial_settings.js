$(document).ready(function () {

    var dt_start = new Date();
    var dt_stop = new Date(dt_start.getTime() + 1000*60*60*12);
    var trial_lim = 5;

    var refresh_trial_form = function(){
        $(".trial_start")[0].value = dt_start.toLocaleString();//.substring(4,24);
        $(".trial_stop")[0].value = dt_stop.toLocaleString();//.substring(4,24);
        $(".trial_limit")[0].value = trial_lim;
    };

    $.get("http://127.0.0.1:8000/eerfapp/my_session/", {}, function(result) {
        result = JSON.parse(result);
        if (result.hasOwnProperty('monitor')) {
            $(".monitor")[0].checked = result['monitor'];
        }
        var temp_date = new Date();
        mins_to_add = temp_date.getTimezoneOffset();
        if (result.hasOwnProperty('trial_start')) {
            dt_start = new Date(result['trial_start']);
            dt_start.setMinutes(dt_start.getMinutes()+mins_to_add);
        }
        if (result.hasOwnProperty('trial_stop')) {
            dt_stop = new Date(result['trial_stop']);
            dt_stop.setMinutes(dt_stop.getMinutes()+mins_to_add);
        }
        if (result.hasOwnProperty('trial_limit')) {
            trial_lim = result['trial_limit'];
        }
        refresh_trial_form();
    });

    var n_trials;
    $.get("http://127.0.0.1:8000/eerfapp/subject/" + subject_pk + "/count_trials/", {}, function(resp) {
        //TODO: Get rid of the hard-coded URL.
        n_trials = resp;
    });

    //Bind the defaults button to reset the times. 2012-09-11T22:54:00
    $(".reset_trial_settings").click( function(){
        $(".monitor")[0].checked = true;
        dt_start = new Date();
        dt_stop = new Date(dt_start.getTime() + 1000*60*60*12);
        trial_lim = 5;
        refresh_trial_form();
    } );

    setInterval(
        function () {
            if ($(".monitor")[0].checked) {
                $.get("http://127.0.0.1:8000/eerfapp/subject/" + subject_pk + "/count_trials/", {}, function(resp) {
                    if (resp != n_trials){
                        $(window).trigger("new_data");
                        n_trials = resp;
                    }
                });
            }
        }
    , 700);//milliseconds
});