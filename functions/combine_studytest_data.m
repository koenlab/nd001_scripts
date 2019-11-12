% combine_studytest_data - This function merges specific functions in the
%                          study and test data tables.
% Usage:
%   >> [study_data, test_data] = combine_studytest_data( study_data, test_data )
%
% Required inputs:
%   study_data - data table for the study behavioral data
%   test_data  - data table for the test behavioral data
%
% Outputs:
%   study_data - data table for the study behavioral data with test data added
%   test_data  - data table for the test behavioral data with study data added
%
% Notes:
%   Here is where I describe more about the output of the data. 
%
% Create by: Joshua D. Koen, University of Notre Dame

function [study_data, test_data] = combine_studytest_data( study_data, test_data )

% Check file
if ~istable(study_data) || ~istable(test_data)
    error('study_data or test_data is not a data table!!!')
end

% Copy test to study data first
test_vars_copy = {'word' 'on_resp' 'artist_resp' 'function_resp' 'pleasant_resp' ...
    'vacation_resp' 'dk_resp' 'task1_acc' 'task2_acc' 'n_cor_source' ...
    'n_sources_sel' 'memory_bin' 'test_de_bad' 'test_rt_bad' 'test_bad_trial'};
study_data = join(study_data, test_data(:, test_vars_copy), 'Keys', 'word');

% Compute new column with combined bad trial data (0 or multiple responses
% at study and 2 responses to de trials at test)

% % Add column for when there are multiple responses for de trial.
study_data.bad_trial_total = study_data.study_bad_trial | study_data.test_bad_trial;
% % study_data.bad_trials_total = zeros(size(study_data,1),1);
% % 
% %Loop through all trials and mark a trial as bad for any of the reasons
% for trial = 1:size(study_data,1)
%     if study_data.test_de_bad(trial) || study_data.study_bad_nr(trial) || study_data.study_bad_multi_resp(trial)
%         study_data.bad_trials_total(trial) = 1;
%     end
% end

%%%%%%%%% Now, manually loop through test and get study_data %%%%%%%%%%%%
% Will add 8 new variables:
%   study_task1_resp
%   study_task1_rt
%   study_task1_n_resps
%   study_task2_resp
%   study_task2_rt
%   study_task2_n_resps
%   lag
%   bad_trials_total

% Initialize these new fields
new_test_fields = {'study_task1_resp' 'study_task1_rt' 'study_task1_n_resps' ...
    'study_task2_resp' 'study_task2_rt' 'study_task2_n_resps' 'lag' 'study_bad_trial'};

% I go through each trial, and make a vector. Then I for loop to make the
% new data entry. 
for trli = 1:size(test_data,1)
    
    % Get indices
    sidx = find( ismember( study_data.word, test_data.word{trli} ) );
    if ~ismember(length(sidx), [0 1 2])
        error('There is a trial presented more than 2 times at study!!!!!!')
    end
    
    % If a new trial, idxs will be empty
    if isempty(sidx)
        study_trial_data = repmat(-99, size(new_test_fields)-1); % Subtract 1 to avoid new item bad trials column being given value of -99. 
        study_trial_data(end+1) = 0; % Code bad trial for new item as good (that is a value of 0).
    elseif length(sidx) == 1 % Must be a DE Trial
        study_trial_data = [ ...
            study_data.study_resp(sidx) ...
            study_data.study_rt(sidx) ...
            study_data.n_resps(sidx) ...
            -99 ...
            -99 ...
            -99 ...
            -99 ...
            study_data.study_bad_trial(sidx)
            ];
    else % Must be a AB or AC trial
        study_trial_data = [ ...
            study_data.study_resp(sidx(1)) ...
            study_data.study_rt(sidx(1)) ...
            study_data.n_resps(sidx(1)) ...
            study_data.study_resp(sidx(1)) ...
            study_data.study_rt(sidx(1)) ...
            study_data.n_resps(sidx(1)) ...
            study_data.lag(sidx(1)) ...
            study_data.study_bad_trial(sidx(1))
            ];
        
        % Error check for sanity
        if study_data.lag(sidx(1)) ~= study_data.lag(sidx(2))
            error('Lags don''t match on AB and AC trials...NO!!!!!!! The word is %s', study_data.word{idx1});
        end
    end
    
    % Check if length matches and, if so, add the data
    if length(new_test_fields) == length(study_trial_data)
        for field = 1:length(new_test_fields)
            test_data.(new_test_fields{field})(trli) = study_trial_data(field);
        end
    end
    
end

% Add bad_trial to test data
test_data.bad_trial_total = test_data.test_bad_trial | test_data.study_bad_trial;
        
end % of function