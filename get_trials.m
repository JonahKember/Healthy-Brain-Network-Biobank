function [trial_idx, resp_idx, resp_times] = get_trials(result,block,response_window)

stim_triggers = {'8   ','9   '};
resp_triggers = {'12  ','13  '};
block_starts = {'94  ','95  ','96  '};

% Collect start time index.
ind = strcmp({result.event.type},block_starts{block}); 
start_idx = result.event(ind).sample;

% Collect trial indices.
ind_1 = strcmp({result.event.type},stim_triggers{1});   
ind_2 = strcmp({result.event.type},stim_triggers{2}); 
trial_idx = [result.event(ind_1).sample,result.event(ind_2).sample];

% Ensure that trials which exist before/after the block are not used.
trial_idx(trial_idx < start_idx) = []; 
block_end = [result.event.duration];
trial_idx(trial_idx > block_end(1)) = [];

% Collect response indices.
ind_1 = strcmp({result.event.type},resp_triggers{1});   
ind_2 = strcmp({result.event.type},resp_triggers{2}); 
resp_idx = [result.event(ind_1).sample, result.event(ind_2).sample];

% Remove trials with no response or more than one response.
trial_idx = find_bad_trials(trial_idx,resp_idx,response_window);

% Collect response times.
resp_times = find_response_times(trial_idx,resp_idx, response_window);
end
