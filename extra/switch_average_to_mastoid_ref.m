%% Clear the workspace
clear all;
clc;

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
    eeg_file = 'set10_goodepochs_pre250blc_avgref_0.1hzhpf_500Hz.set';
    EEG      = pop_loadset( eeg_file, fullfile(par_sets_out_directory) );
    
    %% Step 1: Re-reference to mastoid and add channel locations
    % Perform mastoid rereference using ERPLAB function
    chanop_file = fullfile(directories.spec_files, 'chanops_eeg_reref_linked_mastoid.txt');
    EEG = pop_eegchanoperator( EEG, chanop_file );
    
    % Add back in channel locations
    EEG = pop_add_standard_chanlocs( EEG );
    
    % Save the set
    cfg = [];
    cfg.setname  = 'set11_goodepochs_pre250blc_mastoidref_0.1hzhpf_500Hz';
    cfg.path     = par_sets_out_directory;
    cfg.filename = [cfg.setname '.set'];
    EEG = save_eeglab_set( EEG, cfg.setname, cfg.path, cfg.filename );
    
end

    