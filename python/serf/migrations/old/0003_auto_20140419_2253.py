# encoding: utf8
from django.db import models, migrations

#Default DetailTypes
defdets = [('BG_start_ms','Background start in ms'),
	('BG_stop_ms','Background stop in ms'),
	('BG_chan_label','Background channel label'),
	('MR_start_ms','M-response start in ms'),
	('MR_stop_ms','M-response start in ms'),
	('MR_chan_label','M-response channel label'),
	('HR_start_ms','H-reflex start in ms'),
	('HR_stop_ms','H-reflex start in ms'),
	('HR_chan_label','H-reflex channel label'),
	('HR_detection_limit','Min HR size for true detection'),
	('Nerve_stim_output','Nerve stimulator output intensity'),
	('MEP_start_ms','MEP start in ms'),
	('MEP_stop_ms','MEP start in ms'),
	('MEP_chan_label','MEP channel label'),
	('MEP_detection_limit','Min MEP size for true detection'),
	('TMS_powerA','Stimulator output in pcnt'),
	('TMS_powerB','Second pulse intensity in Bistim'),
	('TMS_ISI_ms','Bistim inter-stim interval in ms'),
	('TMS_coil_x','Coil x-coordinate in mm'),
	('TMS_coil_y','Coil y-coordinate in mm'),
	('TMS_coil_z','Coil z-coordinate in mm'),
	('TMS_coil_rot','Coil rotation in deg'),
	('Task_condition','Which task was used this trial? (e.g. 0 or 1)'),
	('Task_start_ms','Task analysis window start in ms'),
	('Task_stop_ms','Task analysis window stop in ms'),
	('Conditioned_feature_name','feature_type.name of conditioned feature'),
	('Conditioned_result','Whether the conditioned feature was rewarded')]
	
def def_det_typ(apps, schema_editor):
    DetailType = apps.get_model("eerfapp", "DetailType")
    for k,v in defdets:
        DetailType.objects.get_or_create(name=k, description=v)
        
def rem_def_det_typ(apps, schema_editor):
    DetailType = apps.get_model("eerfapp", "DetailType")
    for k,v in defdets:
        dettype = DetailType.objects.filter(name=k)
        if dettype: dettype[0].delete()

#Default FeatureTypes
deffeats = [('BEMG_aaa','Background EMG avg abs amp'),
	('MR_aaa','M-response avg abs amp'),
	('HR_aaa','H-reflex avg abs amp'),
	('MEP_p2p','MEP peak-to-peak'),
	('MEP_aaa','MEP average abs amp')]
	
def def_feat_typ(apps, schema_editor):
    FeatureType = apps.get_model("eerfapp", "FeatureType")
    for k,v in deffeats:
        FeatureType.objects.get_or_create(name=k, description=v)
        
def rem_def_feat_typ(apps, schema_editor):
    FeatureType = apps.get_model("eerfapp", "FeatureType")
    for k,v in deffeats:
        feattype = FeatureType.objects.filter(name=k)
        if feattype: feattype[0].delete()

class Migration(migrations.Migration):

    dependencies = [
        ('eerfapp', '0002_auto_20140419_2253'),
    ]

    operations = [
        migrations.RunPython(def_det_typ, reverse_code=rem_def_det_typ),
        migrations.RunPython(def_feat_typ, reverse_code=rem_def_feat_typ),
        migrations.RunSQL("ALTER TABLE datum MODIFY COLUMN number integer UNSIGNED NOT NULL DEFAULT 0", reverse_sql="ALTER TABLE datum MODIFY COLUMN number integer UNSIGNED NOT NULL"),
        migrations.RunSQL("ALTER TABLE datum MODIFY COLUMN is_good bool NOT NULL DEFAULT 1", reverse_sql="ALTER TABLE datum MODIFY COLUMN is_good bool NOT NULL")
    ]