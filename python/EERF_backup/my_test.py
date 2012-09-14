from EERF.API import *
from EERF.APIextension.online import *
subject = Session().query(Subject).all()[-1]
self = lambda: None
self.app = lambda: None
self.app.period = subject.periods[-1]
self.app.period.detail_values['MEP_start_ms']=18
Session().commit()