%% Stage 2: Filter Data and Identify Bad Channels %%
% This script uses EEGLAB and ERPLAB functions to compute and identify ICA components
% that can be used later on for artifact correction. It also does some
% initial preprocessing (filtering, epoching, etc.) that can be useful for future steps.

% The following outlines the steps. Steps with a SAVE indicate those where
% a new EEGLAB .set file is created or another data formation (.mat file)
% is saved. 
%
% Step 1:   Adjust events by photosensor and remove Photosensor channel
% Step 2:   Downsample to 500Hz
%               (SAVE .set)
% Step 3:   Update event marker codes, Create Basic Event List and Binlister the data
% Step 4:   Import channel info using dipfit BESA standard .loc file
%               (SAVE chanlocs to .mat)
% Step 5a:  High-pass filter (1Hz)
%               (SAVE .set)
% Step 5b:  High-pass filter (.1Hz)
%               (SAVE .set)
% Step 6a:  Binepoch 1hz hpf (-500 to 2000 ms, no baseline correction)
%               (SAVE .set)
% Step 6b:  Binepoch .1hz hpf (-500 to 2000 ms, no baseline correction)
%               (SAVE .set)
% Step 7:   Manual Identification of bad epochs (on .1hz hpf data)
% Step 8:   Manually identify/label bad channels
% Step 9:   Run ICA on 1Hz data (after removing epochs and VEOG/HEOG channels, and other bad channels)
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
make_dirs({directories.deriv_eeg});

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
    eeg_file = sprintf('%s_task-study_eeg.set', participant);
    EEG      = pop_loadset( eeg_file, fullfile(par_data_directory,'eeg') );
    
    % Create a 'backup' of the original data
    EEG_orig = EEG; 
            
    %% Step 1: Adjust photosensor (and remove the Photosensor channel)
    % Define options
    cfg = [];
    cfg.events      = {'M  1' 'M  2' 'M  3'}; 
    cfg.channel     = 'Photosensor'; % Channel name
    cfg.threshold   = .85; % Threshold value
    cfg.time_win    = [-.04 .04]; % Extracts data 40 ms before and 40 ms after psensor.events markers
    cfg.frame_rate  = 0;
    cfg.fig_dir     = par_fig_out_directory;
    cfg.draw_trials = false;
    EEG = adjust_events_photosensor( EEG, cfg.events, cfg.channel, cfg.threshold, cfg.time_win, cfg.frame_rate, cfg.fig_dir, cfg.draw_trials ); % CONVERT TO POP FUNCTION
    
    % Save EEG Data
    cfg = [];
    cfg.setname  = 'set01_photosensor_adjust';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    %% Step 2: Resample data to 500Hz
    % Resampling options
    cfg= []; 
    cfg.freq = 500; % New sampling rate
    cfg.fc = .9;  % anti-aliasing filter cutoff (default in pop_resample)
    cfg.df = .2;  % anti-aliasing filter transition bandwidth (default in pop_resample)
    EEG = pop_resample( EEG, cfg.freq, cfg.fc, cfg.df );
    
    % Save EEG Data
    cfg = [];
    cfg.setname  = 'set02_resampled_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    %% Step 3: Update EEG.event type and code fields (for EEGLAB), and make event lists, and run initial binlister
    % Update type fields for EEGLAB
    % Trial type ID numbers
    type_bin = struct( ...
        'ab', 1, ...
        'ac', 2, ...
        'de', 3 );
        
    % Memory bin ID labels
    mem_bin = struct( ...
        'HH2',   'HH', ...
        'HM2',   'HM', ...
        'HM1',   'HM', ...
        'MH2',   'MH', ...
        'MH1',   'MH', ...
        'MM2',   'MM', ...
        'MM1',   'MM', ...
        'MM0',   'MM', ...
        'MISS2', 'MISS', ...
        'H2',    'BAD', ...
        'H1',    'HH', ...
        'M2',    'BAD', ...
        'M1',    'MM', ...
        'M0',    'MM', ...
        'MISS1', 'MISS' );
    
    % Coding the above mem_bin numbreically
    coded_mem_bin = struct( ...
        'HH',   1, ... % Includes HH2 and H1
        'HM',   2, ... % Includes HM2 and HM1
        'MH',   3, ... % Includes MH2 and MH1
        'MM',   4, ... % Includes MM2, MM1, MM0, M1, and M0
        'MISS', 5, ... % Includes MISS2 and MISS1
        'BAD',  99 ... % Includes H2 and M2
        );
    
    % Update EEG.event with new codes
    for evti = 1:length(EEG.event)
        
        % Get the current trial
        cur_event = EEG.event(evti);
        
        % Determine trial type
        this_mem = cur_event.memory_bin;
        mem_label = mem_bin.(this_mem);
        this_type = cur_event.trial_type;
        bad_trial = cur_event.bad_trial_total;
        
        % Update type and code in current trial
        if bad_trial
            cur_event.type    = str2double(sprintf('%d99', type_bin.(this_type)));
        else
            cur_event.type    = str2double(sprintf('%d%d', type_bin.(this_type), coded_mem_bin.(mem_label)));
        end
        
        % Update EEG.event(evti)
        EEG.event(evti) = cur_event;
        
    end
    
    % Create eventlist for ERPLAB
    cfg = [];
    cfg.alphanumclean   = 'on';
    cfg.boundarynumeric = { -99 }; % Must be a cell array of numbers
    cfg.boundarystring  = { 'boundary' }; % must be a cell array of strings
    cfg.eventlist       = fullfile( par_elist_out_directory, 'cont_eeg_type_membin_elist.txt' );
    EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', cfg.alphanumclean, ...
        'BoundaryNumeric', cfg.boundarynumeric, 'BoundaryString', cfg.boundarystring, ...
        'Eventlist', cfg.eventlist ); 
    
    % Run initial binlister
    cfg = [];
    cfg.bdf       = fullfile( directories.spec_files, 'binlister_trialtype_memorybin.txt' );
    cfg.indexEL   = 1; % Use the EEG.EVENTLIST as input
    cfg.sendEL2   = 'EEG'; %Update EEG.EVENTLIST structure
    cfg.updateEEG = 'on'; % Write EEG.EVENTLIST info to EEG.event
    cfg.voutput   = 'EEG'; % Output EEG data structure with EVENTLIST field (not just EVENTLIST field
    cfg.exportEL  = fullfile( par_elist_out_directory, 'cont_eeg_type_membin_elist.txt' ); % Overwrite above file
    EEG  = pop_binlister( EEG , 'BDF', cfg.bdf, 'IndexEL', cfg.indexEL, 'SendEL2', cfg.sendEL2, ...
        'UpdateEEG', cfg.updateEEG, 'Voutput', cfg.voutput, 'ExportEL', cfg.exportEL );
     
    % Import channel info
    % This step uses the standard BESA locations from the dipfit EEGLAB
    % plugin. This will also center the XYZ cartesian coordinates upon
    % importing the locations. These 'original' channel locations are saved
    % in a strcture named chanlocs, and written to a .mat file. This will
    % facilitate channel interpolation later on.
    
    % Add channel locations
    EEG = pop_add_standard_chanlocs( EEG );
    
    % Output EEG.chanlocs to a file
    chanlocs = EEG.chanlocs;
    save( fullfile( par_deriv_out_directory, 'orig_chanlocs.mat' ), 'chanlocs' );
    
    % Save EEG Data
    cfg = [];
    cfg.setname  = 'set03_binlist_resampled_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    % Make a carbon copy of the EEG dataset for running a parallel ICA
    % stream with 1Hz HPF
    EEG_forica = EEG;    
    
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
    cfg.cutoff   = 0.1;
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
    
    % Save CFG for use with ICA
    ica_hpf = cfg;
   
    % Save EEG Data
    cfg = [];
    cfg.setname  = 'set04_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );    
        
    %% Step 5: Run BINEPOCH on the data with whole-epoch baseline correction
    % Run epoching for EEG and EEG_forica sets
    cfg = [];
    cfg.epochwin  = [-500 2000]; % Epoch time window start and end
    cfg.bcopt      = 'all'; % Baseline correction option -- set to 'none' for no baseline correction, 'pre' for prestimulus period, and 'all' for whole epoch baseline correction
    EEG = pop_epochbin( EEG , cfg.epochwin,  cfg.bcopt);
    EEG_forica = pop_epochbin( EEG_forica , cfg.epochwin,  cfg.bcopt);
    
    % Save CFG ofr use with ICA
    ica_binepoch = cfg;
    
    % Save EEG
    cfg = [];
    cfg.setname  = 'set05_binepochs_wholeblc_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );

    %% Step 6: Detect Artifacted Epochs and Bad Channels (using .1HZ HPF data)
    
    % Create a backup of EEG with all channels to re-apply artifacts to
    % after manual inspection
    orig_EEG = EEG;
    
    % Load bad channels
    load( fullfile( par_deriv_out_directory, 'bad_channels.mat' ), 'bad_channels', 'bad_chanids', 'bad_chanlabels' );
    EEG.etc.bad_channels = bad_channels;
    bad_channels.bad_inds = bad_chanids;
    bad_channels.bad_labels = bad_chanlabels;
    
    % Load the preica_marked_epochs
    load( fullfile( par_deriv_out_directory, 'preica_marked_epochs.mat') , 'preica_marked_epochs' );
    
    % Need to syncro artifacts with EEG.EVENTLIST
    cfg = [];
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    
    % Save marked event list
    cfg = [];
    cfg.elname = fullfile( par_elist_out_directory, 'cont_eeg_type_membin_elist.txt' ); % Overwrite existing event_list file
    EEG = pop_exporteegeventlist( EEG, cfg.elname );
    
    % Save EEG
    cfg = [];
    cfg.setname  = 'set06_artmark_binepochs_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );    
    
    %% Step 7: Run ICA and mark components for removal
    % Here, the above is duplicated, but uses a 1Hz HPF. This is optimal
    % for ICA decomposition as it is sensitive to low-frequency noise
    
    % For purpose of easy coding, load in EEG_forica to EEG
    EEG = EEG_forica; % EEG_forica created in Step 3. This set has binepoched
        
    % 1 Hz highpass for ICA on the continuous data with eventlists and
    % binlister
    % Note only cfg.cutoff is changed from the above cfg structure for
    % application of the HPF
    cfg = ica_hpf;
    cfg.cutoff   = 1;
    cfg.order    = 6;
    EEG = pop_basicfilter( EEG, cfg.chans, ...
        'Filter',   cfg.filter, ...
        'Design',   cfg.design, ...
        'Cutoff',   cfg.cutoff, ...
        'Order',    cfg.order, ...
        'RemoveDC', cfg.removedc, ...
        'Boundary', cfg.boundary );     
    
    % Epoch the data (should have the same options as in Step 4)
    cfg = ica_binepoch;
    EEG = pop_epochbin( EEG , cfg.epochwin,  cfg.bcopt);
 
    % Remove bad epochs
    EEG = pop_select(EEG, 'notrial', preica_marked_epochs );
    
    %% Step 8: Run ICA and save it to disk
    % Define options and run pop_runica
    cfg = [];
    cfg.icatype   = 'fastica';
    cfg.approach  = 'symm';
    cfg.g = 'tanh';
    cfg.stabilize = 'on'; % When on, this prevents the algorithm from being stuck between two points
    cfg.chaninds  = find( ~ismember( {EEG.chanlocs.labels}, [bad_channels.bad_labels 'VEOG' 'HEOG'] ) ); % Taken from above, which is a variable written to a .mat file
    
    % Run ICA and sort components
    EEG = pop_runica( EEG, 'icatype', cfg.icatype, 'chanind', cfg.chaninds, ...
        'approach', cfg.approach, 'g', cfg.g, 'stabilization', cfg.stabilize ); 
    
    % Save options
    cfg = [];
    cfg.setname  = 'ica';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );  
    
end