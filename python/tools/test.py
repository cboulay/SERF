from EeratAPI.API import *
from OnlineAPIExtension import *
from sqlalchemy import desc
sub = Session.query(Subject).filter(Subject.Name=="Test").one()
per = sub.periods[-1]
trial = per.trials[-1]
trial.calculate_value_for_feature_name('MEP_p2p')