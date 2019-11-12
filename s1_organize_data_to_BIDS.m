%% FORMAT DATA TO BIDS %%
% This script formats the data from source data to a bids structure.
%
% NEED TO EXPAND ON THIS
% NEED TO EXPAND ON PROCESS_STUDYDATA, PROCESS_TESTDATA, and
% COMBINE_STUDYTEST_DATA

% %% Load settings
% run('analysis_settings.m');

%% Clear the workspace
clear all;
clc;

%% Add path to EEGLAB and run it (to get full path structure)
eeglab; 
addpath('functions');

%% Option flags
% Ask for participant GUI...set to false if you are re-processing data
% where the participant info is in the GUI
show_par_gui = false;

%% Define main directories
% Directories
directories.top        = 'X:\EXPT\nd001\exp1\data';
directories.source     = fullfile(directories.top, 'sourcedata');
directories.derivative = fullfile(directories.top, 'derivatives');

% Make directories if needed
make_dirs({directories.top directories.derivative});

%% BIDS Options
% Channel options
chans.ref = 'FCz';

% BIDS file names
bids_files.participants_tsv = fullfile(directories.top,'participants.tsv');

% Participant input options
par_gui.fields = {'age' 'sex' 'ethnicity' 'race' 'study_cb'};

% variables in study data to add to EEG.event (for *events.tsv sidecar)
study_evt2eeg.event_types = {'M  1' 'M  2' 'M  3'};
study_evt2eeg.vars_to_add = { ...
    'word' 'task1' 'task2' 'cur_task' 'lag' 'item_type' 'trial_type' 'study_resp' 'study_rt' ...
    'n_resps' 'on_resp' 'artist_resp' 'function_resp' 'pleasant_resp' 'vacation_resp' ...
    'vacation_resp' 'dk_resp' 'task1_acc' 'task2_acc' 'n_cor_source' 'n_sources_sel' 'memory_bin' 'bad_trial_total' };
study_evt2eeg.vars_to_write = study_evt2eeg.vars_to_add;

