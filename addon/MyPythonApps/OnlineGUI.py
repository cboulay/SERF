#cd D:/tools/eerat/python_apps/online_analysis
#run test_gui
import matplotlib
matplotlib.use('TkAgg')
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2TkAgg
from matplotlib.figure import Figure
from Tkinter import *
from EeratAPI.API import *
from OnlineAPIExtension import *
from sqlalchemy import desc
#from sqlalchemy.orm import *
#from sqlalchemy import *
from ListBoxChoice import ListBoxChoice
import random
import time

def reset_frame(frame):
    for ww in frame.pack_slaves():
        ww.pack_forget()
    #frame.grid_forget()
    return frame

def my_button_dict():
    return {"Subject Type": Subject_type\
            , "Subject": Subject\
            , "Datum Type": Datum_type\
            , "Detail Type": Detail_type\
            , "Feature Type": Feature_type}
    
class App:
    
    def __init__(self, master):
        
        #master is the root
        button_frame = Frame(master)#Simple container
        button_frame.pack(side = LEFT, fill = Y)
        
        dat_frame = Frame(master)
        dat_frame.pack(side = RIGHT, fill = Y)
        
        self.btn_dict = {}
                
        #Make a list of buttons
        for bb in my_button_dict().iterkeys():
            #action = lambda x = bb: DatFrame(frame=reset_frame(dat_frame), button_text=x)
            action = lambda bb = bb: ListFrame(frame=reset_frame(dat_frame)\
                           , title_text=bb\
                           , item_class=my_button_dict()[bb])
            self.btn_dict[bb] = Button(button_frame, text=bb, command=action)
            self.btn_dict[bb].pack(side = TOP, fill = X)

def def_render_func(item):
    return item.Name

class ListFrame:
    def __init__(self, frame=None, title_text=None, list_data=None, list_render_func=def_render_func, item_class=None, edit_frame='embed', new_item_func=None, del_item_func=None, open_item_func=None):
        #Sanitize the input
        if not frame: frame = Toplevel()
        self.frame = frame
        self.title_text=title_text
        if list_data is None:
            #session = Session()
            list_data = Session.query(item_class).all()
        self.list_data=list_data
        self.list_render_func=list_render_func
        self.item_class = item_class
        #Need to define the other frames before the edit frame.
        list_frame = Frame(frame)
        list_frame.pack(side=LEFT, fill=Y)
        button_frame=Frame(list_frame)
        button_frame.pack(side=BOTTOM)
        if edit_frame=='embed':
            edit_frame=Frame(frame)
            edit_frame.pack(side=RIGHT, fill=Y)
        self.edit_frame=edit_frame
        #Parent has the option of passing in new_func (useful for setting associations)
        self.new_item_func = new_item_func
        self.del_item_func = del_item_func
        #Parent has the option of passing in show_func (useful if new or double-click should spawn non-standard edit window)
        if not open_item_func: open_item_func=self.show_item
        self.open_item_func = open_item_func
        
        ##
        ## Prepare the elements
        ##
        ll = Label(list_frame, text=title_text)
        ll.pack(side=TOP, fill=X)
        ls = Scrollbar(list_frame)
        ls.pack(side=RIGHT, fill=Y)
        lb = Listbox(list_frame, yscrollcommand=ls.set)
        ls.config(command=lb.yview)
        i=0
        for item in self.list_data:
            lb.insert(i, self.list_render_func(item))
            i=i+1
        lb.bind("<Double-Button-1>", self.dbl_click)
        lb.pack(side=LEFT, fill=BOTH)
        self.lb=lb
                
        #New Button
        new_button = Button (button_frame, text="NEW", command = self.new_press)
        new_button.pack(side = LEFT, fill = X)
        
        #Delete Button
        del_button = Button (button_frame, text="DELETE", command = self.del_press)
        del_button.pack(side = RIGHT, fill = X)
 
    def new_press(self):
        #Instantiate the item
        if not self.new_item_func:
            #TODO: If we want to use default values,
            #then this should be persisted to db immediately with get_or_create
            #but then we must supply all key attributes.
            #item = get_or_create(self.item_class, Name="New")
            item=self.item_class(Name="New")
        else:
            item=self.new_item_func(self)
        self.list_data.append(item)
        #Session.commit()
        
        #item.Name=None
        #Insert it into list_data and listbox.
        
        self.lb.insert(END, self.list_render_func(item))
        self.lb.see(self.lb.size())
        self.lb.selection_clear(0,END)
        self.lb.selection_set(END)
        #Show the item in the edit frame
        self.open_item_func(item)
    
    def del_press(self):
        curs = self.lb.curselection()
        for dd in curs:
            instance = self.list_data[int(dd)]
            if not self.del_item_func:
                Session.delete(instance)
                #Session.commit()
                #print "Disabled db delete of", instance
            else:
                #Specify a delete function when we don't want the object deleted.
                #e.g., removing an association/relationship
                self.del_item_func(instance)
            self.lb.delete(int(dd))#Remove the index from the listbox
    
    def dbl_click(self,ev):
        item = self.list_data[int(self.lb.curselection()[0])]
        #Show the item in the edit frame
        self.open_item_func(item)
    
    def show_item(self,item):
        if self.edit_frame: self.edit_frame=reset_frame(self.edit_frame)
        EditFrame(frame=self.edit_frame, item=item)
        
