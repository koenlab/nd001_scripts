%% Clear the workspace
clear all;
clc;

%% Add path to EEGLAB and run it (to get full path structure)
eeglab; 

% Directories
directories.top        = 'X:\EXPT\nd001\exp1\data';
directories.rawbids     = fullfile(directories.top, 'raw_bids');
directories.source      = fullfile(directories.top, 'raw_bids', 'sourcedata');
directories.derivative = fullfile(directories.top, 'preprocessed', 'task-study');

participant_list = participant_selector(directories.source);

%% Step 2: Create all subjects study 
for pari = 1:length(participant_list)
    
    %% Step 1: Gather Participant ID and make directories
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Make directory structure in data
    par_source_beh_directory   = fullfile(directories.rawbids, participant, 'beh');
    cd(par_source_beh_directory);
    
    % Define study and test file names
    study_beh_file_name   = sprintf('%s_task-study_beh.tsv', participant);
    study_beh_file        = readtable(study_beh_file_name, 'FileType', 'text');
    
    if pari == 1
        allsubj_study_beh_file = study_beh_file;
    elseif pari >= 2
        allsubj_study_beh_file = vertcat(allsubj_study_beh_file, study_beh_file);
    end
    
end

cd(fullfile(directories.derivative, 'beh'));
writetable(allsubj_study_beh_file, 'allsubj_task-study_forR.xlsx', 'UseExcel', 1);
    
%% Step 3: Create all subjects test 
for pari = 1:length(participant_list)
    
    %% Step 1: Gather Participant ID and make directories
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Make directory structure in data
    par_source_beh_directory   = fullfile(directories.rawbids, participant, 'beh');
    cd(par_source_beh_directory);
    
    % Define study and test file names
    test_beh_file_name     = sprintf('%s_task-test_beh.tsv', participant);
    test_beh_file          = readtable(test_beh_file_name, 'FileType', 'text');
    
    if pari == 1
        allsubj_test_beh_file = test_beh_file;
    elseif pari >= 2
        allsubj_test_beh_file = vertcat(allsubj_test_beh_file, test_beh_file);
    end
end

cd(fullfile(directories.derivative, 'beh'));
writetable(allsubj_test_beh_file, 'allsubj_task-test_forR.xlsx', 'UseExcel', 1);