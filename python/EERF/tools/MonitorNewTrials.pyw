import matplotlib
matplotlib.use('TkAgg')
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2TkAgg
from matplotlib.figure import Figure
from Tkinter import *
from EeratAPI.API import *
from OnlineAPIExtension import *
from sqlalchemy import desc

class App:
    def __init__(self, master):
        
        #master is the root
        self.frame = master
        plot_frame=Frame(self.frame)
        plot_frame.pack(side=TOP, fill=X)
        pb_frame = Frame(self.frame)
        pb_frame.pack(side=TOP, fill=X)
        
        self.fig = Figure()
        canvas = FigureCanvasTkAgg(self.fig, master=plot_frame)
        canvas.show()
        canvas.get_tk_widget().pack(side=TOP, fill=BOTH, expand=1)
        toolbar = NavigationToolbar2TkAgg( canvas, plot_frame )
        toolbar.update()
        canvas._tkcanvas.pack(side=TOP, fill=BOTH, expand=1)
        
        last_trial = Session.query(Datum).filter(Datum.span_type=='trial').order_by(Datum.datum_id.desc()).first()
        self.last_id = last_trial.datum_id if last_trial else None
        self.update_plot()
        
    def update_plot(self):
        last_trial = Session.query(Datum).filter(Datum.span_type=='trial', Datum.datum_id>self.last_id).order_by(Datum.datum_id.desc()).first()
        if last_trial and not last_trial.store['channel_labels'] is None: #If new trial, add the trial to the plot
            tr_store=last_trial.store
            fig = self.fig
            #my_ax = fig.gca()
            #my_ax.clear()
            #my_ax = fig.add_subplot(111)
            #chans_list = [tdv for tdv in last_trial.detail_values.itervalues() if tdv in tr_store['channel_labels']]
            #chans_list = list(set(chans_list))#make unique
            #Boolean array to index the data.
            #chan_bool = np.array([cl in chans_list for cl in tr_store['channel_labels']])
            
            x = tr_store['x_vec']
            y = tr_store['data']
            
            if not isinstance(y,basestring):
                nchans = np.size(tr_store['channel_labels'])
                for cc in range(0,nchans):
                    y[cc,:]=y[cc,:]-np.mean(y[cc,x<-5])
                x_bool = np.logical_and(x>=-10,x<=100)
                x=x[x_bool]
                #y=y[chan_bool,x_bool]
                y=y[:,x_bool]
                
                
                naxes = np.size(fig.axes)
                while naxes<nchans:
                    fig.add_subplot(nchans,1,naxes+1)
                    naxes=np.size(fig.axes)
                    
                for cc in range(0,nchans):
                    this_ax = fig.axes[cc]
                    this_ax.lines = this_ax.lines[-4:]
                    this_ax.plot(x,y[cc,:].T)
                    y_max = -1*np.inf
                    y_min = np.inf
                    for ll in this_ax.lines:
                        ll.set_linewidth(0.5)
                        temp_data = ll.get_ydata()
                        y_min = min(y_min, min(temp_data[x>=4]))
                        y_max = max(y_max, max(temp_data[x>=4]))
                    this_ax.lines[-1].set_linewidth(3.0)
                    #TODO: Scale y-axis to be +/- 10% around displayed trials (excluding stim artifact)
                    y_margin = 0.1 * np.abs((y_max - y_min))
                    this_ax.set_ylim(y_min-y_margin,y_max+y_margin)
                    if cc==nchans-1:this_ax.set_xlabel('TIME AFTER STIM (ms)')
                    this_ax.set_ylabel('AMPLITUDE (uv)')
                    this_ax.set_title(tr_store['channel_labels'][cc])
                #fig.tight_layout() #tight_layout shrinks the plots
                fig.canvas.draw()
                self.last_id = last_trial.datum_id
        
        self.frame.after(500, self.update_plot)
        
if __name__ == "__main__":
    #engine = create_engine("mysql://root@localhost/eerat", echo=False)#echo="debug" gives a ton.
    #Session = scoped_session(sessionmaker(bind=engine, autocommit=True))
    root = Tk() #Creating the root widget. There must be and can be only one.
    app = App(root)
    root.mainloop() #Event loops