class EditFrame:
    def __init__(self, frame=None, item=None):
        self.item = item
        if not frame: frame=Toplevel()
        self.frame = frame
        
        attr_frame = Frame(frame)
        attr_frame.pack(side=TOP, fill=X)
        
        #Everything has Name
        name_frame = Frame(attr_frame)
        name_frame = name_frame
        name_frame.pack(side = TOP, fill = X)
        name_label = Label(name_frame, text="Name")
        name_label.pack(side = LEFT)
        name_var = StringVar(name_frame)
        name_var.set(item.Name)
        name_var.trace("w", lambda name, index, mode, name_var=name_var: self.update_name(name_var))
        name_entry = Entry(name_frame, textvariable=name_var)
        name_entry.pack(side = RIGHT, fill = X)
        
        #Many things have Description
        if hasattr(item,'Description'):
            desc_frame = Frame(attr_frame)
            desc_frame.pack(side = TOP, fill = X)
            desc_label = Label(desc_frame, text="Description")
            desc_label.pack(side = LEFT)
            desc_var = StringVar(desc_frame)
            desc_var.set(item.Description)
            desc_var.trace("w", lambda name, index, mode, desc_var=desc_var: self.update_description(desc_var))
            desc_entry = Entry(desc_frame, textvariable=desc_var)
            desc_entry.pack(side = RIGHT, fill = X)
            
        #Almost as many things have DefaultValue
        if hasattr(item,'DefaultValue'):
            dv_frame = Frame(attr_frame)
            dv_frame.pack(side = TOP, fill = X)
            dv_label = Label(dv_frame, text="Default Value")
            dv_label.pack(side = LEFT)
            dv_var = StringVar(dv_frame)
            if isinstance(item.DefaultValue,str):
                dv_var.set(item.DefaultValue)
            else: dv_var.set(str(item.DefaultValue))
            dv_var.trace("w", lambda name, index, mode, dv_var=dv_var: self.update_defaultvalue(dv_var))
            dv_entry = Entry(dv_frame, textvariable=dv_var)
            dv_entry.pack(side = RIGHT, fill = X)
            
        #save_button = Button(attr_frame, text="Save", command=self.commit)
        #save_button.pack(side=TOP, fill=X)
            
        #Further attributes require separate frames.
        if hasattr(item, 'DateOfBirth'):
            ss_frame = Frame(attr_frame)
            ss_frame.pack(side = TOP)
            SubjectFrame(frame=ss_frame, subject=item)
            
        #TODO: detail type list box.
        if hasattr(item, 'detail_types'):
            dt_frame = Frame(attr_frame)
            dt_frame.pack(side=TOP)
            DetailListFrame(frame=dt_frame, parent=item)
            
        if hasattr(item, 'feature_types'):
            ft_frame = Frame(attr_frame)
            ft_frame.pack(side=TOP)
            FeatureListFrame(frame=ft_frame, parent=item)
            
    def commit(self):
        print "Autocommit enabled so this does nothing"
        #Session.commit()
    
    def update_name(self, name_var):
        self.item.Name = name_var.get()
                
    def update_description(self, desc_var):
        self.item.Description = desc_var.get()
        
    def update_defaultvalue(self, dv_var):
        if isinstance(self.item.DefaultValue,str):
            self.item.DefaultValue = dv_var.get()
        else:
            self.item.DefaultValue = float(dv_var.get())
              
