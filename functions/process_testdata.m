% process_testdata() - This function processes the test data files. This
%                       function is spectic to this project.
% Usage:
%   >> dt = process_testdata(tsv_file)
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

function dt = process_testdata(tsv_file)

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
    'task1' 'task2' 'item_type' 'on_resp_key' 'on_resp' 'on_rt' ...
    'artist_resp' 'function_resp' 'pleasant_resp' 'vacation_resp' 'dk_resp' ...
    'source_rt' 'task1_acc' 'task2_acc' 'n_cor_source' 'n_sources_sel' };

% Extract variables needed
dt = orig_data(:, vars_to_keep);

% Extract variables to rename
dt.Properties.VariableNames{'id'} = 'sub_id';

% Update n_cor_source and n_sources_sel with -99 if a new response
for t = 1:size(dt,1)
    if strcmpi( dt.on_resp{t}, 'new' )
        dt.n_cor_source(t) = -99;
        dt.n_sources_sel(t) = -99;
    end
end

% Code the data and add the memory bin columns. These are:
% ABAC Trials:
%   (11) HH2  - Task 1 and Task 2 Remembered 
%   (12) HM2  - Task 1 Remembered and Task 2 Forgotten (2 sources selected)
%   (13) HM1  - Task 1 Remembered and Task 2 Forgotten (1 source selected)
%   (14) MH2  - Task 1 Forgotten and Task 2 Remembered (2 sources selected)
%   (15) MH1  - Task 1 Forgotten and Task 2 Remembred (1 source selected)
%   (17) MM1  - Both Tasks Forgotten (1 source selected)
%   (16) MM2  - Both Tasks Forgotten (2 sources selected)
%   (18) MM0  - Both Tasks Forgotten (DK Option Selected)
%   (19) MISS2 - Item Miss (new response to the word, no sources made)
%
% DE Trials:
%   (22) H1  - DE Remembered (1 source selected)
%   (21) H2  - DE Remembered (2 sources selected)
%   (24) M1  - DE Forgotten  (1 source selected)
%   (23) M2  - DE Forgotten  (2 source selected)
%   (25) M0  - DE Forgotten  (DK option selected)
%   (26) MISS1 - Item Miss (new response to the word, no sources made)
%
% New Trials
%   (NA) FA0  - False Alarm (DK source response)
%   (NA) FA1  - False Alarm (1 source selected)
%   (NA) FA2  - False Alarm (2 source selected)
%   (NA) CR   - Correct Rejection

for t = 1:size(dt,1)
    
    % Gather tasks
    task1 = dt.task1{t};
    task2 = dt.task2{t};
    
    % Check old item source responses
    if ~strcmpi(dt.item_type{t}, 'new')
        
        % Do task 1 always
        if ( dt.(sprintf('%s_resp',task1))(t) ~= dt.task1_acc(t) ) && ...
           ( strcmpi(dt.on_resp{t}, 'new') ~= dt.task1_acc(t) == -99 )
            error('THERE IS A CODING ERROR IN TASK 1 SOURCE ACCURACY TRIAL %d', t)
        end
        
        % Do task 2 if abac
        if strcmpi(dt.item_type{t}, 'abac')
            if ( dt.(sprintf('%s_resp',task2))(t) ~= dt.task2_acc(t) ) && ...
               ( strcmpi(dt.on_resp{t}, 'new') ~= dt.task1_acc(t) == -99 )
             error('THERE IS A CODING ERROR IN TASK 2 SOURCE ACCURACY TRIAL %d', t)
            end
        end
        
    end

    % Code the trials
    if strcmpi(dt.item_type{t}, 'new') % New Trials
        
        % Code based on response and, if old response, n_sources_sel
        if strcmpi(dt.on_resp{t}, 'old')
            dt.memory_bin{t} = sprintf('FA%d', dt.n_sources_sel(t));
        else
            dt.memory_bin{t} = 'CR';
        end
        
    elseif strcmpi(dt.item_type{t}, 'de') % DE Trials
        
        % Error check n_cor_source (should be in [0 1 -99]
        if ~ismember(dt.n_cor_source(t), [0 1 -99])
            error('N_COR_SOURCE OUT OF RANGE ON TRIAL %t', t)
        end
        
        % Code the data
        if dt.task1_acc(t) == 1
            dt.memory_bin{t} = sprintf('H%d', dt.n_sources_sel(t));
        elseif dt.task1_acc(t) == 0
            dt.memory_bin{t} = sprintf('M%d', dt.n_sources_sel(t));
        else % should be a -99
            dt.memory_bin{t} = 'MISS1';
        end
        
    elseif strcmpi(dt.item_type{t}, 'abac') % ABAC Trials
        
        % Error check n_cor_course (should be in [0 1 2 -99]
        if ~ismember(dt.n_cor_source(t), [0 1 2 -99])
            error('N_COR_SOURCE OUT OF RANGE ON TRIAL %t', t)
        end 
        
        % Code the data
        if dt.task1_acc(t) == 1 && dt.task2_acc(t) == 1
            dt.memory_bin{t} = 'HH2';
        elseif dt.task1_acc(t) == 1 && dt.task2_acc(t) == 0
            dt.memory_bin{t} = sprintf('HM%d', dt.n_sources_sel(t));
        elseif dt.task1_acc(t) == 0 && dt.task2_acc(t) == 1
            dt.memory_bin{t} = sprintf('MH%d', dt.n_sources_sel(t));
        elseif dt.task1_acc(t) == 0 && dt.task2_acc(t) == 0
            dt.memory_bin{t} = sprintf('MM%d', dt.n_sources_sel(t));
        else % should be a -99 and -99
            dt.memory_bin{t} = 'MISS2';
        end
        
    end
    
end

%% Add columnns excluding trials with bad data.
% Add column for when there are multiple responses for de trial.
dt.test_de_bad = zeros(size(dt,1),1);
dt.test_rt_bad = zeros(size(dt,1),1);

%Loop through all trials and mark dt.test_de_bad when there are 2 sources selected
for trial = 1:size(dt,1)
    if (strcmp(dt.item_type(trial), 'de') && (dt.n_sources_sel(trial)==2))
        dt.test_de_bad(trial) = 1;
    end
end

%Loop through all trials and mark dt.test_rt_bad when rt < 200ms
for trial = 1:size(dt,1)
    if (abs(dt.on_rt(trial)) < .2) || (abs(dt.source_rt(trial)) < .2)
        dt.test_rt_bad(trial) = 1;
    end
end

% For clarity, copy dt.test_rt_bad to dt.test_bad_trial
dt.test_bad_trial = dt.test_de_bad | dt.test_rt_bad;

end % of function