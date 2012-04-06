#cd D:/tools/eerat/python_apps/online_analysis
#import test_gui
from Tkinter import *
from EeratAPI.API import *
from EeratAPI.OnlineAPIExtension import *
from sqlalchemy.orm import *
from sqlalchemy import *


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
            action = lambda x = bb: DatFrame(frame=reset_frame(dat_frame), button_text=x)
            self.btn_dict[bb] = Button(button_frame, text=bb, command=action)
            self.btn_dict[bb].pack(side = TOP, fill = X)
            
class DatFrame:
    def __init__(self, frame=None, button_text=None):
        
        self.button_text = button_text

        #Get the data        
        session = Session()
        self.list_data = session.query(my_button_dict()[button_text]).all()

        #Make a list, and new and delete buttons
        if not frame: frame = Toplevel()
        
        lb={}
        self.lb = lb
        lb['list_frame'] = Frame(frame)
        lb['list_frame'].pack(side = LEFT, fill = Y)
        lb['button_frame'] = Frame(lb['list_frame'])
        lb['button_frame'].pack(side = BOTTOM)
        #Extra frame on right, specific to each class.
        lb['edit_frame'] = Frame(frame)
        lb['edit_frame'].pack(side = RIGHT, fill = Y)
        
        #Label
        lb['label'] = Label (lb['list_frame'], text=button_text)
        lb['label'].pack(side = TOP, fill = X)
        #Scrollbar
        lb['scrollbar'] = Scrollbar(lb['list_frame'])
        lb['scrollbar'].pack(side=RIGHT, fill=Y)
        #Listbox
        lb['lb'] = Listbox(lb['list_frame'], yscrollcommand = lb['scrollbar'].set )
        lb['scrollbar'].config(command=lb['lb'].yview)
        i=0
        for ld in self.list_data:
            lb['lb'].insert(i, ld.Name)
            i=i+1
        lb['lb'].bind("<Double-Button-1>", self.open_item)
        lb['lb'].pack(side = LEFT, fill = BOTH)
        
        #New Button
        lb['new_button'] = Button (lb['button_frame'], text="NEW", command = self.new_item)
        lb['new_button'].pack(side = LEFT, fill = X)
        #Delete Button
        lb['del_button'] = Button (lb['button_frame'], text="DELETE", command = self.del_item)
        lb['del_button'].pack(side = RIGHT, fill = X)
       
    def new_item(self):
        item = my_button_dict()[button_text]()#print "New " + self.button_text
        self.show_item(item)
    def del_item(self):
        curs = self.lb['lb'].curselection()
        for dd in curs:
            instance = self.list_data[int(dd)]
            session = Session.object_session(instance)
            #session.delete(instance)
            print "Disabled: Delete " + instance.Name
    def open_item(self,ev):
        item = self.list_data[int(self.lb['lb'].curselection()[0])]
        self.show_item(item)
    def show_item(self,item):
        EditFrame(frame=reset_frame(self.lb['edit_frame']),item=item)
        
class EditFrame:
    def __init__(self, frame=None, item=None):
        self.item = item
        if not frame: frame=Toplevel()
        self.frame = frame
        
        #Everything has Name
        name_frame = Frame(frame)
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
            desc_frame = Frame(frame)
            desc_frame.pack(side = TOP, fill = X)
            desc_label = Label(desc_frame, text="Description")
            desc_label.pack(side = LEFT)
            desc_var = StringVar(desc_frame)
            desc_var.set(item.Description)
            desc_var.trace("w", lambda name, index, mode, desc_var=desc_var: self.update_description(desc_var))
            desc_entry = Entry(desc_frame, textvariable=desc_var)
            desc_entry.pack(side = RIGHT, fill = X)
            
        if hasattr(item,'DefaultValue'):
            dv_frame = Frame(frame)
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
            
        #TODO: Associations (datum_type_has_feature_type)
            
        #Further attributes require separate frames.
        if hasattr(item, 'DateOfBirth'):
            ss_frame = Frame(frame)
            ss_frame.pack(side = BOTTOM)
            SubjectFrame(frame=ss_frame, item=item)
    
    def update_name(self, name_var):
        self.item.Name = name_var.get()
        #Should flush right away?
                
    def update_description(self, desc_var):
        self.item.Description = desc_var.get()
        #Should flush right away?
        
    def update_defaultvalue(self, dv_var):
        if isinstance(item.DefaultValue,str):
            self.item.DefaultValue = dv_var.get()
        else:
            self.item.DefaultValue = float(dv_var.get())
            
class SubjectFrame:
    def __init__(self, frame=None, item=None):
        self.item = item
        if not frame: frame=Toplevel()
        self.frame = frame
        
        #We already have Name, this is for everything else related to the subject
        #DateOfBirth
        #IsMale
        #Weight
        #Notes
        #species_type (spin)
        
        #periods list (datum_type, Number, IsGood, StartTime, EndTime)
        #new, delete
        #double click loads a new window

#New period window
    #spinner to change datum_type
    #change StartTime and EndTime
    #IsGood
    #Canvas to show ERP (average + up to 100 trials)
    #Button to set ERP window
    #Button to recalculate features
    #Canvas to model erp IO/threshold
    #Maybe mapping if it's the right period type

engine = create_engine("mysql://root@localhost/eerat", echo=False)#echo="debug" gives a ton.
Session = scoped_session(sessionmaker(bind=engine, autocommit=True))
root = Tk() #Creating the root widget. There must be and can be only one.
app = App(root)
root.mainloop() #Event loops