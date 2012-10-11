$(document).ready(function () {
	$.get("http://127.0.0.1:8000/eerfd/subject/" + subject_pk + "/detail_values/TMS_powerA/", {}, function(result) {
		result = JSON.parse(result);
		console.log(result);
	});
});