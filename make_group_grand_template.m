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

%% Files for grand average
file_list = {};

%% Run the participant selector
% Run participant selector GUI
participant_list       = participant_selector(directories.top);


%% Loop through participants
mkdir('grand')
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
    this_erp = 'erp_30hzlpf_-250to1500_avgref_preblc_binop_condmem';
    this_file = fullfile(par_erps_out_directory, sprintf('%s.erp',this_erp));
    
%     % Add to file list
    new_file = fullfile('grand',sprintf('%s.erp',participant));
    copyfile(this_file,new_file);
    file_list = vertcat(file_list,new_file);
%     
    
    % Load ERP
    ERP = pop_loaderp('filename',new_file);

    %Equivalent command:
    ERP = pop_erpchanoperator( ERP, {  'nch1 = ch1 - ( (ch10+ch21)/2 ) Label Fp1',  'nch2 = ch2 - ( (ch10+ch21)/2 ) Label Fz',...
        'nch3 = ch3 - ( (ch10+ch21)/2 ) Label F3',  'nch4 = ch4 - ( (ch10+ch21)/2 ) Label F7',  'nch5 = ch5 - ( (ch10+ch21)/2 ) Label FT9',  'nch6 = ch6 - ( (ch10+ch21)/2 ) Label FC5',...
        'nch7 = ch7 - ( (ch10+ch21)/2 ) Label FC1',  'nch8 = ch8 - ( (ch10+ch21)/2 ) Label C3',  'nch9 = ch9 - ( (ch10+ch21)/2 ) Label T7',...
        'nch10 = ch10 - ( (ch10+ch21)/2 ) Label TP9',  'nch11 = ch11 - ( (ch10+ch21)/2 ) Label CP5',  'nch12 = ch12 - ( (ch10+ch21)/2 ) Label CP1',...
        'nch13 = ch13 - ( (ch10+ch21)/2 ) Label Pz',  'nch14 = ch14 - ( (ch10+ch21)/2 ) Label P3',  'nch15 = ch15 - ( (ch10+ch21)/2 ) Label P7',...
        'nch16 = ch16 - ( (ch10+ch21)/2 ) Label O1',  'nch17 = ch17 - ( (ch10+ch21)/2 ) Label Oz',  'nch18 = ch18 - ( (ch10+ch21)/2 ) Label O2',...
        'nch19 = ch19 - ( (ch10+ch21)/2 ) Label P4',  'nch20 = ch20 - ( (ch10+ch21)/2 ) Label P8',  'nch21 = ch21 - ( (ch10+ch21)/2 ) Label TP10',...
        'nch22 = ch22 - ( (ch10+ch21)/2 ) Label CP6',  'nch23 = ch23 - ( (ch10+ch21)/2 ) Label CP2',  'nch24 = ch24 - ( (ch10+ch21)/2 ) Label Cz',...
        'nch25 = ch25 - ( (ch10+ch21)/2 ) Label C4',  'nch26 = ch26 - ( (ch10+ch21)/2 ) Label T8',  'nch27 = ch27 - ( (ch10+ch21)/2 ) Label FT10',...
        'nch28 = ch28 - ( (ch10+ch21)/2 ) Label FC6',  'nch29 = ch29 - ( (ch10+ch21)/2 ) Label FC2',  'nch30 = ch30 - ( (ch10+ch21)/2 ) Label F4',...
        'nch31 = ch31 - ( (ch10+ch21)/2 ) Label F8',  'nch32 = ch32 - ( (ch10+ch21)/2 ) Label Fp2',  'nch33 = ch33 - ( (ch10+ch21)/2 ) Label AF7',...
        'nch34 = ch34 - ( (ch10+ch21)/2 ) Label AF3',  'nch35 = ch35 - ( (ch10+ch21)/2 ) Label AFz',  'nch36 = ch36 - ( (ch10+ch21)/2 ) Label F1',...
        'nch37 = ch37 - ( (ch10+ch21)/2 ) Label F5',  'nch38 = ch38 - ( (ch10+ch21)/2 ) Label FT7',  'nch39 = ch39 - ( (ch10+ch21)/2 ) Label FC3',...
        'nch40 = ch40 - ( (ch10+ch21)/2 ) Label C1',  'nch41 = ch41 - ( (ch10+ch21)/2 ) Label C5',  'nch42 = ch42 - ( (ch10+ch21)/2 ) Label TP7',...
        'nch43 = ch43 - ( (ch10+ch21)/2 ) Label CP3',  'nch44 = ch44 - ( (ch10+ch21)/2 ) Label P1',  'nch45 = ch45 - ( (ch10+ch21)/2 ) Label P5',...
        'nch46 = ch46 - ( (ch10+ch21)/2 ) Label PO7',  'nch47 = ch47 - ( (ch10+ch21)/2 ) Label PO3',  'nch48 = ch48 - ( (ch10+ch21)/2 ) Label POz',...
        'nch49 = ch49 - ( (ch10+ch21)/2 ) Label PO4',  'nch50 = ch50 - ( (ch10+ch21)/2 ) Label PO8',  'nch51 = ch51 - ( (ch10+ch21)/2 ) Label P6',...
        'nch52 = ch52 - ( (ch10+ch21)/2 ) Label P2',  'nch53 = ch53 - ( (ch10+ch21)/2 ) Label CPz',  'nch54 = ch54 - ( (ch10+ch21)/2 ) Label CP4',...
        'nch55 = ch55 - ( (ch10+ch21)/2 ) Label TP8',  'nch56 = ch56 - ( (ch10+ch21)/2 ) Label C6',  'nch57 = ch57 - ( (ch10+ch21)/2 ) Label C2',...
        'nch58 = ch58 - ( (ch10+ch21)/2 ) Label FC4',  'nch59 = ch59 - ( (ch10+ch21)/2 ) Label FT8',  'nch60 = ch60 - ( (ch10+ch21)/2 ) Label F6',...
        'nch61 = ch61 - ( (ch10+ch21)/2 ) Label AF8',  'nch62 = ch62 - ( (ch10+ch21)/2 ) Label AF4',  'nch63 = ch63 - ( (ch10+ch21)/2 ) Label F2',...
        'nch64 = ch64 - ( (ch10+ch21)/2 ) Label FCz'} , 'ErrorMsg', 'popup', 'KeepLocations',  0, 'Warning', 'on' );
    pop_savemyerp(ERP, 'erpname',participant,'filename',new_file);

end

% Write files
filePh = fopen('file_list.txt','w');
fprintf(filePh,'%s\n',file_list{:});
fclose(filePh);

ERP = pop_gaverager( 'X:\EXPT\nd001\exp1\data\scripts\file_list.txt' , 'Criterion',  25, 'ExcludeNullBin', 'on', 'SEM', 'on' );
pop_savemyerp(ERP,'filename','grand.erp','erpname','grand_avgref');