%% Run the participant selector
% Run participant selector GUI
participant_list = participant_selector(directories.source);

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 1: Gather Participant ID and make directories
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Print info to screen
    fprintf('\n\nOrganizing BIDS data for %s:\n\n',participant);
    
    % Request information on participants and store in participants_tsv
    if show_par_gui
        par_info = participant_info_gui( participant, par_gui.fields );
        bids_participants_tsv( par_info, bids_files.participants_tsv );
    end
    
    % Make directory structure in data
    par_source_beh_directory   = fullfile(directories.source, participant, 'beh');
    par_source_eeg_directory   = fullfile(directories.source, participant, 'eeg');
    par_data_directory         = fullfile(directories.top, participant);
    par_data_beh_directory     = fullfile(par_data_directory, 'beh');
    par_data_eeg_directory     = fullfile(par_data_directory, 'eeg');
    par_deriv_out_directory    = fullfile( directories.derivative, 'beh', participant );
    par_beh_fig_directory      = fullfile( par_deriv_out_directory, 'figures' );
    
    % Make directories
    make_dirs({par_data_directory, par_data_eeg_directory, par_data_beh_directory, par_deriv_out_directory, par_beh_fig_directory});
    
    %% Step 2: Process study and test data files
    % Define study and test file names
    study_beh_file       = sprintf('%s_task-study_beh.tsv', participant);
    test_beh_file        = sprintf('%s_task-test_beh.tsv', participant);
        
    % Load and process BEH data files from sourcedata
    study_beh_data       = process_studydata( fullfile(par_source_beh_directory, study_beh_file) );
    test_beh_data        = process_testdata( fullfile(par_source_beh_directory, test_beh_file) );
    [study_beh_data, test_beh_data] = combine_studytest_data( study_beh_data, test_beh_data );
    
    % Conduct some behavioral analysis
    summarize_behavioral_data( study_beh_data, test_beh_data, participant, par_beh_fig_directory );
    
    % Save study and test data file in bids
    writetable(study_beh_data, fullfile(par_data_beh_directory, study_beh_file), ...
        'FileType','text','Delimiter','\t');
    writetable(test_beh_data, fullfile(par_data_beh_directory, test_beh_file), ...
        'FileType','text','Delimiter','\t');
    
    %% Step 3: Process Study EEG Data
    % Load EEG Data 
    eeg_vhdr   = sprintf('%s_task-study_eeg.vhdr', participant);
    eeg_set    = sprintf('%s_task-study_eeg.set', participant);
    EEG = pop_loadbv(par_source_eeg_directory, eeg_vhdr, [], []);
    
    % Add channel info
    EEG = add_channel_info(EEG, chans.ref);
    
    % Remove first event
    EEG.event(1) = [];
    
    % Merge Events from study_beh -- manually trimmed first 9 events off
    % for subject 126 because EEG didn't record for first 9 events (MLW)
    EEG = eeglab_add_table_to_events( EEG, study_beh_data, ...
        study_evt2eeg.event_types, study_evt2eeg.vars_to_add);
    
    % Add set name and participant
    EEG.setname = 'task-study raw data';
    EEG.subject = participant;
    
    % Fix mislabelled auxiliary sensors (VEOG, HEOG, photosensor) for subjects 111-114
    if ismember(participant, {'sub-111' 'sub-112' 'sub-113' 'sub-114' 'sub-115'})
       
        EEG.chanlocs(64).labels = 'Photosensor';
        EEG.chanlocs(64).type = 'MISC';
        EEG.chanlocs(64).unit = 'mV';
        
        EEG.chanlocs(65).labels = 'VEOG';
        EEG.chanlocs(65).type = 'VEOG';
        EEG.chanlocs(65).unit = 'µV';
        
        EEG.chanlocs(66).labels = 'HEOG';
        EEG.chanlocs(66).type = 'HEOG';
        EEG.chanlocs(66).unit = 'µV';
        
    end
    
    % Save the set    
    EEG = pop_saveset( EEG, ...
        'filename', eeg_set, ...
        'filepath', par_data_eeg_directory, ...
        'check', 'on' );
    
    % Create *_channels.tsv and *_events.tsv
    bids_channels_to_tsv( EEG, '' );
    bids_events_to_tsv( EEG,'', study_evt2eeg.vars_to_write);

    %% Step 3: Process EO Rest Data
    try
        for runi = 1:2
            
            % Load EEG Data 
            eeg_vhdr   = sprintf('%s_task-eorest_run-0%d_eeg.vhdr', participant, runi);
            eeg_set    = sprintf('%s_task-eorest_run-0%d_eeg.set', participant, runi);
            EEG = pop_loadbv(par_source_eeg_directory, eeg_vhdr, [], []);
            
            % Add channel info
            EEG = add_channel_info(EEG, chans.ref);
            
            % Remove first event
            EEG.event(1) = [];
            
            % Add set name and participant
            EEG.setname = 'task-study raw data';
            EEG.subject = participant;
            
            % Fix mislabelled auxiliary sensors (VEOG, HEOG, photosensor) for subjects 111-114
            
            if ismember(participant, {'sub-111' 'sub-112' 'sub-113' 'sub-114' 'sub-115'})
                
                EEG.chanlocs(64).labels = 'Photosensor';
                EEG.chanlocs(64).type = 'MISC';
                EEG.chanlocs(64).unit = 'mV';
                
                EEG.chanlocs(65).labels = 'VEOG';
                EEG.chanlocs(65).type = 'VEOG';
                EEG.chanlocs(65).unit = 'µV';
                
                EEG.chanlocs(66).labels = 'HEOG';
                EEG.chanlocs(66).type = 'HEOG';
                EEG.chanlocs(66).unit = 'µV';
                
            end
            
            % Save the set
            EEG = pop_saveset( EEG, ...
                'filename', eeg_set, ...
                'filepath', par_data_eeg_directory, ...
                'check', 'on' );
            
            % Create *_channels.tsv and *_events.tsv
            bids_channels_to_tsv( EEG, '' );
            bids_events_to_tsv( EEG,'', ''); % Write all fields
            
        end
        
    catch
        fprintf('EO Rest data does not exist for %s!!!\n',participant)      
    end
    
   % Add some space
   fprintf('\n\n')
    
end

% Add in other JSON and sidecar files
% task-study_events.json
% task-study_beh.json
% task-test_beh.json
% README

    
    
    
    
    
    
    
    