class SubjectFrame:
    def __init__(self, frame=None, subject=None):
        self.subject = subject
        if not frame: frame=Toplevel()
        self.frame = frame
        
        sp_names=['human','rat']#TODO: I wish there was a way I could figure out what the enum possibilities were.
        
        self.sub_types = Session.query(Subject_type).all()
        
        if not self.subject.subject_type: #implies subject not yet persisted in db
            self.subject.subject_type = self.sub_types[0]
            Session.add(self.subject) #New subject is now pending           
        
        det_frame = Frame(frame)
        det_frame.pack(side=LEFT, fill=Y)
        pd_frame = Frame(frame)
        pd_frame.pack(side=RIGHT, fill=Y)
        
        #We already have Name, this is for everything else related to the subject
        #DateOfBirth
        dob_frame = Frame(det_frame)
        dob_frame.pack(side=TOP, fill=X)
        dob_label = Label(dob_frame, text="DOB (YYYY-MM-DD)")
        dob_label.pack(side = LEFT)
        dob_var = StringVar(dob_frame)
        dob_var.set(self.subject.DateOfBirth)
        dob_var.trace("w", lambda name, index, mode, dob_var=dob_var: self.update_dob(dob_var))
        dob_entry = Entry(dob_frame, textvariable=dob_var)
        dob_entry.pack(side=RIGHT, fill=X)

        #IsMale
        gender_frame = Frame(det_frame)
        gender_frame.pack(side=TOP, fill=X)
        gender_label = Label(gender_frame, text="Gender")
        gender_label.pack(side = LEFT)
        self.gender_var = IntVar(gender_frame)
        self.gender_var.set(self.subject.IsMale)
        gender_rb_frame = Frame(gender_frame)
        gender_rb_frame.pack(side=RIGHT, fill=X)
        gender_m_radio = Radiobutton(gender_rb_frame, text="M", variable=self.gender_var, value=1, command=self.update_gender)
        gender_m_radio.pack(side=LEFT)
        gender_f_radio = Radiobutton(gender_rb_frame, text="F", variable=self.gender_var, value=0, command=self.update_gender)
        gender_f_radio.pack(side=LEFT)
        
        #Weight
        wt_frame = Frame(det_frame)
        wt_frame.pack(side=TOP, fill=X)
        wt_label = Label(wt_frame, text="Weight (g)")
        wt_label.pack(side=LEFT)
        wt_var = StringVar(wt_frame)
        wt_var.set(self.subject.Weight)
        wt_var.trace("w", lambda name, index, mode, wt_var=wt_var: self.update_weight(wt_var))
        wt_entry = Entry(wt_frame, textvariable=wt_var)
        wt_entry.pack(side=RIGHT, fill=X)
        
        #TODO: Notes
        
        #species_type (OptionMenu)
        spt_frame = Frame(det_frame)
        spt_frame.pack(side=TOP, fill=X)
        sptype_label = Label(spt_frame, text="Species type:")
        sptype_label.pack(side=LEFT)
        sptype_var = StringVar()
        sptype_var.set(self.subject.species_type)
        sptype_var.trace("w", lambda name, index, mode, sptype_var=sptype_var: self.update_species(sptype_var))
        sp_names = [spn for spn in sp_names if spn != self.subject.species_type]
        spt_menu = OptionMenu(spt_frame, sptype_var, self.subject.species_type, *sp_names)
        spt_menu.pack(side=LEFT)
        
        #subject_type (OptionMenu) requires subject to have a subject_type
        sbt_frame = Frame(det_frame)
        sbt_frame.pack(side=TOP, fill=X)
        sbtype_label = Label(sbt_frame, text="Subject type:")
        sbtype_label.pack(side=LEFT)
        sbtype_var = StringVar()
        sbtype_var.set(self.subject.subject_type.Name)
        sbtype_var.trace("w", lambda name, index, mode, sbtype_var=sbtype_var: self.update_subject_type(sbtype_var))
        st_names = [st.Name for st in self.sub_types if st.subject_type_id != self.subject.subject_type_id]
        st_menu = OptionMenu(sbt_frame, sbtype_var, self.subject.subject_type.Name, *st_names)
        st_menu.pack(side=LEFT)
        
        #TODO: Each detail for this subject_type - do as a function that can change if subject_type changes
        #self.subject.details is a kv struct.
        self.details_frame = Frame(det_frame)
        self.details_frame.pack(side=TOP, fill=X)
        self.render_details()
        
        #TODO: MVIC preview
        
        #TODO: SIC preview
        
        #button to load periods
        self.showing_periods = False
        pb_frame = Frame(det_frame)
        pb_frame.pack(side=BOTTOM, fill=X)
        self.pb_button = Button(pb_frame, text="Periods >>", command=self.toggle_periods)
        self.pb_button.pack(side=RIGHT)
        self.per_list_frame = pd_frame
        
    def update_dob(self, dob_var):
        #TODO: Check that it matches 'YYYY-MM-DD'
        self.subject.DateOfBirth = dob_var.get()
    def update_gender(self):
        self.subject.IsMale = self.gender_var.get()
    def update_weight(self, wt_var):
        self.subject.Weight=float(wt_var.get())
    def update_species(self, type_var):
        self.subject.species_type=type_var.get()
    def update_subject_type(self, type_var):
        #Find the subject type that matches
        stname = type_var.get()
        self.subject.subject_type_id = [st.subject_type_id for st in self.sub_types if st.Name==stname][0]
        #Session.commit() #Force commit because subject type affects other details and features.
        self.render_details()
    def render_details(self):
        sdvs=self.subject.subject_detail_value
        self.details_frame=reset_frame(self.details_frame)
        for sdv in sdvs.itervalues():
            self.render_sdv(sdv,self.details_frame)
    def render_sdv(self,sdv,frame):
        parent = Frame(frame)
        parent.pack(side=TOP, fill=X)
        lab = Label(parent, text=sdv.detail_name)
        lab.pack(side=LEFT)
        str_var = StringVar(parent)
        str_var.set(sdv.Value)
        str_var.trace("w", lambda name, index, mode, str_var=str_var: self.update_sdv(ddv,str_var))
        entry = Entry(parent, textvariable=str_var)
        entry.pack(side=RIGHT)
    def update_sdv(self,sdv,str_var):
        sdv.Value=str_var.get()
    def toggle_periods(self):
        frame=reset_frame(self.per_list_frame)
        self.showing_periods = not self.showing_periods
        self.pb_button.configure(text="Periods <<" if self.showing_periods else "Periods >>")
        if self.showing_periods:
            PerListFrame(frame=frame, subject=self.subject)
            
