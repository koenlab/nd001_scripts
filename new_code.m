   '
     EEG.etc.eeglabvers = '2019.0'; % this tracks which version of EEGLAB is being used, you may ignore it
     EEG = pop_loadset('filename','sub-101_task-study_eeg.set','filepath','X:\\EXPT\\nd001\\exp1\\data\\sub-101\\eeg\\');
     EEG = eeg_checkset( EEG );
     EEG = adjust_events_photosensor( EEG, {'M  1' 'M  2' 'M  3'  },  66, 10, [-40  40] );
     EEG = eeg_checkset( EEG );
     EEG = pop_resample( EEG, 250);
     EEG = eeg_checkset( EEG );
     EEG = pop_saveset( EEG, 'filename','resampled_500hz.set','filepath','X:\\EXPT\\nd001\\exp1\\data\\derivatives\\eeg\\task-study\\sub-101\\eeglab_sets\\');
     EEG = eeg_checkset( EEG );
     pop_eegplot( EEG, 1, 1, 1);
     pop_eegplot( EEG, 1, 1, 1);
     EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'BoundaryNumeric', { -99 }, 'BoundaryString', { 'boundary' }, 'Eventlist', 'X:\EXPT\nd001\exp1\data\derivatives\eeg\task-study\sub-101\event_lists\trialtype_memory_curtask_elist.txt' ); % GUI: 03-Sep-2019 14:34:15
     EEG = eeg_checkset( EEG );
     EEG = eeg_checkset( EEG );
     EEG  = pop_binlister( EEG , 'BDF', 'X:\EXPT\nd001\exp1\data\scripts\trialtype_memory_curtask_binlister.txt', 'IndexEL',  1, 'SendEL2', 'EEG', 'UpdateEEG', 'on', 'Voutput', 'EEG' ); % GUI: 03-Sep-2019 14:40:50
     EEG = eeg_checkset( EEG );
     EEG  = pop_basicfilter( EEG,  1:65 , 'Boundary', 'boundary', 'Cutoff',  1, 'Design', 'butter', 'Filter', 'highpass', 'Order',  4, 'RemoveDC', 'on' ); % GUI: 03-Sep-2019 14:45:05
     EEG = eeg_checkset( EEG );
     EEG = pop_epochbin( EEG , [-500.0  2000.0],  'none'); % GUI: 03-Sep-2019 14:46:47
     EEG = eeg_checkset( EEG );
     pop_eegplot( EEG, 1, 1, 1);
     EEG = eeg_checkset( EEG );
     EEG = pop_runica(EEG, 'icatype', 'runica', 'extended',1, 'interrupt','on', 'chanind', 1:length(EEG.nbchan)-2);
     % Save icaact, icawinv, icasphere, icaweights, icachansind, to a .mat file labeled ica_results
     % A
     EEG = eeg_checkset( EEG );
     EEG = pop_iclabel(EEG, default);
     % Save EEG.reject.gcompreject to a .mat file labeled ica_artifact_ics
     % (variable is bad_ics)
     EEG = eeg_checkset( EEG );
     pop_selectcomps(EEG, [1:5] );
     EEG = eeg_checkset( EEG );
     EEG = pop_subcomp( EEG, [1], 0);
     EEG = eeg_checkset( EEG );
     EEG = eeg_checkset( EEG );
     EEG = pop_eegchanoperator( EEG, {  'nch1 = ch1 - ( (ch10 + ch21) / 2 ) Label Fp1',  'nch2 = ch2 - ( (ch10 + ch21) / 2 ) Label Fz',  'nch3 = ch3 - ( (ch10 + ch21) / 2 ) Label F3',  'nch4 = ch4 - ( (ch10 + ch21) / 2 ) Label F7',  'nch5 = ch5 - ( (ch10 + ch21) / 2 ) Label FT9',  'nch6 = ch6 - ( (ch10 + ch21) / 2 ) Label FC5',  'nch7 = ch7 - ( (ch10 + ch21) / 2 ) Label FC1',  'nch8 = ch8 - ( (ch10 + ch21) / 2 ) Label C3',  'nch9 = ch9 - ( (ch10 + ch21) / 2 ) Label T7',  'nch10 = ch10 - ( (ch10 + ch21) / 2 ) Label TP9',  'nch11 = ch11 - ( (ch10 + ch21) / 2 ) Label CP5',  'nch12 = ch12 - ( (ch10 + ch21) / 2 ) Label CP1',  'nch13 = ch13 - ( (ch10 + ch21) / 2 ) Label Pz',  'nch14 = ch14 - ( (ch10 + ch21) / 2 ) Label P3',  'nch15 = ch15 - ( (ch10 + ch21) / 2 ) Label P7',  'nch16 = ch16 - ( (ch10 + ch21) / 2 ) Label O1',  'nch17 = ch17 - ( (ch10 + ch21) / 2 ) Label Oz',  'nch18 = ch18 - ( (ch10 + ch21) / 2 ) Label O2',  'nch19 = ch19 - ( (ch10 + ch21) / 2 ) Label P4',  'nch20 = ch20 - ( (ch10 + ch21) / 2 ) Label P8',  'nch21 = ch21 - ( (ch10 + ch21) / 2 ) Label TP10',  'nch22 = ch22 - ( (ch10 + ch21) / 2 ) Label CP6',  'nch23 = ch23 - ( (ch10 + ch21) / 2 ) Label CP2',  'nch24 = ch24 - ( (ch10 + ch21) / 2 ) Label Cz',  'nch25 = ch25 - ( (ch10 + ch21) / 2 ) Label C4',  'nch26 = ch26 - ( (ch10 + ch21) / 2 ) Label T8',  'nch27 = ch27 - ( (ch10 + ch21) / 2 ) Label FT10',  'nch28 = ch28 - ( (ch10 + ch21) / 2 ) Label FC6',  'nch29 = ch29 - ( (ch10 + ch21) / 2 ) Label FC2',  'nch30 = ch30 - ( (ch10 + ch21) / 2 ) Label F4',  'nch31 = ch31 - ( (ch10 + ch21) / 2 ) Label F8',  'nch32 = ch32 - ( (ch10 + ch21) / 2 ) Label Fp2',  'nch33 = ch33 - ( (ch10 + ch21) / 2 ) Label AF7',  'nch34 = ch34 - ( (ch10 + ch21) / 2 ) Label AF3',  'nch35 = ch35 - ( (ch10 + ch21) / 2 ) Label AFz',  'nch36 = ch36 - ( (ch10 + ch21) / 2 ) Label F1',  'nch37 = ch37 - ( (ch10 + ch21) / 2 ) Label F5',  'nch38 = ch38 - ( (ch10 + ch21) / 2 ) Label FT7',  'nch39 = ch39 - ( (ch10 + ch21) / 2 ) Label FC3',  'nch40 = ch40 - ( (ch10 + ch21) / 2 ) Label C1',  'nch41 = ch41 - ( (ch10 + ch21) / 2 ) Label C5',  'nch42 = ch42 - ( (ch10 + ch21) / 2 ) Label TP7',  'nch43 = ch43 - ( (ch10 + ch21) / 2 ) Label CP3',  'nch44 = ch44 - ( (ch10 + ch21) / 2 ) Label P1',  'nch45 = ch45 - ( (ch10 + ch21) / 2 ) Label P5',  'nch46 = ch46 - ( (ch10 + ch21) / 2 ) Label PO7',  'nch47 = ch47 - ( (ch10 + ch21) / 2 ) Label PO3',  'nch48 = ch48 - ( (ch10 + ch21) / 2 ) Label POz',  'nch49 = ch49 - ( (ch10 + ch21) / 2 ) Label PO4',  'nch50 = ch50 - ( (ch10 + ch21) / 2 ) Label PO8',  'nch51 = ch51 - ( (ch10 + ch21) / 2 ) Label P6',  'nch52 = ch52 - ( (ch10 + ch21) / 2 ) Label P2',  'nch53 = ch53 - ( (ch10 + ch21) / 2 ) Label CPz',  'nch54 = ch54 - ( (ch10 + ch21) / 2 ) Label CP4',  'nch55 = ch55 - ( (ch10 + ch21) / 2 ) Label TP8',  'nch56 = ch56 - ( (ch10 + ch21) / 2 ) Label C6',  'nch57 = ch57 - ( (ch10 + ch21) / 2 ) Label C2',  'nch58 = ch58 - ( (ch10 + ch21) / 2 ) Label FC4',  'nch59 = ch59 - ( (ch10 + ch21) / 2 ) Label FT8',  'nch60 = ch60 - ( (ch10 + ch21) / 2 ) Label F6',  'nch61 = ch61 - ( (ch10 + ch21) / 2 ) Label AF8',  'nch62 = ch62 - ( (ch10 + ch21) / 2 ) Label AF4',  'nch63 = ch63 - ( (ch10 + ch21) / 2 ) Label F2',  'nch64 = - ( (ch10 + ch21) / 2 ) Label FCz',  'nch65 = ch64 Label VEOG',  'nch66 = ch65 Label HEOG'} , 'ErrorMsg', 'popup', 'Warning', 'on' ); % GUI: 03-Sep-2019 14:58:24
     EEG = eeg_checkset( EEG );
     pop_eegplot( EEG, 1, 1, 1);
     EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\jkoen\\Documents\\MATLAB\\eeglab2019_0\\plugins\\dipfit3.2\\standard_BESA\\standard-10-5-cap385.elp');
     EEG = eeg_checkset( EEG );
     pop_eegplot( EEG, 1, 1, 1);'