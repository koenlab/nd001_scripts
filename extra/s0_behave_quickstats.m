%% QUICK OVERVIEW OF PARTICIPANT INDIVIDUAL STATS (TO CHECK PERFORMANCE) %%


%% Clear the workspace
clear all;
clc;

%% Define main directories
% Directories
directories.top        = 'X:\EXPT\nd001\exp1\data';
directories.source     = fullfile(directories.top, 'sourcedata');
directories.data       = fullfile(directories.top, 'data');
directories.derivative = fullfile(directories.top, 'derivatives');

participant_list = participant_selector(directories.source);

%% Loop through participants
for sub = 1:length(participant_list)
    
% Load test data
maindir = 'X:\EXPT\nd001\exp1\data\data';
filename = fullfile(maindir,sprintf('sub-%d',sub),'beh',sprintf('sub-%d_task-test_beh.tsv',sub));
test_data = readtable(filename, ...
    'Delimiter','\t','FileType','Text');

% Get Vectors of Interest
abac = ismember( test_data.item_type, 'abac' );
de   = ismember( test_data.item_type, 'de'   );
new  = ismember( test_data.item_type, 'new'  );

% Tasks
t1_art = ismember( test_data.task1, 'artist'   );
t1_fun = ismember( test_data.task1, 'function' );
t1_pls = ismember( test_data.task1, 'pleasant' );
t1_vac = ismember( test_data.task1, 'vacation' );
t2_art = ismember( test_data.task2, 'artist'   );
t2_fun = ismember( test_data.task2, 'function' );
t2_pls = ismember( test_data.task2, 'pleasant' );
t2_vac = ismember( test_data.task2, 'vacation' );

% Responses
old_resp = ismember( test_data.on_resp, 'old' );
art_resp = test_data.artist_resp;
fun_resp = test_data.function_resp;
pls_resp = test_data.pleasant_resp;
vac_resp = test_data.vacation_resp;
n_s_resp = test_data.n_sources_sel;
de_bad   = de & n_s_resp == 2;

% Old/New Performance
abac_hits = sum( abac & old_resp ) / sum( abac );
de_hits   = sum( de   & old_resp & ~de_bad ) / sum( de & ~de_bad );
new_fa    = sum( new  & old_resp ) / sum( new  );
fprintf(' ABAC:\t%2.4f \n DE:\t%2.4f \n FA:\t%2.4f \n', [abac_hits de_hits new_fa]);

% Source N Hit
abac_n_old = sum( abac & old_resp );
de_n_old   = sum( de   & old_resp & ~de_bad ) ;
ab_source_hit = ...
    ( abac & t1_art & art_resp ) | ...
    ( abac & t1_fun & fun_resp ) | ...
    ( abac & t1_pls & pls_resp ) | ...
    ( abac & t1_vac & vac_resp );
ac_source_hit = ...
    ( abac & t2_art & art_resp ) | ...
    ( abac & t2_fun & fun_resp ) | ...
    ( abac & t2_pls & pls_resp ) | ...
    ( abac & t2_vac & vac_resp );
de_source_hit = ...
    ( de & t1_art & art_resp ) | ...
    ( de & t1_fun & fun_resp ) | ...
    ( de & t1_pls & pls_resp ) | ...
    ( de & t1_vac & vac_resp ) & ...
    ~de_bad;

% Proportion Source Hit
ab_p_source_acc = sum( ab_source_hit ) / sum( abac_n_old );
ac_p_source_acc = sum( ac_source_hit ) / sum( abac_n_old );
de_p_source_acc = sum( de_source_hit ) / sum( de_n_old   );
fprintf(' AB:\t%2.4f \n AC:\t%2.4f \n DE:\t%2.4f \n', [ab_p_source_acc ac_p_source_acc de_p_source_acc]);


% ABAC Grid and Conditional
abac_hh = sum( abac & ab_source_hit & ac_source_hit & old_resp );
abac_hm = sum( abac & ab_source_hit & ~ac_source_hit & old_resp );
abac_mh = sum( abac & ~ab_source_hit & ac_source_hit & old_resp );
abac_mm = sum( abac & ~ab_source_hit & ~ac_source_hit & old_resp );
fprintf(' HH:\t%d \n HM:\t%d \n MH:\t%d \n MM:\t%d \n', ...
    [abac_hh abac_hm abac_mh abac_mm]);

% Conditional proportions
ab_acc_ac_hit  = abac_hh / ( abac_hh + abac_mh );
ab_acc_ac_miss = abac_hm / ( abac_hm + abac_mm );
ac_acc_ab_hit  = abac_hh / ( abac_hh + abac_hm );
ac_acc_ab_miss = abac_mh / ( abac_mh + abac_mm );
fprintf(' p(AB|AC Hit):\t%2.4f\n', ab_acc_ac_hit );
fprintf(' p(AB|AC Miss):\t%2.4f\n', ab_acc_ac_miss );
fprintf(' p(AC|AB Hit):\t%2.4f\n', ac_acc_ab_hit );
fprintf(' p(AC|AB Miss):\t%2.4f\n', ac_acc_ab_miss );
fprintf(' p(DE):\t\t\t%2.4f\n', de_p_source_acc );

end %end of participant loop