class DetailListFrame:#For setting X_type associations
    def __init__(self, frame=None, parent=None):
        if not frame: frame=Toplevel()
        self.frame = frame
        self.parent = parent
        
        lf = ListFrame(frame, title_text="Detail Types", list_data=self.parent.detail_types\
                  , item_class=Detail_type\
                  , edit_frame=None\
                  , new_item_func=self.add_dt\
                  , del_item_func=self.rem_dt)
        
    def add_dt(self, lf):
        #self is DetailListFrame, lf is ListFrame
        #self.parent is the item we wish to add an association to.
        #We must return a detail_type to add to the list. Get detail_types we don't already have.
        session = Session.object_session(self.parent)
        dts = get_or_create(Detail_type, all=True, sess=session)
        dts = [dt for dt in dts if dt not in self.parent.detail_types]
        #Modal list box to choose. I hope this is blocking.
        det_to_add = ListBoxChoice(self.frame, "Detail Types", "Pick a detail type to add", dts).returnValue()
        #self.parent.detail_types.append(det_to_add)
        return det_to_add
    def rem_dt(self, instance):
        #self.parent is the item with the association
        #instance is the item to be disassociated
        #We don't actually want to delete the item, just its association with its parent
        self.parent.detail_types.remove(instance)
        
class FeatureListFrame:#For setting X_type associations
    def __init__(self, frame=None, parent=None):
        if not frame: frame=Toplevel()
        self.frame = frame
        self.parent = parent
        
        lf = ListFrame(frame, title_text="Feature Types", list_data=self.parent.feature_types\
                  , item_class=Feature_type\
                  , edit_frame=None\
                  , new_item_func=self.add_ft\
                  , del_item_func=self.rem_ft)
        
    def add_ft(self, lf):
        #self is DetailListFrame, lf is ListFrame
        #self.parent is the item we wish to add an association to.
        #We must return a detail_type to add to the list. Get detail_types we don't already have.
        session = Session.object_session(self.parent)
        fts = get_or_create(Feature_type, all=True, sess=session)
        fts = [ft for ft in fts if ft not in self.parent.feature_types]
        #Modal list box to choose. I hope this is blocking.
        feat_to_add = ListBoxChoice(self.frame, "Feature Types", "Pick a feature type to add", fts).returnValue()
        #self.parent.detail_types.append(det_to_add)
        return feat_to_add
    def rem_ft(self, instance):
        #self.parent is the item with the association
        #instance is the item to be disassociated
        #We don't actually want to delete the item, just its association with its parent
        self.parent.feature_types.remove(instance)
        
