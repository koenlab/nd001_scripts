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

%% Bad Channels for a subject
% User defined bad channels
% Form is sub_<id#>. Channels are entered as name (or label)
user_def_badchans.sub_103 = {'FC3'};
user_def_badchans.sub_108 = {'C5'};
user_def_badchans.sub_109 = {'Cz'};
user_def_badchans.sub_122 = {'Cz'};

%% Add path to EEGLAB and run it (to get full path structure)
eeglab; 

%% Define main directories
% Directories
directories.top        = 'X:\EXPT\nd001\exp1\data';
directories.source     = fullfile(directories.top, 'sourcedata');
directories.derivative = fullfile(directories.top, 'derivatives');
directories.deriv_eeg  = fullfile(directories.derivative, 'eeg');
directories.spec_files = fullfile(directories.top, 'scripts', 'spec_files'); % Where specification files are stored
% make_dirs({directories.deriv_eeg});

%% Run the participant selector
% Run participant selector GUI
participant_list       = participant_selector(directories.top);

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 0: Get some general information defined and load data
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Print info to screen
    fprintf('Preprocessing data for %s:\n',participant);
    
    % Make directory structure in data
    par_data_directory      = fullfile( directories.top, participant );
    par_data_beh_directory  = fullfile( par_data_directory, 'beh' );
    par_data_eeg_directory  = fullfile( par_data_directory, 'eeg' );
    par_deriv_out_directory = fullfile( directories.deriv_eeg, 'task-study', participant );
    par_fig_out_directory   = fullfile( par_deriv_out_directory, 'figures' );
    par_sets_out_directory  = fullfile( par_deriv_out_directory, 'eeglab_sets' );
    par_erps_out_directory  = fullfile( par_deriv_out_directory, 'erplab_sets' );
    par_elist_out_directory = fullfile( par_erps_out_directory, 'event_lists' );
    make_dirs({par_deriv_out_directory par_fig_out_directory par_sets_out_directory par_erps_out_directory par_elist_out_directory par_sets_out_directory});
    
    % Load EEG set file
    EEG      = pop_loadset( 'set03_binlist_resampled_500Hz.set', par_sets_out_directory );
    
    % Create a 'backup' of the original data
    EEG_orig = EEG; 
            
    %% Step 4: HPF Filter continuous EEG data
    % HIGHPASS FILTER - We are performing a high pass filter on the
    % continuous EEG data using a zero-phase shift butterworth filter.
    % Although boundary events are set, there should be none, so the
    % warning can be ignored. 
    
    % 0.1 Hz highpass for ERP computation       
    cfg = [];
    cfg.chans    = 1:EEG.nbchan; % Apply to all channels
    cfg.filter   = 'highpass';
    cfg.design   = 'butter';
    cfg.cutoff   = 0.01;
    cfg.order    = 4;
    cfg.removedc = 'on';
    cfg.boundary = -99;
    EEG = pop_basicfilter( EEG, cfg.chans, ...
        'Filter',   cfg.filter, ...
        'Design',  cfg.design, ...
        'Cutoff',   cfg.cutoff, ...
        'Order',    cfg.order, ...
        'RemoveDC', cfg.removedc, ...
        'Boundary', cfg.boundary );     
    
    %% Step 5: Run BINEPOCH on the data with whole-epoch baseline correction
    % Run epoching for EEG and EEG_forica sets
    cfg = [];
    cfg.epochwin  = [-500 2000]; % Epoch time window start and end
    cfg.bcopt      = 'all'; % Baseline correction option -- set to 'none' for no baseline correction, 'pre' for prestimulus period, and 'all' for whole epoch baseline correction
    EEG = pop_epochbin( EEG , cfg.epochwin,  cfg.bcopt);
    
    %% Step 10: Apply IC results to 0.01 Hz Data and interpolate bad channels (if missing)
    % Load bad channels
    load( fullfile( par_deriv_out_directory, 'bad_channels.mat') );
    EEG.etc.bad_channels = bad_channels; 
    
    % Load ICA and information to loaded .01 Hz filtered data
    load( fullfile( par_deriv_out_directory, 'ica_data_output.mat' ) );
    EEG.icasphere = icasphere;
    EEG.icaweights = icaweights;
    EEG.icachansind = find( ~ismember({EEG.chanlocs.labels}, [EEG.etc.bad_channels.bad_labels 'VEOG' 'HEOG']) );
    EEG.reject.gcompreject = bad_ic_vector;
    EEG = eeg_checkset(EEG);
    
    % Gather reject structure
    this_reject = EEG.reject;
    this_reject.gcompreject = [];
    
    % Subtract bad ICA components (rejects components in
    % EEG.reject.gcompreject).
    EEG = pop_subcomp(EEG, [], 0);
    
    % Interpolate channels. Add in rejection marks manual.
    if ~isempty(EEG.etc.bad_channels.bad_inds)
        EOG = pop_select(EEG, 'channel', {'VEOG' 'HEOG'});
        EEG = pop_select(EEG, 'nochannel', {'VEOG' 'HEOG'});
        EEG = pop_interp(EEG, EEG.etc.bad_channels.bad_inds, 'spherical');
        EEG.data = cat(1, EEG.data, EOG.data);
        EEG.chanlocs = cat(2, EEG.chanlocs, EOG.chanlocs);
        EEG.nbchan = size(EEG.data,1); 
    else
        fprintf('No channels need to be interpolated.\n');
    end
    EEG.icawinv = [];
    EEG.icasphere = [];
    EEG.icaweights = [];
    EEG.icachansind = [];
    EEG.reject = this_reject;
    
    %% Step 11: Re-reference to average and add channel locations
    % Perform mastoid rereference using ERPLAB function
    chanop_file = fullfile(directories.spec_files, 'chanops_eeg_reref_average.txt');
    EEG = pop_eegchanoperator( EEG, chanop_file );
    
    % Add back in channel locations
    EEG = pop_add_standard_chanlocs( EEG );
    
    %% Step 12: Pre-stimulus baseline correction
    % Use pop_rmbase to correct pre-stimulus baseline
    cfg = [];
    cfg.baseline_time  = [-250 0]; % Epoch time window start and end
    EEG = pop_rmbase( EEG , cfg.baseline_time );
    
    %% Step ##: Mark prior artifacts
    % Load postica_art_epochs
    load(fullfile( par_deriv_out_directory, 'postica_art_epochs.mat' ))
    EEG.reject.rejmanual = false(1,EEG.trials);
    EEG.reject.rejmanualE = false(EEG.nbchan, EEG.trials);
    EEG.reject.rejmanual(postica_art_epochs) = true;
    
    % Sync Artifacts for verification
    cfg = [];
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    pop_summary_AR_eeg_detection(EEG,''); % This prints it to the screen
    
    % Remove bad file
    bad_file = fullfile(par_sets_out_directory, 'set12_goodepochs_pre250blc_avgref_0.01hzhpf_500Hz.set' );
    if exist(bad_file,'file')
        delete(bad_file);
    end
        
    % Save the set
    cfg = [];
    cfg.setname  = 'set12_goodepochs_pre250blc_avgref_0.01hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
end