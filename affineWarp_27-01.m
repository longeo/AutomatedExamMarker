close all
clear all
load('/users/ugrad/longeo/Documents/MATLAB/results_from_sections-20200117T170620Z-002/results_from_sections/basic_ground_truths/AffineSIFT1.mat', 'exam_info')


grades_fields_loc = '/users/ugrad/longeo/Documents/MATLAB/grades_fields.pgm';
trinity_loc = '/users/ugrad/longeo/Documents/MATLAB/trinity_crest.jpg';
studentno_loc = '/users/ugrad/longeo/Documents/MATLAB/exam_number_field.pgm';
examscript_loc = '/users/ugrad/longeo/Documents/MATLAB/examtemplate.pgm';

exam_number_img = imread(studentno_loc);
exam_number_img = rgb2gray(exam_number_img);
crest_img = imread(trinity_loc);
crest_img = rgb2gray(crest_img);
grades_img = rgb2gray(imread(grades_fields_loc));
examscript_imgOriginal = imread(examscript_loc);

%USE SIFT TO ITERATIVELY CLOSE IN ON EXAM NUMBER FIELD

%studentno_loc = '~/mai_project_media/crest_student_num_field.png';
grades_fields_loc = '/users/ugrad/longeo/Documents/MATLAB/grades_fields.pgm';
trinity_loc = '/users/ugrad/longeo/Documents/MATLAB/trinity_crest.jpg';
studentno_loc = '/users/ugrad/longeo/Documents/MATLAB/exam_number_field.pgm';
instructionBoxloc = '/users/ugrad/longeo/Documents/MATLAB/instructionBox.pgm';


student_no_field = imread(studentno_loc);
trinityOriginal = imread(trinity_loc);
instructionBoxOriginal = imread(instructionBoxloc);
trinity = rgb2gray(trinityOriginal);

student_no_field = rgb2gray(student_no_field);
grades_fields = rgb2gray(imread(grades_fields_loc));
instructionBox = instructionBoxOriginal;
examscript_img = rgb2gray(examscript_imgOriginal);


iterations = 10;
for i=1:length(exam_info)
  scriptOriginal = exam_info{i}.original;
  script = rgb2gray(scriptOriginal);
  %   script = imresize(trinity, 0.7);
  %   script = imrotate(script, 10);

  
  
  % Stage 1
  % Code copied and altered from 'Find Image Rotation Using Automated Feature
  % Matching' on www.MathWorks.com
  % Detect features in both images.
  ptsCrest  = detectSURFFeatures(trinity);
  ptsScript = detectSURFFeatures(script);
  % Extract feature descriptors.
  [featuresCrest,   validPtsCrest]  = extractFeatures(trinity,  ptsCrest);
  [featuresScript, validPtsScript]  = extractFeatures(script, ptsScript);
  % Match features by using their descriptors.
  indexPairs = matchFeatures(featuresCrest, featuresScript);   
  % Retrieve locations of corresponding points for each image.
  matchedTrinity  = validPtsCrest(indexPairs(:,1));
  matchedScript = validPtsScript(indexPairs(:,2));
  
  
  % Estimate image rotation based on features. Use MSAC algorithm to make
  % it more robust.
  [tform1, inlierScript, inlierTrinity] = estimateGeometricTransform(...
    matchedScript, matchedTrinity, 'similarity');
  % Recover the original image by transforming the distorted image.
  outputView = imref2d(size(trinity));
  crestRecovered  = imwarp(script, tform1, 'OutputView', outputView);  
  scriptRecovered  = imwarp(scriptOriginal,tform1);
  
% %   Display original script and warped script
% %   figure(2), imshowpair(scriptOriginal, crestRecovered,'montage');
% %   title('Original script and CREST alligned using feature based transform.');
% %   figure(3), imshowpair(scriptOriginal, scriptRecovered, 'montage');
% %   title('Original script and SCRIPT alligned using FEATURE based transform.');
  
  



  
  % Stage 2:
  % Refining transformation estimation using intensity-based image
  % registration. Use sample image of trinity cret and MATLAB imregtform() function
  [optimizer, metric] = imregconfig('multimodal'); 
  % Tune Parameters
  optimizer.InitialRadius = 0.009;
  optimizer.Epsilon = 1.5e-4;
  optimizer.GrowthFactor = 1.01;
  optimizer.MaximumIterations = 300;
  
  % Generate transform matrix and perform warp on image.
  intensityBasedtform = imregtform(crestRecovered, trinity, 'affine', optimizer, metric);
  % Combine featurebased warp and intensity based warp
  finalTform = tform1.T * intensityBasedtform.T;
  
  scriptRecoveredRGB = imwarp(scriptRecovered, intensityBasedtform, 'OutputView', imref2d(size(scriptRecovered)));
  scriptRecovered = rgb2gray(scriptRecoveredRGB);