class PerListFrame:
    def __init__(self, frame=None, subject=None):
        self.subject = subject
        if not frame: frame=Toplevel()
        self.frame = frame
        
        lf = ListFrame(frame, title_text="Periods", list_data=subject.periods\
                  , list_render_func=lambda x: x.datum_type.Name + " " + str(x.Number) + " " + str(x.StartTime) + " to " + str(x.EndTime)
                  , item_class=Datum\
                  , edit_frame=None\
                  , new_item_func=self.new_per\
                  , open_item_func=self.open_per)
        
    #period instantiation requires keys, 
    #thus we need a custom new_per function that creates the period.
    def new_per(self,lf):
        #self is PerListFrame, lf is ListFrame
        session = Session.object_session(self.subject)
        dat_types = get_or_create(Datum_type, all=True)
        #Where do we want the datum_type from?
        period = get_or_create(Datum, sess=session\
            , subject=self.subject\
            , datum_type=dat_types[0]\
            , span_type='period'\
            , IsGood=1\
            , Number=0)
        return period
    
    #Use a separate frame for periods
    def open_per(self,period):
        PeriodFrame(period=period)
        
class PeriodFrame:
    def __init__(self, frame=None, period=None):
        self.period = period
        if not frame: frame=Toplevel()
        self.frame = frame
        
        session = Session.object_session(self.period)
        
        id_frame = Frame(frame)
        id_frame.pack(side=TOP, fill=X)
        dates_frame = Frame(frame)
        dates_frame.pack(side=TOP, fill=X)
        plot_frame = Frame(frame)
        plot_frame.pack(side=TOP, fill=X)
        bframe = Frame(frame)
        bframe.pack(side=TOP, fill=X)
        self.detail_frame = Frame(bframe)
        self.detail_frame.pack(side=LEFT)
        pbutton_frame = Frame(bframe)
        pbutton_frame.pack(side=LEFT)
        
        #Period ID
        subj_name_label = Label(id_frame, text="Subject: " + self.period.subject.Name)
        subj_name_label.pack(side=LEFT)
        self.num_label = Label(id_frame, text="Number: " + str(self.period.Number))
        self.num_label.pack(side=LEFT)
        type_label = Label(id_frame, text="Datum type:")
        type_label.pack(side=LEFT)
        type_var = StringVar()
        type_var.set(self.period.datum_type.Name)
        type_var.trace("w", lambda name, index, mode, type_var=type_var: self.update_type(type_var))
        datum_types = get_or_create(Datum_type,all=True,sess=session)
        dt_names = [dt.Name for dt in datum_types]
        dt_menu = OptionMenu(id_frame, type_var, self.period.datum_type.Name, *dt_names)
        dt_menu.pack(side=LEFT)
        
        #Dates
        start_label = Label(dates_frame, text="StartTime (YYYY-MM-DD hh:mm:ss)")
        start_label.pack(side = LEFT)
        start_var = StringVar(dates_frame)
        start_var.set(self.period.StartTime)#str()?
        start_var.trace("w", lambda name, index, mode, start_var=start_var: self.update_start(start_var))
        start_entry = Entry(dates_frame, textvariable=start_var)
        start_entry.pack(side=LEFT, fill=X)
        end_label = Label(dates_frame, text="EndTime")
        end_label.pack(side = LEFT)
        end_var = StringVar(dates_frame)
        end_var.set(self.period.EndTime)#str()?
        end_var.trace("w", lambda name, index, mode, end_var=end_var: self.update_end(end_var))
        end_entry = Entry(dates_frame, textvariable=end_var)
        end_entry.pack(side=LEFT, fill=X)
        
        #Plot
        self.erp_fig = Figure()
        erp_canvas = FigureCanvasTkAgg(self.erp_fig, master=plot_frame)
        erp_canvas.show()
        erp_canvas.get_tk_widget().pack(side=TOP, fill=BOTH, expand=1)
        toolbar = NavigationToolbar2TkAgg( erp_canvas, plot_frame )
        toolbar.update()
        erp_canvas._tkcanvas.pack(side=TOP, fill=BOTH, expand=1)
        self.plot_erps()
        
        self.render_details()
        
        #Plot buttons
        refr_button = Button(pbutton_frame, text="Refresh", command=self.plot_erps)
        refr_button.pack(side=TOP, fill=X)
        reavg_button = Button(pbutton_frame, text="ReAvg ERP", command=self.period.update_store)
        reavg_button.pack(side=TOP, fill=X)
        if 'mapping' in self.period.type_name:
            mapping_button = Button(pbutton_frame, text="MEP Mapping", command=self.mep_map)
            mapping_button.pack(side=TOP, fill=X)
            xy_button = Button(pbutton_frame, text="Get XY", command=self.get_xy)
            xy_button.pack(side=TOP, fill=X)
            #space_type (OptionMenu)
            spt_frame = Frame(pbutton_frame)
            spt_frame.pack(side=TOP, fill=X)
            sptype_label = Label(spt_frame, text="Brainsight Space:")
            sptype_label.pack(side=LEFT)
            self.sptype_var = StringVar()
            self.sptype_var.set('brainsight')
            #sptype_var.trace("w", lambda name, index, mode, sptype_var=sptype_var: self.update_space(sptype_var))
            spt_menu = OptionMenu(spt_frame, self.sptype_var, 'brainsight','mni')
            spt_menu.pack(side=LEFT)
        elif 'io' in self.period.type_name:
            model_button = Button(pbutton_frame, text="Model IO", command=self.show_model)
            model_button.pack(side=TOP, fill=X)
            detection_button = Button(pbutton_frame, text="Calc Threshold", command = self.calc_threshold)
            detection_button.pack(side=TOP, fill=X)
        recalc_button = Button(pbutton_frame, text="Calc Features", command=self.recalc_features)
        recalc_button.pack(side=TOP, fill=X)
        
    def update_type(self, type_var):
        session = Session.object_session(self.period)
        self.period.datum_type = get_or_create(Datum_type, sess=session, Name=type_var.get())
        #session = Session.object_session(self.period)
        #self.period.datum_type = session.query(Datum_type).filter(Name==type_var.get()).first()
        #TODO: flush
        self.render_details()
        self.num_label.configure(text="Number: " + str(self.period.Number))
    def update_start(self, start_var):
        #TODO: Check that it matches 'YYYY-MM-DD hh:mm:ss'
        self.period.StartTime = start_var.get()
    def update_end(self, end_var):
        #TODO: Check that it matches 'YYYY-MM-DD hh:mm:ss'
        self.period.EndTime = end_var.get()
    def plot_erps(self):
        if len(self.period.trials.all())>0:
            if not self.period.store['channel_labels']:
                self.period.update_store()
            per_store=self.period.store
            #Find any channel that appears in period.detail_values
            chans_list = [pdv for pdv in self.period.detail_values.itervalues() if pdv in per_store['channel_labels']]
            chans_list = list(set(chans_list))#make unique
            #Boolean array to index the data.
            chan_bool = np.array([cl in chans_list for cl in per_store['channel_labels']])
            n_chans = sum(chan_bool)
            
            x_vec = per_store['x_vec']
            y_avg = per_store['data'].T[:,chan_bool]
            
            #get y data from up to 100 trials.
            trials = self.period.trials[-100:]
            #if len(trials)>100:
            #    #trials=random.sample(trials,100)
            #    trials=trials[:-100]
            y_trials = np.zeros((x_vec.shape[0],n_chans * len(trials)))
            tt=0
            for tr in trials:
                store=tr.store
                dat=store['data'].T[:,chan_bool]
                if n_chans>1:
                    y_trials[:,n_chans*tt:n_chans*tt+n_chans-1]=dat
                else:
                    y_trials[:,tt]=dat.T
                tt=tt+1
                
            #Find values for axvline
            window_lims = [pdv for pdk,pdv in self.period.detail_values.iteritems() if '_ms' in pdk]
            
            erp_ax = self.erp_fig.gca()
            #self.erp_fig.delaxes(erp_ax)
            erp_ax.clear()
            erp_ax = self.erp_fig.add_subplot(111)
            
            erp_ax.plot(x_vec, y_trials)
            erp_ax.plot(x_vec, y_avg, linewidth=3.0, label='avg')
            for ll  in window_lims:
                erp_ax.axvline(x=float(ll))
            erp_ax.set_xlim([-10,100])
            erp_ax.set_xlabel('TIME AFTER STIM (ms)')
            erp_ax.set_ylabel('AMPLITUDE (uV)')
            self.erp_fig.canvas.draw()
        
    def calc_threshold(self):
        self.period.detection_limit = None#Set the detail to None
        temp = self.period.detection_limit
        self.render_details()#Re-render ddv
    
    def show_model(self):
        ModelFrame(period=self.period)
    def mep_map(self):
        MapFrame(period=self.period)
        
    def render_details(self):
        self.detail_frame=reset_frame(self.detail_frame)
        parent = Frame(self.detail_frame)
        parent.pack(side=TOP, fill=X)
        lab = Label(parent, text="Detail")
        lab.pack(side=LEFT)
        lab = Label(parent, text="Value")
        lab.pack(side=RIGHT)
        for ddv in self.period.datum_detail_value.itervalues():
            self.render_ddv(ddv,self.detail_frame)
    def render_ddv(self,ddv,frame):
        parent = Frame(frame)
        parent.pack(side=TOP, fill=X)
        lab = Label(parent, text=ddv.detail_name)
        lab.pack(side=LEFT)
        str_var = StringVar(parent)
        str_var.set(ddv.Value)
        str_var.trace("w", lambda name, index, mode, str_var=str_var: self.update_ddv(ddv,str_var))
        entry = Entry(parent, textvariable=str_var)
        entry.pack(side=RIGHT)
    def update_ddv(self,ddv,str_var):
        ddv.Value=str_var.get()
        Session.flush()
    def recalc_features(self):
        #self.period._get_detection_limit()#Reget detection limit - why?
        self.period.recalculate_child_feature_values()#Recalculate features. This flushes the transaction.
    def get_xy(self):
        self.period.assign_coords(space=self.sptype_var.get())
        
