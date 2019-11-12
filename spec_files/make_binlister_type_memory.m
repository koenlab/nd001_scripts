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

%% Clear workspace
clear all;
clc;

%% Initialize file
% Open the file in write only mode
fid = fopen('binlister_trialtype_memorybin.txt','w');

%% Write binlister file
% Trial type ID numbers
type_bin = struct( ...
    'ab', 1, ...
    'ac', 2, ...
    'de', 3 );

% Coding the above mem_bin numbreically
coded_mem_bin = struct( ...
    'HH',   1, ... % Includes HH2 and H1
    'HM',   2, ... % Includes HM2 and HM1
    'MH',   3, ... % Includes MH2 and MH1
    'MM',   4, ... % Includes MM2, MM1, MM0, M1, and M0
    'MISS', 5 ... % Includes MISS2 and MISS1
    );

% Get strings of fields from above variables
type_str = fieldnames(type_bin);
mem_str  = fieldnames(coded_mem_bin); 

% Initialize a bin number counter
bin_counter = 1;

% Loop through everything for all 'good' bins
for typei = 1:length(type_str)
    for memi = 1:length(mem_str)
        
        % Get current values
        this_type = type_str{typei};
        this_mem  = mem_str{memi};
        
        % Skip bins that are not necessary (DE and MH or HM memory or AB-AC paired with BAD)
        if strcmpi(this_type,'de') && ismember(this_mem, {'HM' 'MH'} ), continue; end
%         if ismember(this_type,{'ab' 'ac'}) && strcmpi(this_mem, 'BAD'), continue; end
        
        % Write to file
        fprintf(fid, 'bin %d\n', bin_counter);
        fprintf(fid, '%s-%s\n', this_type, this_mem);
        fprintf(fid, '.{%d%d}\n\n', type_bin.(this_type), coded_mem_bin.(this_mem));
        
        % Increment counter
        bin_counter = bin_counter+1;
        
    end
end

% Loop through bad bins
for typei = 1:length(type_str)
    % Get current values
    this_type = type_str{typei};
    this_mem  = 'BAD';
    
    % Write to file
    fprintf(fid, 'bin %d\n', bin_counter);
    fprintf(fid, '%s-%s\n', this_type, this_mem);
    fprintf(fid, '.{%d99}\n\n', type_bin.(this_type));
    
    % Increment counter
    bin_counter = bin_counter+1;
        
end

fclose(fid);