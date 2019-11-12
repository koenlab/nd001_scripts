 % Flag to run automated methods
    run_auto = false;
    
    % Start the while loop
    while true
    
        % Run automated routines
        if run_auto
            
            % Initialize output variable
            preica_art_epochs = struct();
            
            % Extreme values Threshold
            cfg = [];
            cfg.type       = 1; % Raw Data
            cfg.chans      = 1:EEG_forerp.nbchan; % Only on EEG channels
            cfg.lowthresh  = -500;
            cfg.highthresh = 500;
            cfg.starttime  = EEG_forerp.xmin;
            cfg.endtime    = EEG_forerp.xmax; % Equates to 2 seconds
            cfg.superpose  = 1;
            cfg.reject     = 0; % Do not reject epochs
            EEG_forerp = pop_eegthresh( EEG_forerp, cfg.type, cfg.chans, cfg.lowthresh, cfg.highthresh, ...
                cfg.starttime, cfg.endtime, cfg.superpose, cfg.reject);
            preica_art_epochs.thresh = find(EEG_forerp.reject.rejthresh);
            
            % Joint Probability
            cfg = [];
            cfg.type         = 1; % Raw Data
            cfg.chans        = 1:EEG_forerp.nbchan; % Same as extreme values
            cfg.locthresh    = 4;
            cfg.globalthresh = 4;
            cfg.superpose    = 1;
            cfg.reject       = 0; % Do not reject epochs
            EEG_forerp = pop_jointprob(EEG_forerp, cfg.type, cfg.chans, cfg.locthresh, cfg.globalthresh, ...
                cfg.superpose, cfg.reject, [], 1 );
            preica_art_epochs.jointprob = find(EEG_forerp.reject.rejjp); % Get the indicies
            
            % Kurtosis
            cfg.type         = 1; % Raw Data
            cfg.chans        = 1:EEG_forerp.nbchan; % Same as extreme values
            cfg.locthresh    = 5;
            cfg.globalthresh = 5;
            cfg.superpose    = 1;
            cfg.reject       = 0; % Do not reject epochs =
            EEG_forerp = pop_rejkurt(EEG_forerp, cfg.type, cfg.chans, cfg.locthresh, cfg.globalthresh, ...
                cfg.superpose, cfg.reject, [] );
            preica_art_epochs.kurtosis = find(EEG_forerp.reject.rejkurt); % Get the indicies
            
            % Run auto update
            run_auto = false;
            
        end
        
        % Try pop_eegplot
        EEG_forerp.reject.rejmanual  = (EEG_forerp.reject.rejthresh + EEG_forerp.reject.rejjp + EEG_forerp.reject.rejkurt) > 0;
        EEG_forerp.reject.rejmanualE = (EEG_forerp.reject.rejthreshE + EEG_forerp.reject.rejjpE + EEG_forerp.reject.rejkurtE) > 0;
        pop_eegplot( EEG_forerp, 1, 1, 0 );
        waitfor( findobj('parent', gcf, 'string', 'UPDATE MARKS'), 'userdata');
        
        % Ask if we are OK with results
        clear_bads = questdlg('Do you need to re-inspect the epochs (or did you forget to hit UPDATE MARKS)?');
        if strcmpi(clear_bads,'no')
            break;
        else
            rerun_auto = questdlg('You want to look at the data again. Do you want to re-run the automated methods?');
            if strcmpi(rerun_auto,'yes')
                run_auto = true;
            end
        end
        
    end