% 
%   figure(4)
%   %   imshowpair(scriptTemplateOriginal, scriptRecovered,'montage')
%   imshowpair(scriptTemplateOriginal, scriptRecovered,'Scaling','joint')
%   title('Exam script after FEATURE and INTENSITY warp.');

  


  
  % Stage 3:  
  % Detect and extract SURF feature descriptors for crest and
  % recovered script
  ptsExamNumber  = detectSURFFeatures(trinity);
  ptsExamField = detectSURFFeatures(scriptRecovered);
  [featuresExNumber,   validPtsExNum]  = extractFeatures(trinity,  ptsExamNumber);
  [featuresExField, validPtsExField]  = extractFeatures(scriptRecovered, ptsExamField);
  indexPairs = matchFeatures(featuresExNumber, featuresExField);
  % Retrieve locations of corresponding points for each image.
  matchedOriginal  = validPtsExNum(indexPairs(:,1));
  matchedDistorted = validPtsExField(indexPairs(:,2));
  % Remove outliers SURF features
  
%   % Show point matches. Notice the presence of outliers.
%   figure(6);
%   showMatchedFeatures(trinity,scriptRecovered,matchedOriginal,matchedDistorted);
%   title('Putatively matched points (including outliers)');
 


  % Match INSTRUCTIONS BOX with recovered script
% % % %   ptsBox = detectSURFFeatures(instructionBox);
% % % %   ptsScript = detectSURFFeatures(scriptRecovered);
% % % %   [featuresBox,   validPtsBox]  = extractFeatures(instructionBox,  ptsBox);
% % % %   [featuresScript, validPtsScript]  = extractFeatures(scriptRecovered, ptsScript);
% % % %   indexPairs = matchFeatures(featuresBox, featuresScript);   
% % % %   matchedBox  = validPtsBox(indexPairs(:,1));
% % % %   matchedDistorted = validPtsScript(indexPairs(:,2));
% % % %   [tform, inlierScript, inlierTrinity] = estimateGeometricTransform(...
% % % %     matchedDistorted, matchedBox, 'similarity');
% % % %   figure(1);ax = axes;
% % % %   % showMatchedFeatures(trinity, examscript_img, inlierTrinity, inlierScript);
% % % %   showMatchedFeatures(instructionBox,scriptRecovered,matchedBox,matchedDistorted,'montage','Parent',ax);




  % Stage 4:
  % Detect and remove outliers and crop box
  % Crop exam number and grades field from image
%   original_crop_offsetx = 1550;
%   original_crop_offsety = 700; 
%   box_width = 480;
%   box_height = 1300;
  instruction_crop_offsetx = -200;
  instruction_crop_offsety = 650; 
  box_width = 1800;
  box_height = 1400;
  outlier = isoutlier(matchedDistorted.Location);
  outlier = ~(outlier(:,1) | outlier(:,2));
  surfLocations = [matchedDistorted.Location(outlier,1), matchedDistorted.Location(outlier,2)];

  % Determine the mean positions of the SURF
  % features.
  meanSurfLoc = mean(surfLocations);

  % Determine minimum and maximum of bounding box based on SURF
  % features mean.
  min_x = meanSurfLoc(1,1) + instruction_crop_offsetx;
  max_x = meanSurfLoc(1,1) + instruction_crop_offsetx + box_width;
  min_y = meanSurfLoc(1,2) + instruction_crop_offsety;
  max_y = meanSurfLoc(1,2) + instruction_crop_offsety + box_height;
  
  % Use rectangle to draw bounding rectangle and crop image
%   figure(7); 
%   imshow(scriptRecovered);
%   hold on
%   plot(meanSurfLoc(1,1), meanSurfLoc(1,2), 'b*');
%   rectangle('Position',[min_x min_y (max_x-min_x) (max_y-min_y)]);
  cropped = imcrop(scriptRecovered,[min_x min_y (max_x-min_x) (max_y-min_y)]);
%   figure(8);
%   imshow(cropped);
%   title('Cropped instruction box after feature and intensity based warped');
%   



  % Try to allign image using feature based image registration from
  % instruciton box
  ptsCrest  = detectSURFFeatures(instructionBox);
  ptsScript = detectSURFFeatures(cropped);
  % Extract feature descriptors.
  [featuresCrest,   validPtsCrest]  = extractFeatures(instructionBox,  ptsCrest);
  [featuresScript, validPtsScript]  = extractFeatures(cropped, ptsScript);
  % Match features by using their descriptors.
  indexPairs = matchFeatures(featuresCrest, featuresScript);   
  % Retrieve locations of corresponding points for each image.
  matchedTrinity  = validPtsCrest(indexiterationsPairs(:,1));
  matchedScript = validPtsScript(indexPairs(:,2));
  % Estimate image rotation based on features. Use MSAC algorithm to make
  % it more robust.
  [tform1, inlierScript, inlierTrinity] = estimateGeometricTransform(...
    matchedScript, matchedTrinity, 'similarity');

  % Recover the original image by transforming the distorted image.
  outputView = imref2d(size(script));
  scriptRecovered  = imwarp(scriptOriginal, tform1, 'OutputView', outputView);  
  figure(10);
  imshow(scriptRecovered);
  
  
  
  
  % Try intensity based image registration based on cropped insruction box
% % %   croppedTform = imregtform(cropped_final, instructionBox, 'affine', optimizer, metric);
% % %   figure(9);
% % %   croppedRecovered = imwarp(cropped_final, croppedTform, 'OutputView', imref2d(size(instructionBox)));
% % %   imshowpair(instructionBox, croppedRecovered,'Scaling','joint')

  
  
  pause(1)
end





























