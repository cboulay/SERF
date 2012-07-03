%Ch labels
channel_labels{1}={'FC3','C5.','C3.','C1.','CP3','FCz','C1.','Cz.','C2.','CPz','FC4','C2.','C4.','C6.','CP4','trigger'};
channel_labels{2}={'trigger','FC3','C5.','C3.','C1.','CP3','FC4','C2.','C4.','C6.','CP4','EMG1','EMG2'};
channel_labels{3}={'trigger','FC3','C5.','C3.','C1.','CP3','FC4','C2.','C4.','C6.','CP4'};
channel_labels{4}={'trigger','FC3','C5.','C3.','C1.','CP3','FCz','C1.','Cz.','C2.','CPz','FC4','C2.','C4.','C6.','CP4'};
%trigger 0 is rest, 1 is imagery
%If the data have EMG (2), then samplerate is 1200. Else it is 256.

%Sometimes there is a file called name_parameter.mat (e.g. name is test1)
%which has a variable called nonuseTrial indicating trials to exclude.
%Most of the time there is also a .txt file indicating whether imagery was
%L or R.
%subject_info
ss=0;

ss=ss+1;
subject_info(ss).Name='A';
subject_info(ss).imagery_hand='L';
subject_info(ss).base_dir='Z:\BMIProject\visual_fb\2008\SubA\EEG\';
dd=0;
% dd=dd+1;
% subject_info(ss).day(dd).folder='090209';
% subject_info(ss).day(dd).file_names={'Lhand174859';'Lhand175454'};
dd=dd+1;
subject_info(ss).day(dd).folder='090210';
subject_info(ss).day(dd).file_names={'test1';'test2';'test3';'test4'};
dd=dd+1;
subject_info(ss).day(dd).folder='090211';
subject_info(ss).day(dd).file_names={'test1';'test2'};
dd=dd+1;
subject_info(ss).day(dd).folder='090212';
subject_info(ss).day(dd).file_names={'test1';'test2';'test3';'test4'};
dd=dd+1;
subject_info(ss).day(dd).folder='090213';
subject_info(ss).day(dd).file_names={'test1';'test2'};%'Lhand171521';'Lhand172112';
dd=dd+1;
subject_info(ss).day(dd).folder='090216';
subject_info(ss).day(dd).file_names={'16-Feb-2009'};
dd=dd+1;
subject_info(ss).day(dd).folder='090217';
subject_info(ss).day(dd).file_names={'17-Feb-2009'};
dd=dd+1;
subject_info(ss).day(dd).folder='090218';
subject_info(ss).day(dd).file_names={'test1';'test2';'test3';'test4'};
dd=dd+1;
subject_info(ss).day(dd).folder='090219';
subject_info(ss).day(dd).file_names={'test1';'test2';'test3';'test4';'test5';'test6'};
% dd=dd+1;
% subject_info(ss).day(dd).folder='090220';
% subject_info(ss).day(dd).file_names={'Lhand173318';'Lhand174218';'Lhand174851';'Other172716';'Rhand173639';'test6'};
dd=dd+1;
subject_info(ss).day(dd).folder='090224';
subject_info(ss).day(dd).file_names={'test1';'test2';'test3';'test4';'test5'};
dd=dd+1;
subject_info(ss).day(dd).folder='090225';
subject_info(ss).day(dd).file_names={'test1';'test2';'test3';'test4';'test5'};
% dd=dd+1;
% subject_info(ss).day(dd).folder='090226';
% subject_info(ss).day(dd).file_names={'Lhand172949';'Lhand173519';'Lhand174919';'Lhand174052'};

ss=ss+1;
subject_info(ss).Name='B';
subject_info(ss).imagery_hand='L';
subject_info(ss).base_dir='Z:\BMIProject\visual_fb\2009\SubB\EEG\';
dd=0;
% dd=dd+1;
% subject_info(ss).day(dd).folder='090624'; %No task instruction.
% subject_info(ss).day(dd).file_names={'LHandImage1';'LHandImage2';'LHandImage3'};
dd=dd+1;
subject_info(ss).day(dd).folder='090625';
subject_info(ss).day(dd).file_names={'LeftImage1';'LeftImage2';'LeftImage3'};
dd=dd+1;
subject_info(ss).day(dd).folder='090629';
subject_info(ss).day(dd).file_names={'LeftImage1';'LeftImage2'};
dd=dd+1;
subject_info(ss).day(dd).folder='090630';
subject_info(ss).day(dd).file_names={'LeftImage'};
dd=dd+1;
subject_info(ss).day(dd).folder='090701';
subject_info(ss).day(dd).file_names={'LeftImage1';'LeftImage2';'LeftImage3';'LeftImage4';'LeftImage5'};
dd=dd+1;
subject_info(ss).day(dd).folder='090702';
subject_info(ss).day(dd).file_names={'02-Jul-2009'};
dd=dd+1;
subject_info(ss).day(dd).folder='090706';
subject_info(ss).day(dd).file_names={'LeftImage1';'LeftImage2';'LeftImage3'};
dd=dd+1;
subject_info(ss).day(dd).folder='090707';
subject_info(ss).day(dd).file_names={'LeftImage1';'LeftImage2';'LeftImage3'};
dd=dd+1;
subject_info(ss).day(dd).folder='090708';
subject_info(ss).day(dd).file_names={'LeftImage1';'LeftImage2';'LeftImage3';'LeftImage4'};

ss=ss+1;
subject_info(ss).Name='C';
subject_info(ss).imagery_hand='L';
subject_info(ss).base_dir='Z:\BMIProject\visual_fb\2009\SubC\eeg\';
dd=0;
% dd=dd+1;
% subject_info(ss).day(dd).folder='091104';
% subject_info(ss).day(dd).file_names={'image1'};%No class

clear ss