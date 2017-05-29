% Project
% Victor Vargas - U01251248
% vv16417n@pace.edu
%disp('Loading, it may take a moment')
%disp('-----Finish Solving Problem -----');
%pause;
close all;
clear all;
matlab.video.read.UseHardwareAcceleration('on')  
fileName = 't5.mp4';

VideoInfo = get(VideoReader(fileName));
NumTrainingFrames = int64(VideoInfo.FrameRate*(VideoInfo.Duration/4));
NumGaussians = 3;
%STEP 1 - Import Video and Initialize Foreground Detector

%Initialize the Gaussian mixture model with the first 50 frames

foregroundDetector = vision.ForegroundDetector('NumGaussians', NumGaussians, 'NumTrainingFrames', NumTrainingFrames);
videoReader = vision.VideoFileReader(fileName);
for i = 1:NumTrainingFrames*NumGaussians
    frame = step(videoReader); % read the next video frame
    foreground = step(foregroundDetector, frame);  % extract foreground
end
figure; imshow(frame); title('Video Frame');
figure; imshow(foreground); title('Foreground');

%STEP 2 - Detect Cars in an Initial Video Frame

%Morphological opening to remove the noise and to fill gaps in the detected objects
seSize = round(VideoInfo.Width*0.01);
se = strel('square',seSize); % 1% of video's with

filteredForeground = imopen(foreground, se);
figure; imshow(filteredForeground); title('Clean Foreground');

MinimumBlobArea = int64(VideoInfo.Width*0.10*VideoInfo.Height*0.10); % 8% of video's with
blobAnalysis = vision.BlobAnalysis('BoundingBoxOutputPort', true, 'AreaOutputPort', false, 'CentroidOutputPort', false, 'MinimumBlobArea', MinimumBlobArea);
bbox = step(blobAnalysis, filteredForeground);

%green boxes around detected cars
result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');

numCars = size(bbox, 1);
result = insertText(result, [10 10], numCars, 'BoxOpacity', 1, 'FontSize', 14);
figure; imshow(result); title('Detected Cars');

%Step 3 - Process the Rest of Video Frames
videoPlayer = vision.VideoPlayer('Name', 'Detected Cars');
se = strel('square', seSize); % morphological filter for noise removal
%Play video. Every call to the step method reads another frame.
while ~isDone(videoReader)
    frame = step(videoReader); % read the next video frame

    % Detect the foreground in the current video frame
    foreground = step(foregroundDetector, frame);

    % Use morphological opening to remove noise in the foreground
    filteredForeground = imopen(foreground, se);

    % Detect the connected components with the specified minimum area, and
    % compute their bounding boxes
    bbox = step(blobAnalysis, filteredForeground);

    % Draw bounding boxes around the detected cars
    result = insertShape(frame, 'Rectangle', bbox, 'Color', 'green');

    % Display the number of cars found in the video frame
    numCars = size(bbox, 1);
    result = insertText(result, [10 10], numCars, 'BoxOpacity', 1,'FontSize', 14);

    step(videoPlayer, result);  % display the results
end

release(videoReader); % close the video file