class ModelFrame:
    def __init__(self, frame=None, period=None, doing_threshold=True):
        self.period = period
        if not frame: frame=Toplevel()
        self.frame = frame
        
        io_frame=Frame(frame)
        io_frame.pack(side=LEFT, fill=X)
        io_plot_frame=Frame(io_frame)
        io_plot_frame.pack(side=TOP, fill=X)
        self.io_label_frame=Frame(io_frame)
        self.io_label_frame.pack(side=TOP, fill=X)
        thresh_frame=Frame(frame)
        thresh_frame.pack(side=LEFT, fill=X)
        thresh_plot_frame=Frame(thresh_frame)
        thresh_plot_frame.pack(side=TOP, fill=X)
        self.thresh_label_frame=Frame(thresh_frame)
        self.thresh_label_frame.pack(side=TOP, fill=X)
        button_frame=Frame(thresh_frame)
        button_frame.pack(side=TOP, fill=X)
        
        #Plot IO
        self.io_fig = Figure()
        io_canvas = FigureCanvasTkAgg(self.io_fig, master=io_plot_frame)
        io_canvas.show()
        io_canvas.get_tk_widget().pack(side=TOP, fill=BOTH, expand=1)
        toolbar = NavigationToolbar2TkAgg( io_canvas, io_plot_frame )
        toolbar.update()
        io_canvas._tkcanvas.pack(side=TOP, fill=BOTH, expand=1)
        self.plot_io()
        
        #Plot Threshold
        self.thresh_fig = Figure()
        thresh_canvas = FigureCanvasTkAgg(self.thresh_fig, master=thresh_plot_frame)
        thresh_canvas.show()
        thresh_canvas.get_tk_widget().pack(side=TOP, fill=BOTH, expand=1)
        toolbar = NavigationToolbar2TkAgg( thresh_canvas, thresh_plot_frame )
        toolbar.update()
        thresh_canvas._tkcanvas.pack(side=TOP, fill=BOTH, expand=1)
        self.plot_thresh()
        
        #Buttons
        io_button = Button(button_frame, text="Model IO", command=self.plot_io)
        io_button.pack(side=LEFT)
        thresh_button = Button(button_frame, text="Model Threshold", command=self.plot_thresh)
        thresh_button.pack(side=LEFT)
        
    def plot_io(self):
        self.plot_either()
    def plot_thresh(self):
        self.plot_either(mode='threshold')
    def plot_either(self,mode=None):
        parms,parms_err,x,y = self.period.model_erp(model_type=mode)
        
        #if 'hr' in self.period.type_name:
        #    stim_det_name='dat_Nerve_stim_output'
        #    erp_name='HR_aaa'
        #elif 'mep' in self.period.type_name:
        #    stim_det_name='dat_TMS_powerA'
        #    erp_name='MEP_aaa'
            
        #x = self.period._get_child_details(stim_det_name)
        #x = x.astype(np.float)
        #y = self.period._get_child_features(erp_name)
        
        if not mode:#Default to io
            fig = self.io_fig
            ylabel = "AMPLITUDE"
            l_frame = reset_frame(self.io_label_frame)
            l_names = ['x0','k','a','c']
            sig_func = my_sigmoid
        elif mode=='threshold':
        #    y=y>self.period.erp_detection_limit
        #    y=y.astype(int)
            fig = self.thresh_fig
            ylabel = "EP DETECTED"
            l_frame = reset_frame(self.thresh_label_frame)
            l_names = ['x0','k']
            sig_func = my_simp_sigmoid
            
        x_est = np.arange(min(x),max(x),(max(x)-min(x))/100)
        y_est = sig_func(x_est,*list(parms))
            
        #Plot model estimate and actual values
        model_ax = fig.gca()
        model_ax.clear()
        model_ax = fig.add_subplot(111)
        model_ax.plot(x, y, 'o', label='data')
        model_ax.plot(x_est,y_est, label='fit')
        model_ax.legend(loc='upper left')
        model_ax.set_xlabel('STIMULUS INTENSITY')
        model_ax.set_ylabel(ylabel)
        fig.canvas.draw()
        
        #Display the model parameters x0, k, a, c
        i=0
        for ln in l_names:
            lab_str = '{0}: {1:.2f} +/- {2:.2f} ( {3:.2%})'.format(ln, parms[i], parms_err[i], parms_err[i]/parms[i])
            lab = Label(l_frame, text=lab_str)
            lab.pack(side=TOP)
            i=i+1
        if mode=='threshold':
            lab_str = 'Threshold: {0:.2f}'.format(self.period.detection_limit)
            lab = Label(l_frame, text=lab_str)
            lab.pack(side=TOP)
                    
