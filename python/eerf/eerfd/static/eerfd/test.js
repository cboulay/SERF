Ext.onReady(function() {
	var paragraphClicked = function(e) {
		var paragraph = Ext.get(e.target);
		paragraph.highlight();
		Ext.MessageBox.show({
			title: 'Paragraph Clicked',
			msg: paragraph.dom.innerHTML,
			width:400,
			buttons: Ext.MessageBox.OK,
			animEl: paragraph
		});
	}
	Ext.select('p').on('click', paragraphClicked);
});