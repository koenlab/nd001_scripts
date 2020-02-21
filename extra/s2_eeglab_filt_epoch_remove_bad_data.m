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
        
        % Fix for boundary event in middle of EEG.event structure
        if isempty(cur_event.memory_bin)
            continue
        end
        
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
    % This step is where we determine any bad channels or artifacted epochs. 
    % Part 1 invokes the mark_bad_channels function to plot the frequency spectrum and
    % potentially identify bad channels from that figure. Part 2 removes
    % any bad channels that have been marked from either the frequency
    % spectrum or because they were known to be bad from online data
    % collection notes. Part 3 plots the EEG scrolling data to allow for
    % visual inspection of the data for the user to manually mark/flag any
    % artifacted epochs. If, during manual inspection, the user determines
    % that a channel is bad and needs to be removed, the user can specify
    % that. If the user needs to go back and re-do epoch inspection
    % following the removal of a bad channel, the script allows for that to
    % occur and re-write the marks. The final set of bad channels and bad
    % epochs are saved and synchronized with eventlist. Part 4 removes the
    % bad epochs from the 1Hz high-pass data (for ICA) and saves that set.
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%% PART 1 START %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Look at frequency spectrum to potentially identify bad channels and
    % mark 'known' bad channels for removal
    
    % Set configurations for first round of bad channel detection
    cfg = [];
    cfg.chan_inds       = 1:EEG.nbchan;
    cfg.fig_dir         = par_fig_out_directory;
    cfg.plot_freq_spect = 'yes';
    cfg.plot_EEG_scroll = 'no';

    % Gather from user defined bad channels, then run
    % mark_bad_channels() to plot frequency spectrum. After the frequency
    % spectrum is manually inspected and the figure is closed, two
    % questions will pop up for the user. The first question asks if you
    % need to mark any additional channels as bad and the second question
    % asks if you need to unmark any channels currently marked as bad
    
    % Get the participant field name (through string manipulation) to index
    % user_def_badchans structure. This sets the cfg.badchans input
    par_field = strrep(participant,'-','_');
    if isfield(user_def_badchans, par_field )
        cfg.badchans = find( ismember( {EEG.chanlocs.labels}, user_def_badchans.(par_field) ) );
    else
        cfg.badchans = [];
    end
    
    % Run the mark bad channels function
    EEG = mark_bad_channels(EEG, cfg);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%  PART 1 END  %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%% PART 2 START %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Create a backup of EEG with all channels to re-apply artifacts to
    % after manual inspection
    orig_EEG = EEG;
    
    % Remove any bad channels that have been marked
    % This is done to avoid rejecting EPOCHs based on bad channels. 
    if ~isempty(EEG.etc.bad_channels.bad_labels)
        EEG = pop_select( EEG, 'nochannel', EEG.etc.bad_channels.bad_labels );
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%  PART 2 END  %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%% PART 3 START %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Mark artifacts via visual inspection. Then, if needed, remove any
    % other channels and redo it all
    while true
        
        % Call function to manually flag artifacts. This will open a
        % scrolling EEG window for the user to manually mark bad artifacts.
        pop_eegplot( EEG, 1, 1, 0, [] );
        waitfor( findobj('parent', gcf, 'string', 'UPDATE MARKS' ), 'userdata');
        preica_marked_epochs = find(EEG.reject.rejmanual);
        
        % Second round of channel removal, if necessary
        more_bad_chans = questdlg('Do you need to remove any additional channels that were noticed during epoch inspection?');
        if strcmpi(more_bad_chans,'yes')
            
            % Re-ask for bad channels
            cfg = [];
            cfg.chan_inds = 1:orig_EEG.nbchan;
            cfg.badchans  = orig_EEG.etc.bad_channels.bad_inds;
            orig_EEG = mark_bad_channels(orig_EEG, cfg);
            
        end
        
        % Ask if we are OK with results
        clear_bads = questdlg('Are you done marking epochs (click No if you need to mark more)?');
        if strcmpi(clear_bads,'yes')
            
            % Re-establish orig_EEG with updates
            EEG = orig_EEG;
            EEG.reject.rejmanual = false(1,EEG.trials);
            EEG.reject.rejmanual(preica_marked_epochs) = true;
            EEG.reject.rejmanualE = false(EEG.nbchan, EEG.trials);
            
            % Exit while loop
            break;
            
        end
        
    end %end while loop for bad epoch/channel identification
    
    % Save the EEG.etc.bad_channels structure to a file
    bad_channels   = EEG.etc.bad_channels;
    bad_chanids    = bad_channels.bad_inds;
    bad_chanlabels = bad_channels.bad_labels;
    save( fullfile( par_deriv_out_directory, 'bad_channels.mat' ), 'bad_channels', 'bad_chanids', 'bad_chanlabels' );
    
    % Save the preica_marked_epochs
    save( fullfile( par_deriv_out_directory, 'preica_marked_epochs.mat') , 'preica_marked_epochs' );
    
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
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%  PART 3 END  %%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
   %% Step 7: Prepare 1Hz HPF data for ICA
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
    cfg.stabilize = 'off'; % When on, this prevents the algorithm from being stuck between two points
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
    
    %% Step 9: Run ICLabel and ID Bad Components manually (POP-UPS)
    % Run IC Label and autofind 'bad' components
    EEG = iclabel(EEG, 'default');
    EEG = pop_icflag(EEG, [0 0; .8 1; .8 1; .8 1; 0 0; 0 0; 0 0]); 
        
    % Copy IC Label information, and extract max class and label.
    iclabel_output = EEG.etc.ic_classification.ICLabel;
        
    % ID bad components manually
    while true
    
        % Identify bad ICs and plot in increments of 10 components for
        % verification
        %n_ics = size(EEG.icaact,1);
        n_ics = size(EEG.icaweights,1);
        n_comps_plot = 15;
        n_loops = ceil(n_ics/n_comps_plot);
        comp_start = 1;
        comp_end = n_comps_plot;
        increment = n_comps_plot;
        for loopi = 1:n_loops
            
            % Show components and wait for OK (or the object to close)
            if loopi ~= n_loops
                EEG = pop_selectcomps( EEG, comp_start:comp_end );
                saveas(gcf,fullfile(par_fig_out_directory,sprintf('ica_comps%d-%d.png',comp_start,comp_end)));
            else
                EEG = pop_selectcomps( EEG, comp_start:n_ics );
                saveas(gcf,fullfile(par_fig_out_directory,sprintf('ica_comps%d-%d.png',comp_start,n_ics)));
            end
            
            % Wait for user to close figure
            movegui('center'); % Center on screen
            waitfor( findobj('parent', gcf, 'string', 'OK'), 'userdata');
            
            % Increment
            comp_start = comp_start + increment;
            comp_end = comp_end + increment;
            
        end
        
        % Ask if we are OK with results
        ic_good = questdlg('Do you need to look at the components again to make changes?');
        if strcmpi(ic_good, 'no')
            break;
        end
        
    end
    
    % Overwrite IC set
    cfg = [];
    cfg.setname  = 'ica';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    % Extract ICS, and write file in eeglab/ica_info
    % Extract bad ICS
    bad_ic_vector = EEG.reject.gcompreject;
    bad_ic_ids    = find(bad_ic_vector);
    
    % Extract ica info to dsbr
    icasphere   = EEG.icasphere;
    icaweights  = EEG.icaweights;
    icachansind = EEG.icachansind;
    icaact      = EEG.icaact;
    icawinv     = EEG.icawinv;
    
    % Save to .mat file
    vars2save = {'iclabel_output' 'bad_ic_vector' 'bad_ic_ids' 'icasphere' 'icaweights' 'icachansind' 'icaact' 'icawinv'};
    save( fullfile( par_deriv_out_directory, 'ica_data_output.mat' ), vars2save{:} );
    
    % Clear EEG
    EEG = [];
    ALLEEG = [];
    
    %% Step 10: Apply IC results to 0.1 Hz Data and interpolate bad channels (if missing)
    % Load EEG set file
    eeg_file = 'set06_artmark_binepochs_0.1hzhpf_500Hz.set';
    EEG      = pop_loadset( eeg_file, par_sets_out_directory );
    
    % Gather reject structure
    this_reject = EEG.reject;
    this_reject.gcompreject = [];
    
    % Copy ICA information to loaded .1 Hz filtered data
    EEG.icasphere = icasphere;
    EEG.icaweights = icaweights;
    EEG.icachansind = find( ~ismember({EEG.chanlocs.labels}, [EEG.etc.bad_channels.bad_labels 'VEOG' 'HEOG']) );
    EEG.reject.gcompreject = bad_ic_vector;
    EEG = eeg_checkset(EEG);
    
    % Subtract bad ICA components (rejects components in
    % EEG.reject.gcompreject).
    EEG = pop_subcomp(EEG, [], 1);
    
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
    EEG.reject = this_reject; 

    % Save set
    cfg = [];
    cfg.setname  = 'set07_icaclean_binepochs_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    %% Step 11: Re-reference to average and add channel locations
    % Perform mastoid rereference using ERPLAB function
    chanop_file = fullfile(directories.spec_files, 'chanops_eeg_reref_average.txt');
    EEG = pop_eegchanoperator( EEG, chanop_file );
    
    % Add back in channel locations
    EEG = pop_add_standard_chanlocs( EEG );
    
    % Save the set
    cfg = [];
    cfg.setname  = 'set08_averageref_icacleaned_binepochs_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    %% Step 12: Pre-stimulus baseline correction
    % Use pop_rmbase to correct pre-stimulus baseline
    cfg = [];
    cfg.baseline_time  = [-250 0]; % Epoch time window start and end
    EEG = pop_rmbase( EEG , cfg.baseline_time );
    
    % Save the set
    cfg = [];
    cfg.setname  = 'set09_pre250blc_avgref_icacleaned_binepochs_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    %% Step 13: Final round of artifact detection
    % Inspect previously marked epochs and remove marking
    % if they are "good" now. Also remove any epochs that have come up
    % as "bad" after removing ICs. Then do automatic algorithm for min-max
    % extreme value correction, linear drift, peak-2-peak.
    
    % Sync Artifacts
    cfg = [];
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    
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
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    
    % Gather the postica rejected epochs
    postica_art_epochs = find(EEG.reject.rejmanual);

    % Save the EEG.etc.bad_channels structure to a file
    save( fullfile( par_deriv_out_directory, 'postica_art_epochs.mat' ), 'postica_art_epochs' );
    
    % Export EVENTLIST to a file in elist
    EEG = pop_exporteegeventlist( EEG , 'Filename', fullfile( par_elist_out_directory, 'erp_good_epochs_elist.txt' ));
    
    % Save the set
    cfg = [];
    cfg.setname  = 'set10_goodepochs_pre250blc_avgref_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
end