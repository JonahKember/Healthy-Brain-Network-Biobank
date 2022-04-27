function good_trial_idx = find_bad_trials(trial_idx,resp_idx,response_window)

% Removes trials with no response or more than one response in the specified window following stimulus onset.
%
% Inputs: 
%
%   trial_idx = Index of trials.
%   resp_idx = Index of responses.
%   reponse_window = Number of samples following stimulus-onset in which a response will be kept.
%
% Output:
%
%   good_trial_idx = Index of good trials (no repeats or duplicates).
%

trial_idx = sort(trial_idx);
band = [trial_idx',(trial_idx + response_window)'];
r = resp_idx;
r = sort(r)';

trials_w_resp = [];
for response = 1:length(r)
    in_band = and((r(response) > band(:,1)),(r(response) < band(:,2)));
    check = sum(in_band);
    if check == 1
        trials_w_resp = [trials_w_resp;find(in_band == 1)]; %#ok<AGROW> 
    end
end

repeats = hist(trials_w_resp,unique(trials_w_resp)) > 1; %#ok<HIST> 
unique_sorted_trials = sort(unique(trials_w_resp));
bad_trials = unique_sorted_trials(repeats);

missing_resp = setdiff((1:length(trial_idx)),trials_w_resp);
trial_idx([missing_resp,bad_trials']) = [];
good_trial_idx = trial_idx;