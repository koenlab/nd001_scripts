%% Stage 3: Make ERPs using ERPLAB functions

%% Clear the workspace
clear all;
clc;

%% Add path to EEGLAB and run it (to get full path structure)
eeglab; 

%% Define main directories
% Directories
% Directories
directories.top         = 'X:\EXPT\nd001\exp1\data';
directories.preproc     = fullfile(directories.top, 'preprocessed', 'task-study');
directories.preproc_eeg = fullfile(directories.preproc, 'eeg');
directories.scripts     = fullfile(directories.top, 'scripts');
directories.spec_files  = fullfile(directories.scripts, 'spec_files'); % Where specification files are stored
directories.functions   = fullfile(directories.scripts, 'functions');

% Add directories.functions to path
addpath(directories.functions);

% Output directories for this analysis 
directories.analyses      = fullfile(directories.top, 'analyses');
directories.this_analysis = fullfile(directories.analyses, 'erp_sme1_mastoidref');
directories.erp_files     = fullfile(directories.this_analysis, 'erp_files');
make_dirs( {directories.analyses directories.this_analysis directories.erp_files} );

%% Gather participants
% Run participant selector GUI
participant_list       = participant_selector( directories.preproc_eeg );

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 0: Get some general information defined and load data
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Print info to screen
    fprintf('Preprocessing data for %s:\n',participant);
    
    % Make directory structure in data
    par_preproc_eeg_directory = fullfile( directories.preproc_eeg, participant );
    par_erps_directory        = fullfile( par_preproc_eeg_directory, 'erplab_sets' );
        
    % Define erpfile
    this_erp = 'erp6_sme_30hzlpf_mastoidref_-200to0preblc';
    this_file = fullfile(par_erps_directory, sprintf('%s.erp',this_erp));
    
    ERP = pop_loaderp('filename',this_file);
    if pari == 1
        chanlocs = ERP.chanlocs;
    end
    ERP.chanlocs = chanlocs;
    
    % Add to file list
    new_file = sprintf('%s_%s.erp',participant, this_erp);
%     copyfile( this_file, fullfile( directories.erp_files, new_file ) );
    pop_savemyerp(ERP,'filename',new_file,'filepath', directories.erp_files);
    
end

%% Change directory to ERP_FILES folder
cd(directories.erp_files)

%% Make a text file with the file names
file_list = dir2('sub*erp');
fh = fopen('erp_file_list.txt','w');
fprintf(fh,'%s\n',file_list{:});
fclose(fh);

%% Make the grand average
ERP = pop_gaverager( 'erp_file_list.txt' , 'Criterion',  25, 'ExcludeNullBin', 'on', 'SEM', 'on' );
pop_savemyerp(ERP,'filename','grand_average.erp','erpname','grand_avgref');