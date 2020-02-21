%% Stage 3: Make ERPs using ERPLAB functions

%% Clear the workspace
clear all;
clc;

%% Add path to EEGLAB and run it (to get full path structure)
eeglab; 

%% Define main directories
% Directories
directories.top        = 'X:\EXPT\nd001\exp1\data';
directories.source     = fullfile(directories.top, 'sourcedata');
directories.derivative = fullfile(directories.top, 'derivatives');
directories.spec_files = fullfile(directories.top, 'scripts', 'spec_files'); % Where specification files are stored

% Output directories for this analysis 
directories.analyses      = fullfile(directories.top, 'analyses');
directories.this_analysis = fullfile(directories.analyses, 'erp_sme1_avgref');
directories.erp_files     = fullfile(directories.this_analysis, 'erp_files');
make_dirs( {directories.analyses directories.this_analysis directories.erp_files} );

%% Gather participants
participant_list = dir2( fullfile(directories.top,'sub-*') );

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 0: Get some general information defined and load data
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Print info to screen
    fprintf('Preprocessing data for %s:\n',participant);
    
    % Make directory structure in data
    par_deriv_out_eeg_directory    = fullfile( directories.derivative, 'eeg', 'task-study', participant );
    par_erps_out_directory         = fullfile( par_deriv_out_eeg_directory, 'erplab_sets' );
        
    % Define erpfile
    this_erp = 'erp_30hzlpf_-250to1500_avgref_preblc_binop_SME';
    this_file = fullfile(par_erps_out_directory, sprintf('%s.erp',this_erp));
    
    % Add to file list
    new_file = sprintf('%s_%s.erp',participant, this_erp);
    copyfile( this_file, fullfile( directories.erp_files, new_file ) );
    
end

%% Change directory to ERP_FILES folder
cd(directories.erp_files)

%% Make a text file with the file names
file_list = dir2('*erp');
fh = fopen('erp_file_list.txt','w');
fprintf(fh,'%s\n',file_list{:});
fclose(fh);

%% Make the grand average
ERP = pop_gaverager( 'erp_file_list.txt' , 'Criterion',  25, 'ExcludeNullBin', 'on', 'SEM', 'on' );
pop_savemyerp(ERP,'filename','grand_average.erp','erpname','grand_avgref');