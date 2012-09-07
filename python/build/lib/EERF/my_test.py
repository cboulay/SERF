from EERF.API import *
subject = Session().query(Subject).all()[0]
subject.periods