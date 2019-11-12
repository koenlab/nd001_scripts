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
    eeg_file = 'ica.set';
    EEG      = pop_loadset(eeg_file, fullfile(par_sets_out_directory) );
    
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
        n_loops = fix(n_ics/n_comps_plot) + 1;
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
    % extreme value correction.
    
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
    
    % Do another round of manual inspection
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
    
    % Sync Artifacts
    cfg = [];
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    
    % Save the set
    cfg = [];
    cfg.setname  = 'set10_goodepochs_pre250blc_avgref_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
    % Gather the postica rejected epochs
    postica_art_epochs = find(EEG.reject.rejmanual);

    % Save the EEG.etc.bad_channels structure to a file
    save( fullfile( par_deriv_out_directory, 'postica_art_epochs.mat' ), 'postica_art_epochs' );
    
end
