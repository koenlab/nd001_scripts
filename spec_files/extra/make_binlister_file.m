%% Make Binlister TXT file
% This script makes a binlister formatted text file for use with ERPLABs
% binepoch functions. This creates bins over trial type (AB, AC, and DE)
% and subsequent memory (HH, HM, MH, MM, MISS, and BAD) factors. Note that
% HH, HM, etc. correspond to source memory accuracy for the AB trials
% (first litter) and source memory for the AC trials (second letter). This
% coding scheme is also used for DE trials, which only include memory for
% one source. Thus, source htis for DE are coded as HH and misses as MM.
% Trials labeled BAD are mainly DE trials where two source responses were
% given (H2 and M2 trials). The MISS bin corresponds to item misses. 

% Trial type ID numbers
type_bin = struct( ...
    'ab', 1, ...
    'ac', 2, ...
    'de', 3 );
    
    % Memory bin ID numbers
    mem_bin = struct( ...
        'hh',   21, ...
        'hm',   22, ...
        'mh',   23, ...
        'mm',   24, ...
        'miss2',  25, ...
        'bad',  99, ...
        'h',    11, ...
        'm',    12, ...
        'miss1',  13 );
    
    % Current task bin numbers
    task_bin = struct( ...
        'artist', 1, ...
        'function', 2, ...
        'pleasant', 3, ...
        'vacation', 4 );
    
    % Initialize counter
    counter = 1;
    
    %Create cell array to loop through the different combinations of type,
    %memory and current task
    type_ind = {'ab' 'ac' 'de'};
    mem_ind = {'hh' 'hm' 'mh' 'mm' 'miss2' 'bad' 'h' 'm' 'miss1'};
    task_ind = {'artist' 'function' 'pleasant' 'vacation'};
    
    % Initialize the combo variable
    combo = {};
    
    for a = 1:length(type_ind)
        for b = 1:length(mem_ind)
            for c = 1:length(task_ind)
                
                %Determine type, mem and task for each index
                this_type = type_ind{a};
                this_mem = mem_ind{b};
                this_task = task_ind{c};
                
                % Determine type and code in current index
                cur_event.code = str2double(sprintf('%d%d%d', type_bin.(this_type), mem_bin.(this_mem), task_bin.(this_task)));
                cur_event.task = sprintf('%s-%s-%s',this_type,this_mem,this_task);
                
                % Update total variable with current task and code
                combo{1,counter} = cur_event.task;
                combo{2,counter} = cur_event.code;
                
                counter = counter + 1;
            end
        end
    end
    
    fileID = fopen('X:\EXPT\nd001\exp1\data\scripts\trialtype_memory_curtask_binlister.txt', 'w');
    for d = 1:length(combo)  
        fprintf(fileID, 'bin %d\r\n%s\r\n.{%d}\r\n\r\n', d, combo{1,d}, combo{2,d});
    end
    fclose(fileID);
    