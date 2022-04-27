function resp_times = find_response_times(good_trial_idx,resp_idx, response_window)

band = [good_trial_idx',(good_trial_idx + response_window)'];
r = resp_idx;
r = sort(r)';

resp_times = zeros(size(band,1),1);
for response = 1:length(r)
    in_band = and((r(response) > band(:,1)),(r(response) < band(:,2)));
    check = sum(in_band);
    if check == 1
        resp_times((in_band == 1)) = r(response) - good_trial_idx((in_band == 1));
    end
end


