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

% Add directories.functions to path
addpath(directories.functions);

%% Run the participant selector
% Run participant selector GUI
participant_list       = participant_selector(directories.preproc_eeg);

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 0: Get some general information defined
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
    eeg_file = 'set11_goodepochs_pre200blc_mastoidref_0.05-100bpf_500Hz.set';
    EEG = pop_loadset( eeg_file, par_sets_out_dir );
    
    % Pull the bad ICA components value
    ica_bad(pari) = (63-size(EEG.icaact, 1));
    
end

   % Pull stats on removed ic's
   mean(ica_bad)
   std(ica_bad)