class MapFrame:
    def __init__(self, frame=None, period=None):
        self.period = period
        if not frame: frame=Toplevel()
        self.frame = frame
        
        map_frame=Frame(frame)
        map_frame.pack(side=LEFT, fill=X)
        map_plot_frame=Frame(map_frame)
        map_plot_frame.pack(side=TOP, fill=X)
        self.map_label_frame=Frame(map_frame)
        self.map_label_frame.pack(side=TOP, fill=X)
        button_frame=Frame(map_frame)
        button_frame.pack(side=TOP, fill=X)
        
        #Plot Map
        self.map_fig = Figure()
        map_canvas = FigureCanvasTkAgg(self.map_fig, master=map_plot_frame)
        map_canvas.show()
        map_canvas.get_tk_widget().pack(side=TOP, fill=BOTH, expand=1)
        toolbar = NavigationToolbar2TkAgg( map_canvas, map_plot_frame )
        toolbar.update()
        map_canvas._tkcanvas.pack(side=TOP, fill=BOTH, expand=1)
        self.plot_map()
        
        #Buttons
        #map_button = Button(button_frame, text="REDO", command=self.plot_map)
        #map_button.pack(side=LEFT)
        
    def plot_map(self):
        fig = self.map_fig
        l_frame = reset_frame(self.map_label_frame)
        
        fts = self.period.datum_type.feature_types
        isp2p = any([ft for ft in fts if 'p2p' in ft.Name])
        erp_name= 'MEP_p2p' if isp2p else 'MEP_aaa'
        
        x = self.period._get_child_details('dat_TMS_coil_x').astype(float)
        y = self.period._get_child_details('dat_TMS_coil_y').astype(float)
        z = self.period._get_child_features(erp_name)
        
        #Limit ourselves to trials that had the same intensity as the last trial.
        power = self.period._get_child_details('dat_TMS_powerA')
        t_bool = np.asarray([p==power[-1] for p in power])
        x = x[t_bool]
        y = y[t_bool]
        z = z[t_bool]
        
        tx=np.linspace(min(x),max(x),100)
        ty=np.linspace(min(y),max(y),100)
        XI, YI = np.meshgrid(tx,ty)
        
        #http://docs.scipy.org/doc/scipy/reference/tutorial/interpolate-7.py
        from scipy.interpolate import Rbf
        rbf = Rbf(x, y, z, esplison=2)
        ZI = rbf(XI, YI)
        id = find(ZI==np.max(ZI))[0]
        best_x = XI.flatten()[id]
        best_y = YI.flatten()[id]

        #Plot model estimate and actual values
        map_ax = fig.gca()
        map_ax.clear()
        map_ax = fig.add_subplot(111)
        abc = map_ax.pcolor(XI,YI,ZI)
        fig.colorbar(abc)
        map_ax.scatter(x,y,100,z)
        map_ax.scatter(best_x,best_y,100,marker='x')
        map_ax.set_xlabel('X')
        map_ax.set_ylabel('Y')
        fig.canvas.draw()
        
        #Display the Map hotspot
        lab = Label(l_frame, text='HOTSPOT: X {0:.2f}, Y {1:.2f}'.format(best_x,best_y))
        lab.pack(side=TOP)
        
if __name__ == "__main__":
    #engine = create_engine("mysql://root@localhost/eerat", echo=False)#echo="debug" gives a ton.
    #Session = scoped_session(sessionmaker(bind=engine, autocommit=True))
    root = Tk() #Creating the root widget. There must be and can be only one.
    app = App(root)
    root.mainloop() #Event loops