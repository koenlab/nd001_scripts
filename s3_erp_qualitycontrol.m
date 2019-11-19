%% Stage 3: Perform Quality Control Analysis with ERPs %%

% Step 0: Load set10 (cleaned 0.1Hz HPF data from s2), trim time (-250 to 1500ms)
% Step 1: Artifact detection (epoch drift, peak-to-peak, manual inspect)
% Step 2: Generate ERPs
%    Drop EOG channels
%    Low-pass filter at 30Hz, order 2 (no DC removal)
% Step 3: Quality Control Analyses
%    Need n_trial/bin in a table as well sa topi-plots for...:
%    AB, AC, DE all in a plot
%    Bin by subsequent memory aka AB|ABhit vs. AB|ABmiss
%    Bin by conditional memory aka AB|AChit vs. AB|ACmiss
% Step 4: Grand average ERP for AB, AC, DE plot

%% Clear the workspace
clear all;
clc;

%% Add path to EEGLAB and run it (to get full path structure)
eeglab; 

%% Option to look at plots in detail
examine_figures = true; % If True, will keep to figures open to investigate. If False, will close the figures once saved.

%% Define main directories
% Directories
directories.top        = 'X:\EXPT\nd001\exp1\data';
directories.source     = fullfile(directories.top, 'sourcedata');
directories.derivative = fullfile(directories.top, 'derivatives');
directories.deriv_eeg  = fullfile(directories.derivative, 'eeg');
directories.spec_files = fullfile(directories.top, 'scripts', 'spec_files'); % Where specification files are stored

