% process_studydata() - This function processes the study data files. This
%                       function is spectic to this project.
% Usage:
%   >> dt = process_studydata(tsv_file)
%
% Required inputs:
%   tsv_file   - file naem of data file to process
%
% Outputs:
%   dt         - data table object containing the processed data. 
%
% Notes:
%   Here is where I describe more about the output of the data. 
%
% Create by: Joshua D. Koen, University of Notre Dame

function dt = process_studydata(tsv_file)

% Check file
if ~isfile(tsv_file)
    error('%s does not exist.', tsv_file);
end

% Load the file into a DataTable using automatic option detection
opts       = detectImportOptions(tsv_file, 'FileType', 'text');
orig_data  = readtable(tsv_file, opts);

% Reorganize original data
vars_to_keep = { ...
    'id' 'stim_set' 'study_cb' 'word' 'length' 'freq_kf' 'nsyll' 'cnc' 'img' ...
    'task1' 'task2' 'cur_task' 'lag' 'item_type' 'trial_type' ....
    'resp_key' 'resp' 'rt' 'trial_kb_keys' 'trial_kb_rt' 'n_resps'};

% Extract variables needed
dt = orig_data(:, vars_to_keep);

% Extract variables to rename
vars_to_rename = {'id' 'resp_key' 'resp' 'rt' 'trial_kb_keys' 'trial_kb_rt'};
vars_new_names = {'sub_id' 'study_resp_key' 'study_resp' 'study_rt' 'all_keys' 'all_rts'};
for v = 1:length(vars_to_rename)
    try 
        dt.Properties.VariableNames{vars_to_rename{v}} = vars_new_names{v};
    catch
    end
end

% Process all keys 
chars_to_remove = {'''' '[' ']'};
for row = 1:size(dt,1)
    
    % Get the all_keys value
    this_val = dt.all_keys{row};
    for c = string(chars_to_remove)
        this_val = strrep(this_val, c, '');
    end
    dt.all_keys{row} = char(this_val);
    
%     % Convert all_rts to matrix
%     if strcmpi(dt.all_rts{row},'--')
%         dt.all_rts{row} = -99;
%         dt.n_resps(row) = 0;
%     else
%         dt.all_rts{row} = eval(dt.all_rts{row});
%     end
    
end

% Update lag to -99
dt.lag( dt.lag == -999) = -99;

% Add column excluding trials with multiple responses, no response or a
% response that is too quick. For AB/AC trials, this will exclude both (eeek!)

% initialize bad_trial columns
dt.study_bad_nr = zeros(size(dt,1),1);
dt.study_bad_multi_resp = zeros(size(dt,1),1);
dt.study_bad_too_quick = zeros(size(dt,1),1);

% Get vector of unique words and loop over it.
all_words = unique(dt.word);
for wi = 1:length(all_words)
    
    % Get indices of trial
    idxs = find( ismember( dt.word, all_words{wi} ) );
    
    % get study_n_resps
    n_resps = dt.n_resps(idxs);
    
    % get study_rt
    study_rt = dt.study_rt(idxs);
    
    % If either is a 0, makr in dt.study_bad_nr
    if any(n_resps == 0), dt.study_bad_nr(idxs) = 1; end
    
    % If either is > 1, mark in dt.study_bad_multi_resp
    if any(n_resps > 1), dt.study_bad_multi_resp(idxs) = 1; end
    
    % If the participant responded in <200 ms, mark in
    % dt.study_bad_too_quick
    if any(abs(study_rt) < .2), dt.study_bad_too_quick(idxs) = 1; end
    
end 

% Make a study_Bad column
dt.study_bad_trial = dt.study_bad_too_quick | dt.study_bad_multi_resp | dt.study_bad_nr;

end % of function