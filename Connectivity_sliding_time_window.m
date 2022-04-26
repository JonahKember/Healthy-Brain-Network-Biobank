%% Load Participant Identifiers

IDs = readtable('D:\HBN Project\Phenotype Data\Importing Data\Participant_IDs.csv');  % Load csv file with participant IDs from Release 1 (2018).
IDs = IDs{:,1};
eye_chans = [8,14,20,24];                 % Define eye channels (E8, E14, E21, E25; see https://www.nature.com/articles/sdata201740).
scalp_chans = setdiff(1:111,eye_chans);   % Define scalp channels (exclude eye channels).
srate = 500;                              % Specify sampling rate (Hz).

%% Specify connectivity parameters

freq_bands = [1 3;4 7];                   % Specify frequency bands (Hz).
freq_names = {'delta','theta'};           % Specify frequency band names.
increments = [50,50];                     % For each freq-band, define number of samples between matrices at adjacent time-points (size of time-step, in samples).
time_windows = [2500,2500];               % For each freq-band, define size of time-window, in samples (+/- X; e.g., 1000 = 2000 sample window).

%% Estimate Connectivity

for subj = 1:length(IDs)
if exist(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\RestingState.mat']) %#ok<EXIST> 
    if ~ exist(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\adjmat_tensor',freq_names{f},'.mat']) %#ok<EXIST> 

    %% Preprocess

    % Load Participant  
    tic
    fprintf('\nLoading subject %3.0f ...\n', subj)
    load(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\RestingState.mat'])
    
    % Collect start time
    ind = strcmp({result.event.type},'90  ');   % Trigger 90: Start-time of resting-state task.
    start = result.event(ind).sample;
    
    % Define trials
    fprintf('Defining trials... \n')
    data = result.data(scalp_chans,start:end);

    % Calculate Surface Laplacian, normalize
    chan_locs = [[result.chanlocs.X]',[result.chanlocs.Y]',[result.chanlocs.Z]'];
    chan_locs = chan_locs(scalp_chans,:);
    surf_lap = laplacian_perrinX(data,chan_locs(:,1),chan_locs(:,3),chan_locs(:,3));
    result.data = normalize(surf_lap);

    %% Calculate connectivity

    fprintf('Calculating connectivity... \n')
    
    n_source = size(data,1);
    n_samples = size(data, 2);

    for f = 1:length(freq_bands)
        tic

        increment = increments(f);
        window = time_windows(f);
        freq_range = freq_bands(f,:); 
        time = start:increment:size(data,2);

        % Filter  
        transition = mean(freq_range) * 0.2;                                                                   
        freqs = [freq_range(1) - transition, freq_range(1), freq_range(2), freq_range(2) + transition];
        fir_n = kaiserord(freqs, [0 1 0], [0.1 0.05 0.1], srate);                                                                          
        fir_coef = fir1(fir_n, freq_range*2/srate, 'bandpass');
        

        % Calculate the instantaneous phase time-series using the Hilbert transform
        H_data = complex(zeros(n_source,n_samples));
        for kk = 1:n_source
          ts = zscore(data(kk,:));                        
          H_data(kk,:) = hilbert(filter(fir_coef, 1, ts));   
        end
        inst_phase = angle(H_data);
        
        
        % Calculate the phase-lag index adjacency matrices in a given sliding time-window
        adjmat_tensor = zeros(n_source,n_source,length(time));
        for n = 1:length(time)
            adjmat = zeros(n_source,n_source);
            ij =  nchoosek(1:n_source,2);
            t = time(n);
            for i = 1:length(ij)
                phase_diff = inst_phase(ij(i,1),t:(t + window)) - inst_phase(ij(i,2),t:(t + window));
                adjmat(ij(i,1),ij(i,2)) = abs(mean(sign(phase_diff)));
            end
            adjmat_tensor(:,:,n) = adjmat' + adjmat;
        end

        save(['D:\HBN Project\EEG Files\',IDs{subj},'\EEG\preprocessed\mat_format\adjmat_tensor',freq_names{f},'.mat'],'adjmat_tensor')     % Save adjmat.
        toc
    end
 
    end
end
end