%% Run the participant selector
% Run participant selector GUI
participant_list       = participant_selector(directories.top);

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 0: Get some general information defined
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Print info to screen
    fprintf('Preprocessing data for %s:\n',participant);
    
    % Define directory structure in data
    par_data_directory      = fullfile( directories.top, participant );
    par_data_beh_directory  = fullfile( par_data_directory, 'beh' );
    par_data_eeg_directory  = fullfile( par_data_directory, 'eeg' );
    par_deriv_out_directory = fullfile( directories.deriv_eeg, 'task-study', participant );
    par_fig_out_directory   = fullfile( par_deriv_out_directory, 'figures' );
    par_sets_out_directory  = fullfile( par_deriv_out_directory, 'eeglab_sets' );
    par_erps_out_directory  = fullfile( par_deriv_out_directory, 'erplab_sets' );
    par_elist_out_directory = fullfile( par_erps_out_directory, 'event_lists' );
    
    % Load EEG set file
    eeg_file = 'set10_goodepochs_pre250blc_avgref_0.1hzhpf_500Hz.set';
    EEG      = pop_loadset( eeg_file, par_sets_out_directory );
    
    % Backup reject fields
    this_reject = EEG.reject;
    
    % Trim in time
    EEG = pop_select( EEG, 'time', [-.25 1.5]);
    EEG.reject = this_reject;
    
    % Sync Artifacts as trim in time delects EEG.reject.rejmanual
    cfg = [];
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
      
    % Create a 'backup' of the original data
    EEG_orig = EEG;       
    
    
    %% Step 1: Artifact Detection
    % Conduct linear drift detection
    cfg = [];
    cfg.flag = 3; % flag for artifact
    cfg.drift_threshold = 40; % Trheshold for a bad drift trial
    cfg.time_bin1 = [-250 -150]; % time bin in msecs for the first portion to detect drift. This is the first 100 ms
    cfg.time_bin2 = [1400 1498]; % time bin in msecs for the second portion to detect drift. This is the last 100 ms
    cfg.chans = find( ~ismember( {EEG.chanlocs.labels}, {'VEOG' 'HEOG'} ) );
    tbin1_mean = squeeze( mean( EEG.data(cfg.chans, ismember(EEG.times,cfg.time_bin1(1):EEG.srate:cfg.time_bin1(2)) , :), 2) );
    tbin2_mean = squeeze( mean( EEG.data(cfg.chans, ismember(EEG.times,cfg.time_bin2(1):EEG.srate:cfg.time_bin2(2)) , :), 2) );
    delta_mean = abs(tbin1_mean - tbin2_mean);
    is_drift_art = delta_mean > cfg.drift_threshold;
    for triali = 1:size(delta_mean)
        this_trial = is_drift_art(:,triali);
        if any(this_trial)
            EEG = markartifacts(EEG, [1 cfg.flag], 1:EEG.nbchan, find(this_trial), triali, 0, 0);
        end
    end
    
    %% Step 2: Make ERP set
    cfg = [];
    cfg.criterion = 'good'; % Only average Good trials
    cfg.DQ_flag   = 1; % Reject all trials with an artifact
    cfg.SEM       = 'on'; 
    ERP = pop_averager( EEG, 'Criterion', cfg.criterion, 'DQ_flag', cfg.DQ_flag, 'SEM', cfg.SEM);
    
    % Remove ERP channels, then add back in channel locs
    cfg = [];
    cfg.function      = {'delerpchan( 65 66)'}; % Removes VEOG and HEOG channels
    cfg.keeplocations = 1;
    cfg.errormsg      = 'popup';
    cfg.warning       = 'on';
    ERP = pop_erpchanoperator( ERP, cfg.function , 'ErrorMsg', cfg.errormsg, ...
        'KeepLocations',  cfg.keeplocations, 'Warning', cfg.warning );
    ERP.binerror(65:66,:,:) = [];
    
    % Add channel locations back
    ERP.chanlocs = EEG.chanlocs(~ismember( {EEG.chanlocs.labels}, {'VEOG' 'HEOG'} ) ); % Ignore the VEOG and HEOG
    
    % Low pass filter ERP at 30Hz
    cfg = [];
    cfg.chans    = 1:ERP.nchan; % Apply to all channels
    cfg.filter   = 'lowpass';
    cfg.design   = 'butter';
    cfg.cutoff   = 30;
    cfg.order    = 2;
    cfg.removedc = 'off';
    ERP = pop_filterp( ERP, cfg.chans, ...
        'Filter',   cfg.filter, ...
        'Design',  cfg.design, ...
        'Cutoff',   cfg.cutoff, ...
        'Order',    cfg.order, ...
        'RemoveDC', cfg.removedc );     
    
    % Save filtered ERP
    ERP.erpname  = 'erp_30hzlpf_-250to1500_avgref_preblc';
    ERP.filename = sprintf('%s.erp',ERP.erpname);
    ERP.filepath = par_erps_out_directory;
    ERP.subject  = participant; 
    pop_savemyerp( ERP );
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP,fullfile(par_erps_out_directory,'erp_artifact_summary.txt')); % This saves it to a file
    
    % Backup original ERP for re-use later on
    orig_ERP = ERP;
    
    %% Step 3: Bin Operations
    % Define cell array of equations and run binoperator
    % In the input ERP set:
    %   b1-5   = ab trials
    %   b6-10  = ac trials
    %   b11-13  = de trials 
    %   b14-16 = bad trials
    binop_equations = {
        'b17 = wavgbin(b1,b2) label ab-ABHIT', ...
        'b18 = wavgbin(b3,b4) label ab-ABMISS', ...
        'b19 = wavgbin(b6,b8) label ac-ACHIT',...
        'b20 = wavgbin(b7,b9) label ac-ACMISS', ...
        'b21 = wavgbin(b17,b18) label ab', ...
        'b22 = wavgbin(b19,b20) label ac',...
        'b23 = wavgbin(b11,b12) label de', ...
        'b24 = wavgbin(b1,b3) label ab-ACHIT', ...
        'b25 = wavgbin(b2,b4) label ab-ACMISS',...
        'b26 = wavgbin(b6,b7) label ac-ABHIT', ...
        'b27 = wavgbin(b8,b9) label ac-ABMISS',...
        };
    ERP = pop_binoperator( ERP, binop_equations);
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP,fullfile(par_erps_out_directory,'erp_artifact_summary.txt')); % This saves it to a file
    
    % Save ERP 
    ERP.erpname  = 'erp_30hzlpf_-250to1500_avgref_preblc_binop';
    ERP.filename = sprintf('%s.erp',ERP.erpname);
    ERP.filepath = par_erps_out_directory;
    ERP.subject  = participant; 
    pop_savemyerp( ERP );
    
    %% Step 4: Topo Plots
    % Binned by trial type
    cfg = [];
    cfg.bins = 21:23; % This is the scene and object bins, respectively
    cfg.channels = 1:ERP.nchan;
    cfg.blc        = 'pre'; % Although this should already be done, make sure it is
    ERP = pop_ploterps( ERP,  cfg.bins,  cfg.channels , 'Blc', cfg.blc, ....
        'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'ChLabel', 'on',...
        'FontSizeChan',  16, 'FontSizeLeg',  16, 'FontSizeTicks',  14, 'LegPos', 'bottom', ...
        'Linespec', {'k-' , 'r-' , 'b-' }, 'LineWidth',  1.5, ...
        'Style', 'Topo', 'Tag', 'ERP Traces', 'Transparency',  0,  ....
        'xscale', [ -200.0 1498.0   -200:100:1500 ], 'YDir', 'normal', ...
        'maximize','on');
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_directory,'erp_trialtype_ERP_topo.png'));
    if ~examine_figures, close(f); end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % AB trials binned by subsequent memory aka AB|ABhit vs. AB|ABmiss
    cfg = [];
    cfg.bins = 17:18; % This is the scene and object bins, respectively
    cfg.channels = 1:ERP.nchan;
    cfg.blc        = 'pre'; % Although this should already be done, make sure it is
    ERP = pop_ploterps( ERP,  cfg.bins,  cfg.channels , 'Blc', cfg.blc, ....
        'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'ChLabel', 'on',...
        'FontSizeChan',  16, 'FontSizeLeg',  16, 'FontSizeTicks',  14, 'LegPos', 'bottom', ...
        'Linespec', {'k-' , 'r-' , 'b-' }, 'LineWidth',  1.5, ...
        'Style', 'Topo', 'Tag', 'ERP Traces', 'Transparency',  0,  ....
        'xscale', [ -200.0 1498.0   -200:100:1500 ], 'YDir', 'normal', ...
        'maximize','on');
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_directory,'erp_AB_SME-AB_ERP_topo.png'));
    if ~examine_figures, close(f); end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % AC trials binned by subsequent memory aka AC|AChit vs. AC|ACmiss
    cfg = [];
    cfg.bins = 19:20; % This is the scene and object bins, respectively
    cfg.channels = 1:ERP.nchan;
    cfg.blc        = 'pre'; % Although this should already be done, make sure it is
    ERP = pop_ploterps( ERP,  cfg.bins,  cfg.channels , 'Blc', cfg.blc, ....
        'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'ChLabel', 'on',...
        'FontSizeChan',  16, 'FontSizeLeg',  16, 'FontSizeTicks',  14, 'LegPos', 'bottom', ...
        'Linespec', {'k-' , 'r-' , 'b-' }, 'LineWidth',  1.5, ...
        'Style', 'Topo', 'Tag', 'ERP Traces', 'Transparency',  0,  ....
        'xscale', [ -200.0 1498.0   -200:100:1500 ], 'YDir', 'normal', ...
        'maximize','on');
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_directory,'erp_AC_SME-AC_ERP_topo.png'));
    if ~examine_figures, close(f); end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % DE trials binned by subsequent memory aka DE|DEhit vs. DE|DEmiss
    cfg = [];
    cfg.bins = 11:12; % This is the scene and object bins, respectively
    cfg.channels = 1:ERP.nchan;
    cfg.blc        = 'pre'; % Although this should already be done, make sure it is
    ERP = pop_ploterps( ERP,  cfg.bins,  cfg.channels , 'Blc', cfg.blc, ....
        'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'ChLabel', 'on',...
        'FontSizeChan',  16, 'FontSizeLeg',  16, 'FontSizeTicks',  14, 'LegPos', 'bottom', ...
        'Linespec', {'k-' , 'r-' , 'b-' }, 'LineWidth',  1.5, ...
        'Style', 'Topo', 'Tag', 'ERP Traces', 'Transparency',  0,  ....
        'xscale', [ -200.0 1498.0   -200:100:1500 ], 'YDir', 'normal', ...
        'maximize','on');
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_directory,'erp_DE_SME-DE_ERP_topo.png'));
    if ~examine_figures, close(f); end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Bin by conditional memory aka AB|AChit vs. AB|ACmiss
    cfg = [];
    cfg.bins = 24:25; % This is the scene and object bins, respectively
    cfg.channels = 1:ERP.nchan;
    cfg.blc        = 'pre'; % Although this should already be done, make sure it is
    ERP = pop_ploterps( ERP,  cfg.bins,  cfg.channels , 'Blc', cfg.blc, ....
        'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'ChLabel', 'on',...
        'FontSizeChan',  16, 'FontSizeLeg',  16, 'FontSizeTicks',  14, 'LegPos', 'bottom', ...
        'Linespec', {'k-' , 'r-' , 'b-' }, 'LineWidth',  1.5, ...
        'Style', 'Topo', 'Tag', 'ERP Traces', 'Transparency',  0,  ....
        'xscale', [ -200.0 1498.0   -200:100:1500 ], 'YDir', 'normal', ...
        'maximize','on');
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_directory,'erp_AB_SME-AC_ERP_topo.png'));
    if ~examine_figures, close(f); end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Bin by conditional memory aka AC|ABhit vs. AC|ABmiss
    cfg = [];
    cfg.bins = 26:27; % This is the scene and object bins, respectively
    cfg.channels = 1:ERP.nchan;
    cfg.blc        = 'pre'; % Although this should already be done, make sure it is
    ERP = pop_ploterps( ERP,  cfg.bins,  cfg.channels , 'Blc', cfg.blc, ....
        'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'ChLabel', 'on',...
        'FontSizeChan',  16, 'FontSizeLeg',  16, 'FontSizeTicks',  14, 'LegPos', 'bottom', ...
        'Linespec', {'k-' , 'r-' , 'b-' }, 'LineWidth',  1.5, ...
        'Style', 'Topo', 'Tag', 'ERP Traces', 'Transparency',  0,  ....
        'xscale', [ -200.0 1498.0   -200:100:1500 ], 'YDir', 'normal', ...
        'maximize','on');
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_directory,'erp_AC_SME-AB_ERP_topo.png'));
    if ~examine_figures, close(f); end
    
end