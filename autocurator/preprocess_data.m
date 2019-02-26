% PREPROCESS_DATA(DATAOBJ) is designed to take a data object and perform 
% all preprocessing that does not require pole images. All relevant whisker
% tracking data you wish to use should be in dataObj. The output contacts
% will inform the autocurator whether or not to curate a frame (excluding 
% known frames can speed up autocuration). Preprocessing involving altering 
% images fed to the autocuration should happen in the VIDEOS_TO_NUMPY step 
function [preprocessedContacts] = preprocess_data(dataObj, processSettings)

%% DEFAULT SETTINGS
if nargin == 1
    processSettings.useDataPreprocessing = true;
    processSettings.useVelocity = false;
    processSettings.velocityCutoff = 0.05;
    processSettings.useAbsoluteDistance = true;
    processSettings.distanceCutoff = 2;
    processSettings.curateUntracked = true;
    processSettings.snipTrial = true;
    processSettings.startStop = [500, 3500];
end
%% MAIN

numTrials = length(dataObj);
preprocessedContacts = cell(1);
preprocessedContacts{1}.labels = [];
preprocessedContacts{1}.trialNum = [];
preprocessedContacts{1}.video = [];
% Loop through trials and create contacts
for i = 1:numTrials
    % Check if we want to preprocess with data, if not, mark every frame as
    % good
    if processSettings.useDataPreprocessing == 0
        labels = zeros(1,dataObj{i}.numFrames);
        labels(:) = 1;
        preprocessedContacts{i}.labels = labels;
        preprocessedContacts{i}.trialNum = dataObj.trialNum;
        preprocessedContacts{i}.video = dataObj.video;
        continue
    end
    
    % Otherwise proceed with preprocessing 
    labels = zeros(1, dataObj{i}.numFrames);
    for j = 1:dataObj{i}.numFrames
        % Check if frame has usable distance-to-pole data (no lost 
        % tracking)
        if ismember(j,dataObj{i}.trackedFrames)
            dist = dataObj{i}.distance(dataObj{i}.trackedFrames == j);
        elseif processSettings.curateUntracked == 1
            labels(j) = 1; % Have autocurator find contacts in untracked
            % frames
            continue
        else
            labels(j) = -1; % Mark as un-curatable
            continue
        end
        
        if processSettings.useVelocity == 1
            % Velocity filter removes frames that can't be touches due to
            % impossibly high velocity
            if j > 1
                vel = dist - dataObj{i}.distance(dataObj{i}.trackedFrames == (j-1));
                if vel > processSettings.velocityCutoff
                    labels(j) = -1;
                else
                    labels(j) = 1;
                end
            else
                labels(j) = 1;
            end
        end
        if processSettings.useAbsoluteDistance == 1
            % Distance filter removes frames that can't be touches due to
            % being too far away even accounting for the whisker tracker's
            % high margin of error. 
            if dist > processSettings.distanceCutoff
                labels(j) = 0;
            else
                labels(j) = 1;
            end
        if processSettings.snipTrial == 1
            if j < processSettings.startStop(1) || j > processSettings.startStop(2)
                labels(j) = 0;
            end
        end
            
    end
    
    % Write trial data to temporary contacts
    preprocessedContacts{i}.video = dataObj{i}.video;
    preprocessedContacts{i}.labels = labels;
    preprocessedContacts{i}.bar = dataObj{i}.bar;
        
end
