%% Compare ERPs generated with and without epoch drift removal %%

%% Clear the workspace
clear all;
clc;

%% Option to look at plots in detail
examine_figures = false; % If True, will keep to figures open to investigate. If False, will close the figures once saved.

%% Define main directories
% Directories
directories.top         = 'X:\EXPT\nd001\exp1\data';
directories.raw         = fullfile(directories.top, 'raw_bids');
directories.source      = fullfile(directories.raw, 'sourcedata');
directories.preproc     = fullfile(directories.top, 'preprocessed', 'task-study');
directories.preproc_beh = fullfile(directories.preproc, 'beh');
directories.preproc_eeg = fullfile(directories.preproc, 'eeg');
directories.scripts     = fullfile(directories.top, 'scripts');
directories.spec_files  = fullfile(directories.scripts, 'spec_files'); % Where specification files are stored
directories.functions   = fullfile(directories.scripts, 'functions');

% Add directories.functions to path
addpath(directories.functions);

%% Run the participant selector
% Run participant selector GUI
participant_list       = participant_selector(directories.preproc_eeg);

%% Loop through participants
for pari = 1:length(participant_list)
    
    %% Step 0: Get some general information defined
    %% Add path to EEGLAB and run it (to get full path structure)
    eeglab; 
    
    % Convert participant to char type
    participant = participant_list{pari};
    
    % Print info to screen
    fprintf('Preprocessing data for %s:\n',participant);
    
    % Make directory structure in data
    par_data_dir        = fullfile( directories.raw, participant );
    par_data_beh_dir    = fullfile( par_data_dir, 'beh' );
    par_data_eeg_dir    = fullfile( par_data_dir, 'eeg' );
    par_preproc_out_dir = fullfile( directories.preproc_eeg, participant );
    par_fig_out_dir     = fullfile( par_preproc_out_dir, 'figures' );
    par_sets_out_dir    = fullfile( par_preproc_out_dir, 'eeglab_sets' );
    par_erps_out_dir    = fullfile( par_preproc_out_dir, 'erplab_sets' );
    par_elist_out_dir   = fullfile( par_preproc_out_dir, 'event_lists' );
    
    % Load EEG set file
    eeg_file = 'set11_goodepochs_pre200blc_mastoidref_0.05-100bpf_500Hz.set';
    EEG = pop_loadset( eeg_file, par_sets_out_dir );
    
    % Sync Artifacts as trim in time delects EEG.reject.rejmanual
    cfg = [];
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    
    % Backup original EEG for re-use later on
    orig_EEG = EEG;
    
     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% NO ARTIFACT DETECTION
    %% Step 2: Make ERP set
    cfg = [];
    cfg.criterion = 'good'; % Only average Good trials
    cfg.DQ_flag   = 1; % Reject all trials with an artifact
    cfg.SEM       = 'on';
    ERP2 = pop_averager( EEG, 'Criterion', cfg.criterion, 'DQ_flag', cfg.DQ_flag, 'SEM', cfg.SEM);
    
    % Remove EOG channels, then add back in channel locs
    cfg = [];
    cfg.function      = {'delerpchan( 65 66)'}; % Removes VEOG and HEOG channels
    cfg.keeplocations = 1;
    cfg.errormsg      = 'popup';
    cfg.warning       = 'on';
    ERP2 = pop_erpchanoperator( ERP2, cfg.function , 'ErrorMsg', cfg.errormsg, ...
        'KeepLocations',  cfg.keeplocations, 'Warning', cfg.warning );
    ERP2.binerror(65:66,:,:) = [];
    
    % Add channel locations back
    ERP2.chanlocs = EEG.chanlocs(~ismember( {EEG.chanlocs.labels}, {'VEOG' 'HEOG'} ) ); % Ignore the VEOG and HEOG
    
    % Low pass filter ERP at 30Hz
    cfg = [];
    cfg.chans    = 1:ERP2.nchan; % Apply to all channels
    cfg.filter   = 'lowpass';
    cfg.design   = 'butter';
    cfg.cutoff   = 30;
    cfg.order    = 2;
    cfg.removedc = 'off';
    ERP2 = pop_filterp( ERP2, cfg.chans, ...
        'Filter',   cfg.filter, ...
        'Design',  cfg.design, ...
        'Cutoff',   cfg.cutoff, ...
        'Order',    cfg.order, ...
        'RemoveDC', cfg.removedc );
    
    % Save filtered ERP
    ERP2.erpname  = 'erpVS_30hzlpf_mastoidref_-200to0preblc_nodriftremoved';
    ERP2.filename = sprintf('%s.erp',ERP2.erpname);
    ERP2.filepath = par_erps_out_dir;
    ERP2.subject  = participant;
    pop_savemyerp( ERP2 );
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP2,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP2,fullfile(par_erps_out_dir,'erp4_art_summary_30hzlpf_mastoidref_-200to0preblc.txt')); % This saves it to a file
    
    %% Step 3: Bin Operations for Trial Type
    % Define cell array of equations and run binoperator
    % In the input ERP set:
    %   b1-5   = ab trials
    %   b6-10  = ac trials
    %   b11-13  = de trials
    %   b14-16 = bad trials
    binop_equations = {
        'nb1 = wavgbin(b1,b2,b3,b4) label ab', ...
        'nb2 = wavgbin(b5,b6,b7,b8) label ac',...
        'nb3 = wavgbin(b11,b12) label de', ...
        };
    ERP2 = pop_binoperator( ERP2, binop_equations);
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP2,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP2,fullfile(par_erps_out_dir,'erpVS_trialtype_art_summary_30hzlpf_mastoidref_-200to0preblc_nodriftremoved.txt')); % This saves it to a file
    
    % Save ERP
    ERP2.erpname  = 'erpVS_trialtype_30hzlpf_mastoidref_-200to0preblc_nodriftremoved';
    ERP2.filename = sprintf('%s.erp',ERP2.erpname);
    ERP2.filepath = par_erps_out_dir;
    ERP2.subject  = participant;
    pop_savemyerp( ERP2 );
    
    %% WITH EPOCH DRIFT REMOVAL  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Step 1: Artifact Detection
    % Conduct linear drift detection
    cfg = [];
    cfg.flag = 3; % flag for artifact
    cfg.drift_threshold = 40; % Threshold for a bad drift trial
    cfg.time_bin1 = [-200 -2]; % time bin in msecs for the first portion to detect drift. This is the first 100 ms
    cfg.time_bin2 = [1300 1498]; % time bin in msecs for the second portion to detect drift. This is the last 100 ms
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
    
    % Print to screen
    pop_summary_AR_eeg_detection(EEG,'');
    
    %% Step 2: Make ERP set
    % Compute averaged ERPs based on certain configurations
    cfg = [];
    cfg.criterion = 'good'; % Only average Good trials
    cfg.DQ_flag   = 1; % Reject all trials with an artifact
    cfg.SEM       = 'on';
    ERP = pop_averager( EEG, 'Criterion', cfg.criterion, 'DQ_flag', cfg.DQ_flag, 'SEM', cfg.SEM);
    
    % Remove EOG channels, then add back in channel locs
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
    ERP.erpname  = 'erpVS_30hzlpf_mastoidref_-200to0preblc_driftremoved';
    ERP.filename = sprintf('%s.erp',ERP.erpname);
    ERP.filepath = par_erps_out_dir;
    ERP.subject  = participant;
    pop_savemyerp( ERP );
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP,fullfile(par_erps_out_dir,'erpVS_art_summary_30hzlpf_mastoidref_-200to0preblc.txt')); % This saves it to a file
    
    %% Step 3: Bin Operations for Trial Type
    % Define cell array of equations and run binoperator
    % In the input ERP set:
    %   b1-5   = ab trials
    %   b6-10  = ac trials
    %   b11-13  = de trials
    %   b14-16 = bad trials
    binop_equations = {
        'nb1 = wavgbin(b1,b2,b3,b4) label ab', ...
        'nb2 = wavgbin(b5,b6,b7,b8) label ac',...
        'nb3 = wavgbin(b11,b12) label de', ...
        };
    ERP = pop_binoperator( ERP, binop_equations);
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP,fullfile(par_erps_out_dir,'erpVS_trialtype_art_summary_30hzlpf_mastoidref_-200to0preblc_driftremoved.txt')); % This saves it to a file
    
    % Save ERP
    ERP.erpname  = 'erpVS_trialtype_30hzlpf_mastoidref_-200to0preblc_driftremoved';
    ERP.filename = sprintf('%s.erp',ERP.erpname);
    ERP.filepath = par_erps_out_dir;
    ERP.subject  = participant;
    pop_savemyerp( ERP );
    
    %% Append data sets
    erplab redraw
    ALLERP(2) = ERP2;
    ERP = pop_appenderp( ALLERP , 'Erpsets', [ 1 2] );
    
    %% Plots for Trial Type
    % AB
    ERP = pop_ploterps( ERP, [ 1 4],  1:64 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', '-200    0', 'Box', [ 8 8], 'ChLabel',...
 'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1,...
 'Maximize', 'on', 'Position', [ 103.714 29.6429 106.857 31.9286], 'Style', 'Topo', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale',...
 [ -200.0 1998.0   -200:100:1500 ], 'YDir', 'normal' );
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_dir,'erpVS_AB_ERPs_30hzlpf_mastoidref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % AC
    ERP = pop_ploterps( ERP, [ 2 5],  1:64 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', '-200    0', 'Box', [ 8 8], 'ChLabel',...
 'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1,...
 'Maximize', 'on', 'Position', [ 103.714 29.6429 106.857 31.9286], 'Style', 'Topo', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale',...
 [ -200.0 1998.0   -200:100:1500 ], 'YDir', 'normal' );
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_dir,'erpVS_AC_ERPs_30hzlpf_mastoidref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % DE
    ERP = pop_ploterps( ERP, [ 3 6],  1:64 , 'AutoYlim', 'on', 'Axsize', [ 0.05 0.08], 'BinNum', 'on', 'Blc', '-200    0', 'Box', [ 8 8], 'ChLabel',...
 'on', 'FontSizeChan',  10, 'FontSizeLeg',  12, 'FontSizeTicks',  10, 'LegPos', 'bottom', 'Linespec', {'k-' , 'r-' }, 'LineWidth',  1,...
 'Maximize', 'on', 'Position', [ 103.714 29.6429 106.857 31.9286], 'Style', 'Topo', 'Tag', 'ERP_figure', 'Transparency',  0, 'xscale',...
 [ -200.0 1998.0   -200:100:1500 ], 'YDir', 'normal' );
    
    % Save this figure
    f = gcf;
    f.Position = [500 50 1100 1000];
    f.PaperPositionMode = 'auto';
    saveas(f,fullfile(par_fig_out_dir,'erpVS_DE_ERPs_30hzlpf_mastoidref_-200to0preblc.png'));
    if ~examine_figures, close(f); end

end
    