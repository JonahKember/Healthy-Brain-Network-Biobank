%% Load and Untar Raw Data

IDs = readtable('D:\HBN Project\Phenotype Data\Importing Data\Participant_IDs.csv'); IDs = IDs{:,1};  % Load csv file with participant IDs from Release 1 (2018).
storage_location = 'D:\HBN Project\EEG Files';                              % Specify where data is to be stored.
raw_data_location = 'D:\HBN Project\Raw EEG Files\';                        % Specify file locaton of raw data.

for n = 1:length(IDs)     
    if ~exist([storage_location,'\',IDs{n}], 'dir')                         % Only load participants that haven't been loaded yet.
        if exist([raw_data_location,IDs{n},'.tar'],'file')                  % Only load participants that have been downloaded already.
            tic

            fprintf('Loading participant # %3.0f \n',n)
            untar([raw_data_location,IDs{n},'.tar'],storage_location)       % Untar and store data.
            toc
        end
    end
    if exist([storage_location,'\',IDs{n}], 'dir') 
        if exist([raw_data_location,IDs{n},'.tar'],'file')                  % If the folder has alredy been untarred, delete it from 'Raw EEG Files' to save space. 
            delete([raw_data_location,IDs{n},'.tar'])
            fprintf('Tarred file for ID %3.0f deleted \n',n)
        end
    end
    if exist([storage_location,'\',IDs{n},'\EEG\raw\csv_format'], 'dir') 
        rmdir(['D:\HBN Project\EEG Files\',IDs{n},'\EEG\raw\csv_format\'],'s')  % Remove redundant files to save space.
        rmdir(['D:\HBN Project\EEG Files\',IDs{n},'\EEG\raw\mff_format\'],'s')
        rmdir(['D:\HBN Project\EEG Files\',IDs{n},'\EEG\preprocessed\csv_format\'],'s')
        fprintf('Redundant files for ID %3.0f deleted \n',n)
    end
end
    
 
