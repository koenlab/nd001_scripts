
eeglab;

subID = sprintf('sub-%d',101);

% Work with behavioral data

% Study Data
opts = detectImportOptions(sprintf('%s_task-study_beh.tsv', subID),'FileType','text');
study_data = readtable(sprintf('%s_task-study_beh.tsv', subID), opts);
chars_to_remove = {'''' '[' ']' ' '};
for c = chars_to_remove
    study_data.all_resp = cellfun(@(x) strrep(x,c{1},''), study_data.all_resp,'UniformOutput',false);
end
study_data.n_study_resp = cellfun(@(x) length(strrep(x,',','')), study_data.all_resp);
study_data.all_rt = cellfun(@(x) eval(x), study_data.all_rt,'UniformOutput',false);
study_data = removevars(study_data,'x___study_cb');

% Test Data
opts = detectImportOptions(sprintf('%s_task-test_beh.tsv', subID),'FileType','text');
test_data = readtable(sprintf('%s_task-test_beh.tsv', subID), opts);
test_data.Properties.VariableNames{1} = 'frameRate';

% Code test data


% Combine test data with study data
for t = 1:height(study_data)
    
    % Get test index
    test_idx = ismember(test_data.word

% Load Data
EEG = pop_loadbv('','sub-101_task-study_eeg.vhdr');