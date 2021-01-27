close all
clear all

myFolder = '/Users/eoinlong1/Desktop/affine_reg_recoveredScript';
filePattern = fullfile(myFolder, '*.png');
pngFiles = dir(filePattern);
disp('Beginning for loop');

for k = 1:length(pngFiles)
%   script_recovered = imread('/Users/eoinlong1/Desktop/affine_reg_recoveredScript/test4.png');
  baseFileName = pngFiles(k).name;
  fullFileName = fullfile(myFolder, baseFileName);
%   fprintf(1, 'Now reading %s\n', fullFileName);
  script_recovered = imread(fullFileName);


  % Fill holes in crest
  script_binary = im2bw(255 - script_recovered);
  script_binary = imclearborder(script_binary);
%   figure;
%   imshow(script_binary);
  fill = imfill(script_binary, 'holes');
  figure;
  imshow(fill);

  %// Get the region properties and select that with the largest area.
  S = regionprops(fill,'BoundingBox','FilledArea','PixelIdxList');
  boundingboxes = cat(1, S.BoundingBox);
  FilledAreas = cat(1,S.FilledArea);
  [~,MaxAreaIndex] = max(FilledAreas);

  % Find grades box
  crest_width = boundingboxes(MaxAreaIndex,3);
  crest_height = boundingboxes(MaxAreaIndex,4);
  factor_xaxis = 7.20;
  factor_yaxis = 3.1;
  factor_crest2grad_x = 2.2;
  factor_crest2grad_y = 3.8;

  gradebox_x = (crest_width * factor_xaxis) + boundingboxes(MaxAreaIndex,1);
  gradebox_y = (crest_height * factor_yaxis) + boundingboxes(MaxAreaIndex,2);
  gradebox_width = (crest_width * factor_crest2grad_x);
  gradebox_height = (crest_height * factor_crest2grad_y);
  gradebox_pos = [gradebox_x, gradebox_y, gradebox_width,gradebox_height];

  figure;
  imshow(script_binary);
  rectangle('Position',gradebox_pos,'EdgeColor','r');
  rectangle('Position',boundingboxes(MaxAreaIndex,:),'EdgeColor','r');
  gradeboxIm = imcrop(script_recovered, gradebox_pos);
  
  if ~isempty(gradeboxIm)
    imwrite(gradeboxIm,fullfile(['/Users/eoinlong1/Desktop/gradesbox/' baseFileName]));  
  end
end