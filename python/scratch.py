import sys
import os
sys.path.append(os.path.abspath('d:/tools/eerf/python/eerf'))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eerf.settings")
from api.models import *

# Use these next few lines to help with debugging.
self = lambda: None
self.app = lambda: None
self.app.params = {'SubjectName':'Test', 'ERPChan':['C3','EDC'], 'ERPFeedbackFeature': 'MEP_p2p'}
self.app.x_vec = np.arange(-500,500,1000.0/2400,dtype=float)
value = np.random.rand(2,2400)
self.app.subject = Subject.objects.get_or_create(name=self.app.params['SubjectName'])[0]# Get our subject from the DB API.
self.app.period = self.app.subject.get_or_create_recent_period(delay=0)# Get our period from the DB API.
my_trial = Datum.objects.create(subject=self.app.subject,
            span_type='trial'
            )
self.app.period.trials.add(my_trial)
my_store = DatumStore(datum=my_trial,
             x_vec=self.app.x_vec,
             channel_labels=self.app.params['ERPChan'])
my_store.data = value #this will also set n_channels and n_samples

last_trial = self.app.period.trials.order_by('-datum_id').all()[0] if self.app.period.trials.count()>0 else None
feature_name = self.app.params['ERPFeedbackFeature']
last_trial.update_ddv('Conditioned_feature_name', feature_name)

last_trial.update_ddv('MEP_start_ms', '20.0')
last_trial.update_ddv('MEP_stop_ms', '30.0')
last_trial.update_ddv('MEP_chan_label', 'EDC')
last_trial.calculate_value_for_feature_name(feature_name)
feature_value = last_trial.feature_values_dict()[feature_name]
last_trial.update_ddv('Conditioned_result',True)