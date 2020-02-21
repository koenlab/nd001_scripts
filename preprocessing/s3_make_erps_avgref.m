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
    eeg_file = 'set10_goodepochs_pre200blc_avgref_0.05-100bpf_500Hz.set';
    EEG = pop_loadset( eeg_file, par_sets_out_dir );
    
    % Sync Artifacts as trim in time delects EEG.reject.rejmanual
    cfg = [];
    cfg.direction = 'bidirectional';
    EEG = pop_syncroartifacts(EEG, 'Direction', cfg.direction);
    
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
    ERP.erpname  = 'erp1_30hzlpf_avgref_-200to0preblc';
    ERP.filename = sprintf('%s.erp',ERP.erpname);
    ERP.filepath = par_erps_out_dir;
    ERP.subject  = participant;
    pop_savemyerp( ERP );
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP,fullfile(par_erps_out_dir,'erp1_art_summary_30hzlpf_avgref_-200to0preblc.txt')); % This saves it to a file
    
    % Backup original ERP for re-use later on
    orig_ERP = ERP;
    
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
    pop_summary_AR_erp_detection(ERP,fullfile(par_erps_out_dir,'erp2_trialtype_art_summary_30hzlpf_avgref_-200to0preblc.txt')); % This saves it to a file
    
    % Make difference waves
    binop_equations = {
        'b4 = b2 - ((b1+b3)/2) label ac-(ab+de)', ...
        'b5 = b2 - b1 label ac-ab', ...
        'b6 = b2 - b3 label ac-de', ...
        'b7 = b1 - b2 label ab-de', ...
        };
    ERP = pop_binoperator( ERP, binop_equations);
    
    % Save ERP
    ERP.erpname  = 'erp2_trialtype_30hzlpf_avgref_-200to0preblc';
    ERP.filename = sprintf('%s.erp',ERP.erpname);
    ERP.filepath = par_erps_out_dir;
    ERP.subject  = participant;
    pop_savemyerp( ERP );
    
    %% Plots for Trial Type
    % Binned by trial type
    cfg = [];
    cfg.bins = 1:3; %AB, AC, DE
    cfg.channels = 1:ERP.nchan;
    cfg.blc        = '-200 0'; % Although this should already be done, make sure it is
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
    saveas(f,fullfile(par_fig_out_dir,'erp2_trialtype_ERPs_30hzlpf_avgref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % Plot the scalp plot
    cfg            = [];
    cfg.bins       = 4:7; % These are scenes - others, object - others, and face - others, respectively
    cfg.timepoints = [100:200:1000];
    cfg.value      = 'insta';
    cfg.maplimit   = 'maxmin';
    cfg.blc        = [-200 0]; % Although this should already be done, make sure it is
    cfg.colormap   = 'default';
    ERP = pop_scalplot( ERP, cfg.bins, cfg.timepoints , 'Blc', cfg.blc, 'Value', cfg.value, ....
        'Maplimit', cfg.maplimit, 'Colormap', cfg.colormap, 'Colorbar', 'on', ...
        'Electrodes', 'on', 'FontName', 'Courier New', 'FontSize',  16, ...
        'Legend', 'bd-la', 'Mapstyle', 'both', 'Maptype', '2D', 'Mapview', '+X', ...
        'maximize', 'on' );
   
    % Save this figure
    f = gcf;
    saveas(f,fullfile(par_fig_out_dir,'erp2_trialtype_diffwave_scalpmap.png'));
    if ~examine_figures, close(f); end
    
    %% Bin Operations for Subsequent Memory
    % Restore orig ERP
    ERP = orig_ERP;
    
    % Define bin operations equations and run binoperator
    binop_equations = {
        'nb1 = b11 label deHIT',...
        'nb2 = b12 label deMISS', ...
        'nb3 = wavgbin(b1,b2) label ab-ABHIT', ...
        'nb4 = wavgbin(b3,b4) label ab-ABMISS', ...
        'nb5 = wavgbin(b1,b3) label ab-ACHIT', ...
        'nb6 = wavgbin(b2,b4) label ab-ACMISS',...
        'nb7 = wavgbin(b6,b8) label ac-ACHIT',...
        'nb8 = wavgbin(b7,b9) label ac-ACMISS'...
        'nb9 = wavgbin(b6,b7) label ac-ABHIT', ...
        'nb10 = wavgbin(b8,b9) label ac-ABMISS' ...
        };
    ERP = pop_binoperator( ERP, binop_equations);
    
    % Export artifact summary to text file
    pop_summary_AR_erp_detection(ERP,''); % This prints it to the screen
    pop_summary_AR_erp_detection(ERP,fullfile(par_erps_out_dir,'erp3_sme_art_summary_30hzlpf_avgref_-200to0preblc.txt')); % This saves it to a file
    
    % Make difference waves
    binop_equations = {
        'b11 = b1 - b2 label deSME', ...
        'b12 = b3 - b4 label abAB-SME', ...
        'b13 = b5 - b6 label abAC-SME', ...
        'b14 = b7 - b8 label acAC-SME', ...
        'b15 = b9 - b10 label acAB-SME', ...
        };
    ERP = pop_binoperator( ERP, binop_equations);
    
    % Save ERP
    ERP.erpname  = 'erp3_sme_30hzlpf_avgref_-200to0preblc';
    ERP.filename = sprintf('%s.erp',ERP.erpname);
    ERP.filepath = par_erps_out_dir;
    ERP.subject  = participant;
    pop_savemyerp( ERP );
    
    %% Plots for DE Hits vs. Miss
    cfg = [];
    cfg.bins = 1:2;
    cfg.channels = 1:ERP.nchan;
    cfg.blc      = '-200 0'; % Although this should already be done, make sure it is
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
    saveas(f,fullfile(par_fig_out_dir,'erp3_sme_deHITvMISS_ERPs_30hzlpf_avgref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % Plot the scalp plot
    cfg            = [];
    cfg.bins       = 11; % These are scenes - others, object - others, and face - others, respectively
    cfg.timepoints = [100:200:1500];
    cfg.value      = 'insta';
    cfg.maplimit   = 'maxmin';
    cfg.blc        = [-200 0]; % Although this should already be done, make sure it is
    cfg.colormap   = 'default';
    ERP = pop_scalplot( ERP, cfg.bins, cfg.timepoints , 'Blc', cfg.blc, 'Value', cfg.value, ....
        'Maplimit', cfg.maplimit, 'Colormap', cfg.colormap, 'Colorbar', 'on', ...
        'Electrodes', 'on', 'FontName', 'Courier New', 'FontSize',  16, ...
        'Legend', 'bd-la', 'Mapstyle', 'both', 'Maptype', '2D', 'Mapview', '+X', ...
        'maximize', 'on' );
   
    % Save this figure
    f = gcf;
    saveas(f,fullfile(par_fig_out_dir,'erp3_deSME_diffwave_scalpmap.png'));
    if ~examine_figures, close(f); end
    
    %% Plots for AB Trials AB Hits vs. Miss
    cfg = [];
    cfg.bins = 3:4;
    cfg.channels = 1:ERP.nchan;
    cfg.blc      = '-200 0'; % Although this should already be done, make sure it is
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
    saveas(f,fullfile(par_fig_out_dir,'erp3_sme_abTrials_abHITvMISS_ERPs_30hzlpf_avgref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % Plot the scalp plot
    cfg            = [];
    cfg.bins       = 12; % These are scenes - others, object - others, and face - others, respectively
    cfg.timepoints = 100:200:1500;
    cfg.value      = 'insta';
    cfg.maplimit   = 'maxmin';
    cfg.blc        = [-200 0]; % Although this should already be done, make sure it is
    cfg.colormap   = 'default';
    ERP = pop_scalplot( ERP, cfg.bins, cfg.timepoints , 'Blc', cfg.blc, 'Value', cfg.value, ....
        'Maplimit', cfg.maplimit, 'Colormap', cfg.colormap, 'Colorbar', 'on', ...
        'Electrodes', 'on', 'FontName', 'Courier New', 'FontSize',  16, ...
        'Legend', 'bd-la', 'Mapstyle', 'both', 'Maptype', '2D', 'Mapview', '+X', ...
        'maximize', 'on' );
   
    % Save this figure
    f = gcf;
    saveas(f,fullfile(par_fig_out_dir,'erp3_abTrials_abSME_diffwave_scalpmap.png'));
    if ~examine_figures, close(f); end
    
    %% Plots for AB Trials AC Hits vs. Miss
    cfg = [];
    cfg.bins = 5:6;
    cfg.channels = 1:ERP.nchan;
    cfg.blc      = '-200 0'; % Although this should already be done, make sure it is
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
    saveas(f,fullfile(par_fig_out_dir,'erp3_sme_abTrials_abHITvMISS_ERPs_30hzlpf_avgref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % Plot the scalp plot
    cfg            = [];
    cfg.bins       = 13; 
    cfg.timepoints = 100:200:1500;
    cfg.value      = 'insta';
    cfg.maplimit   = 'maxmin';
    cfg.blc        = [-200 0]; % Although this should already be done, make sure it is
    cfg.colormap   = 'default';
    ERP = pop_scalplot( ERP, cfg.bins, cfg.timepoints , 'Blc', cfg.blc, 'Value', cfg.value, ....
        'Maplimit', cfg.maplimit, 'Colormap', cfg.colormap, 'Colorbar', 'on', ...
        'Electrodes', 'on', 'FontName', 'Courier New', 'FontSize',  16, ...
        'Legend', 'bd-la', 'Mapstyle', 'both', 'Maptype', '2D', 'Mapview', '+X', ...
        'maximize', 'on' );
   
    % Save this figure
    f = gcf;
    saveas(f,fullfile(par_fig_out_dir,'erp3_abTrials_acSME_diffwave_scalpmap.png'));
    if ~examine_figures, close(f); end
    
    %% Plots for AC Trials AC Hits vs. Miss
    cfg = [];
    cfg.bins = 7:8;
    cfg.channels = 1:ERP.nchan;
    cfg.blc      = '-200 0'; % Although this should already be done, make sure it is
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
    saveas(f,fullfile(par_fig_out_dir,'erp3_sme_acTrials_acHITvMISS_ERPs_30hzlpf_avgref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % Plot the scalp plot
    cfg            = [];
    cfg.bins       = 14; 
    cfg.timepoints = 100:200:1500;
    cfg.value      = 'insta';
    cfg.maplimit   = 'maxmin';
    cfg.blc        = [-200 0]; % Although this should already be done, make sure it is
    cfg.colormap   = 'default';
    ERP = pop_scalplot( ERP, cfg.bins, cfg.timepoints , 'Blc', cfg.blc, 'Value', cfg.value, ....
        'Maplimit', cfg.maplimit, 'Colormap', cfg.colormap, 'Colorbar', 'on', ...
        'Electrodes', 'on', 'FontName', 'Courier New', 'FontSize',  16, ...
        'Legend', 'bd-la', 'Mapstyle', 'both', 'Maptype', '2D', 'Mapview', '+X', ...
        'maximize', 'on' );
   
    % Save this figure
    f = gcf;
    saveas(f,fullfile(par_fig_out_dir,'erp3_acTrials_acSME_diffwave_scalpmap.png'));
    if ~examine_figures, close(f); end
    
    %% Plots for AC Trials AB Hits vs. Miss
    cfg = [];
    cfg.bins = 9:10;
    cfg.channels = 1:ERP.nchan;
    cfg.blc      = '-200 0'; % Although this should already be done, make sure it is
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
    saveas(f,fullfile(par_fig_out_dir,'erp3_sme_acTrials_abHITvMISS_ERPs_30hzlpf_avgref_-200to0preblc.png'));
    if ~examine_figures, close(f); end
    
    % Plot the scalp plot
    cfg            = [];
    cfg.bins       = 15; 
    cfg.timepoints = 100:200:1500;
    cfg.value      = 'insta';
    cfg.maplimit   = 'maxmin';
    cfg.blc        = [-200 0]; % Although this should already be done, make sure it is
    cfg.colormap   = 'default';
    ERP = pop_scalplot( ERP, cfg.bins, cfg.timepoints , 'Blc', cfg.blc, 'Value', cfg.value, ....
        'Maplimit', cfg.maplimit, 'Colormap', cfg.colormap, 'Colorbar', 'on', ...
        'Electrodes', 'on', 'FontName', 'Courier New', 'FontSize',  16, ...
        'Legend', 'bd-la', 'Mapstyle', 'both', 'Maptype', '2D', 'Mapview', '+X', ...
        'maximize', 'on' );
   
    % Save this figure
    f = gcf;
    saveas(f,fullfile(par_fig_out_dir,'erp3_acTrials_abSME_diffwave_scalpmap.png'));
    if ~examine_figures, close(f); end
    
end