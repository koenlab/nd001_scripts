% Update data in orig data with bad channels
    tsv_file = fullfile( par_data_eeg_directory, sprintf('%s_task-study_channels.tsv',participant) );
    opts     = detectImportOptions(tsv_file, 'FileType', 'text');
    chans    = readtable(tsv_file, opts);
    chans.status( ismember(chans.name, bad_chanlabels) ) = {'bad'};
    writetable( chans, tsv_file, 'FileType','text','Delimiter','\t');