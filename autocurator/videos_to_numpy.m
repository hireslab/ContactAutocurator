% VIDEOS_TO_NUMPY(TCONTACTS, DIRTOPROCESS, ROI) takes the videos indicated
% the preprocessed contact array in DIRTOPROCESS, ROI
function videos_to_numpy(tContacts, dirToProcess, roi)

% Main loop to process
numTrials = length(tContacts);
for i = 1:numTrials
    % Video information
    videoToFind = tContacts{i}.video;
    [~,videoName,~] = fileparts(videoToFind);
    frameIdx = find(tContacts{i}.labels == 1);
    % Load video
    trialVideo = mmread(videoToFind);
    nFrames = length(trialVideo.frames);
    % Loop through each frame of video
    finalMat = zeros(length(frameIdx),roi(1));
    finalMat = repmat(finalMat, 1, 1, roi(2));
    for j = 1:length(frameIdx)
        % Find valid frames
        cFrame = trialVideo.frames(frameIdx(j)).cdata(:,:,1);
        % Use bar positions to crop
        xPos = round(tContacts{i}.bar(frameIdx(j),2));
        yPos = round(tContacts{i}.bar(frameIdx(j),3));
        poleBox = [xPos-roi(1), xPos + roi(1), yPos - roi(2), yPos + roi(2)];
        % Check if ROI exceeds edge of image and skip if so
        nFrameMat = curFrame((poleBox(3)):(poleBox(4)),(poleBox(1)):(poleBox(2)));
        nFrameMat = imadjust(nFrameMat);
        % Save frame in array
        finalMat(j,:,:) = nFrameMat;
    end
    % Save array as numpy file for autocurator
    saveVidName = [videoName '_' num2str(i) '.npy'];
    saveName = [dirToProcess filesep saveVidName];
    writeNPY(finalMat, saveName)
end

