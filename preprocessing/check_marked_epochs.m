%% Stage 2: Pre-Processing of Raw EEG Data %%
% This script uses EEGLAB and ERPLAB functions to perform initial preprocessing
% (filtering, epoching, etc.) and compute and identify ICA components. The
% output is a "cleaned" 0.1Hz HPF dataset with bad channels, epochs, and
% components removed/marked

% The following outlines the steps. Steps with a SAVE indicate those where
% a new EEGLAB .set file is created or another data formation (.mat file)
% is saved. 
%
% Step 1:   Adjust events by photosensor and remove Photosensor channel
% Step 2:   Downsample to 500Hz
%               (SAVE .set)
% Step 3:   Update event marker codes, Create Basic Event List, Binlister the data, add channel locations
%               (SAVE .set)
% Step 4:   HPF (0.1Hz) continuous EEG data
%               (SAVE .set)
% Step 5:  Run BINEPOCH on the data with whole-epoch baseline correction
%               (SAVE .set)
% Step 6:  Detect Artifacted Epochs and Bad Channels (using .1HZ HPF data)
%               (SAVE .set and preica_marked_epochs)
% Step 7:   Prepare dataset for ICA - load re-sampled data, then: 1Hz HPF, binepoch, remove bad epochs
% Step 8:   Run FastICA on 1Hz data and save it to disk
%               (SAVE .set)
% Step 9:   Run ICLabel and ID Bad Components manually
%               (OVERWRITE ica.set and save ica components)
% Step 10:  Apply IC results to 0.1 Hz Data and interpolate bad channels 
%               (SAVE .set)
% Step 11: Re-reference to average and add channel locations
%               (SAVE .set)
% Step 12: Pre-stimulus baseline correction
%               (SAVE .set)
% Step 13: Final round of artifact detection (min-max, manual detection)
%               (SAVE .set)

%% Clear the workspace
clear all;
clc;

%% Add path to EEGLAB and run it (to get full path structure)
eeglab; 

%% Define main directories
% Directories
directories.top         = 'X:\EXPT\nd001\exp1\data';
directories.raw         = fullfile(directories.top, 'raw_bids');
directories.source      = fullfile(directories.raw, 'sourcedata');
directories.preproc     = fullfile(directories.top, 'preprocessed', 'task-study');
directories.preproc_beh = fullfile(directories.preproc, 'beh');
directories.preproc_eeg = fullfile(directories.preproc, 'eeg');
directories.scripts     = fullfile(directories.top, 'scripts');
directories.spec_files  = fullfile(directories.scripts, 'spec_files'); % Where specification files are stored
directories.functions   = fullfile(directories.scripts, 'functions');
make_dirs({directories.preproc directories.preproc_beh directories.preproc_eeg});

% Add directories.functions to path
addpath(directories.functions);

%% Run the participant selector
% Run participant selector GUI
participant_list       = participant_selector( directories.source );

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 0: Get some general information defined and load data
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Print info to screen
    fprintf('Preprocessing data for %s:\n',participant);
    
    % Make directory structure in data
    par_data_dir        = fullfile( directories.raw, participant );
    par_data_beh_dir    = fullfile( par_data_dir, 'beh' );
    par_data_eeg_dir    = fullfile( par_data_dir, 'eeg' );
    par_preproc_out_dir = fullfile( directories.preproc_eeg, participant );
    par_fig_out_dir     = fullfile( par_preproc_out_dir, 'figures' );
    par_sets_out_dir    = fullfile( par_preproc_out_dir, 'eeglab_sets' );
    par_erps_out_dir    = fullfile( par_preproc_out_dir, 'erplab_sets' );
    par_elist_out_dir   = fullfile( par_preproc_out_dir, 'event_lists' );
    
    % Load EEG set file
    eeg_file = 'set09_pre200blc_avgref_icacleaned_binepochs_0.05-100bpf_500Hz.set';
    EEG      = pop_loadset( eeg_file, par_sets_out_dir );
    
    % Load postica artifacts
    load(fullfile(par_preproc_out_dir,'postica_art_epochs.mat'));
    
    %% Step 13: Final round of artifact detection
    % Inspect previously marked epochs and remove marking
    % if they are "good" now. Also remove any epochs that have come up
    % as "bad" after removing ICs. Then do automatic algorithm for min-max
    % extreme value correction, linear drift, peak-2-peak.
    
    % Min-Max Voltage
    cfg = [];
    cfg.channel = find( ~ismember( {EEG.chanlocs.labels}, {'VEOG' 'HEOG'} ) );
    cfg.threshold = [-100 100];
    cfg.flag = 2;
    EEG = pop_artextval( EEG, 'Channel', cfg.channel, 'Flag', cfg.flag, 'Threshold', cfg.threshold);
    
    % Peak-2-Peak
    cfg = [];
    cfg.flag = 4;
    cfg.twindow = [-500 1998];
    cfg.threshold = 150;
    cfg.windowsize = 200;
    cfg.windowstep = 50;
    cfg.channel = find( ~ismember( {EEG.chanlocs.labels}, {'VEOG' 'HEOG'} ) );
    EEG = pop_artmwppth( EEG, ...
        'Twindow', cfg.twindow, ...
        'Threshold', cfg.threshold, ...
        'Windowsize', cfg.windowsize, ...
        'Windowstep', cfg.windowstep, ...
        'Channel', cfg.channel, ...
        'Flag', cfg.flag );
    
    % Add other post-ica artifact flags
    EEG.reject.rejmanual(postica_art_epochs) = true;
    
    % Do a final round of manual inspection
    while true

        % Try pop_eegplot (while loop needed) for second round of manual
        % inspection... 
        
        pop_eegplot( EEG, 1, 1, 0 );
        waitfor( findobj('parent', gcf, 'string', 'UPDATE MARKS'), 'userdata');

        % Ask if we are OK with results
        clear_bads = questdlg('Are you done marking epochs (click No if you need to mark more)?');
        if strcmpi(clear_bads,'yes')
            break;
        else
            continue; %if user wants to re-inspect the epochs again, continue to the next iteration of th while loop and run pop_eegplot again
        end
        
    end
    
    % Sync Artifacts for verification
    cfg = [];
    cfg.direction = 'eeglab2erplab';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    
    % Gather the postica rejected epochs
    postica_art_epochs = find(EEG.reject.rejmanual);

    % Save the EEG.etc.bad_channels structure to a file
    save( fullfile( par_preproc_out_dir, 'postica_art_epochs.mat' ), 'postica_art_epochs' );
    
    % Export EVENTLIST to a file in elist
    EEG = pop_exporteegeventlist( EEG , 'Filename', fullfile( par_elist_out_dir, 'erp_good_epochs_elist.txt' ));
    
    % Save the set
    cfg = [];
    cfg.setname  = 'set10_goodepochs_pre200blc_avgref_0.05-100bpf_500Hz';
    cfg.path     = par_sets_out_dir;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    %% Step 14: Re-reference to mastoid and add channel locations
    % Perform mastoid rereference using ERPLAB function
    chanop_file = fullfile(directories.spec_files, 'chanops_eeg_reref_linked_mastoid.txt');
    EEG = pop_eegchanoperator( EEG, chanop_file );
    
    % Add back in channel locations
    EEG = pop_add_standard_chanlocs( EEG );
    
    % Save the set
    cfg = [];
    cfg.setname  = 'set11_goodepochs_pre200blc_mastoidref_0.05-100bpf_500Hz';
    cfg.path     = par_sets_out_dir;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
        
end