%% Prepare Contrast-Task Data

% For each participant, this script:
% 1) Loads the 'contrast-change detection task' data.
% 2) Time-locks it based on wither the responses or stimuli. 
% 3) Pre-processes the single-trial data (high-pass filter, baseline-correction, artifact rejection).
% 4) Saves the time-locked ERP.

%% Load Variables

addpath C:\Users\Ayda\Downloads\fieldtrip-20220104; addpath 'D:\HBN Project'
load('D:\HBN Project\Miscellaneous\layout.mat')
load('D:\HBN Project\Miscellaneous\task_vars.mat')
load('D:\HBN Project\Miscellaneous\IDs_all_release_1.mat')

%% Define Parameters

lock_type = 'response';                        % Time-lock to stimulus or response? Options:'stimulus', 'response'.
response_window = 1300;                        % Acceptable window for response time (# of samples post-stimulus).
pre_stim = 1000;                               % Number of samples in pre-stimulus period.
post_stim = 150;                               % Number of samples in post-stimulus period.

lp_filter = 100;                               % Low-pass filter (in Hz).
baseline = [-.5 0];                            % Baseline window (in SECONDS).

art_chans = [50:60];                           % Channels to be examined during artifact rejection.
trial_reject = 100;                            % Rejection criteria (uV). Trials w/ absolute value grater than 'trial_reject' are removed. 

%% Collect data.

for subj = 17%:length(IDs)
    if exist(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\SAIIT_2AFC_Block1.mat']) %#ok<EXIST>       

        %%% Pre-process

        % Load Participant  
        tic
        fprintf('\nLoading subject %3.0f ...\n', subj)
        
        all_block_data = [];
        all_resp_times = [];

        for block = 1:3
            if exist(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\SAIIT_2AFC_Block',task_vars.block_names{block},'.mat']) %#ok<EXIST> 
                load(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\SAIIT_2AFC_Block',task_vars.block_names{block},'.mat'])          
    
                % Collect start time index.
                ind = strcmp({result.event.type},task_vars.block_starts{block}); 
                start_idx = result.event(ind).sample;
        
                % Collect trial indices.
                ind_1 = strcmp({result.event.type},task_vars.stim_triggers{1});   
                ind_2 = strcmp({result.event.type},task_vars.stim_triggers{2}); 
                trial_idx = [result.event(ind_1).sample,result.event(ind_2).sample];
    
                % Ensure that trials which exist before/after the block are not used.
                trial_idx(trial_idx < start_idx) = []; 
                block_end = [result.event.duration];
                trial_idx(trial_idx > block_end(1)) = [];
    
                % Collect response indices.
                ind_1 = strcmp({result.event.type},task_vars.resp_triggers{1});   
                ind_2 = strcmp({result.event.type},task_vars.resp_triggers{2}); 
                resp_idx = [result.event(ind_1).sample, result.event(ind_2).sample];
                
                % Remove trials with no response or more than one response.
                trial_idx = find_bad_trials(trial_idx,resp_idx,response_window);
    
                % Collect response times.
                resp_times = find_response_times(trial_idx,resp_idx, response_window);
        
                % Define trials
                switch lock_type 
                    case 'stimulus'; indexes = trial_idx;
                    case 'response'; indexes = trial_idx + resp_times';
                end
    
                block_data = zeros(size(result.data,1),(pre_stim + post_stim + 1),length(indexes));
                for trial_n = 1:length(indexes)
                    start_time = indexes(trial_n) - pre_stim;
                    end_time = indexes(trial_n) + post_stim;
                    block_data(:,:,trial_n) = result.data(:,start_time:end_time);
                end
    
                % Concatenate data across blocks. 
                all_block_data = cat(3,all_block_data,block_data);
                all_resp_times = [all_resp_times;resp_times]; %#ok<AGROW> 

            end
        end
     
        % Artifact rejection.
        bad_trials = [];
        for n_trial = 1:size(all_block_data,3)
            max_volt = max(abs(all_block_data(art_chans,:,n_trial)),[],2);
            if sum(max_volt > trial_reject) > 1                      
                bad_trials = [bad_trials,n_trial]; %#ok<AGROW> 
            end
        end
        all_block_data(:,:,bad_trials) = []; %#ok<SAGROW> 


        %%% Match Fieldtrip Structure
        
        data = [];

        % Specify channels.
        data.label = {result.chanlocs.labels};

        % Specify time.
        time = -(pre_stim/task_vars.srate):.002:(post_stim/task_vars.srate);  
        data.time = repelem({time},size(all_block_data,3));

        % Specify trials.
        trial_data = [];
        for tr = 1:size(all_block_data,3)
            trial_data = cat(2,trial_data,{all_block_data(:,:,tr)});
        end
        data.trial = trial_data;

        % Preprocess (filter, baseline-correct, time-lock) using Fieldtrip.
        cfg = [];
        cfg.lpfilter = 'yes';
        cfg.demean = 'yes';
        cfg.baselinewindow = baseline; 
        cfg.lpfreq = lp_filter;
        
        data = ft_preprocessing(cfg,data);

        ERP = ft_timelockanalysis([], data);    % Time-lock.
        ERP.resp_times = all_resp_times/500;    % Add response times to ERP structure.

        save(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\contrast_change_ERP'],'ERP')

    end
end
