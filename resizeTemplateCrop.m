close all
clear all

myFolder = 'C:\Users\ELong\Documents\MATLAB\gradientWarp\affine_reg_recoveredScript';
filePattern = fullfile(myFolder, '*.png');
pngFiles = dir(filePattern);

%Read template image
scriptTemplate_loc = 'scriptTemplate.jpg';
scriptTemplate = imread(scriptTemplate_loc);
scriptTemplate = rgb2gray(scriptTemplate);

%Get dimensions of crest in template
template_binary = im2bw(255 - scriptTemplate);
template_binary = imclearborder(template_binary);
template_fill = imfill(template_binary, 'holes');
figure;
imshow(template_fill);
% Get the region properties and select that with the largest area.
S = regionprops(template_fill,'BoundingBox','FilledArea','PixelIdxList');
boundingboxes = cat(1, S.BoundingBox);
FilledAreas = cat(1,S.FilledArea);
[max1, ind1] = max(FilledAreas);
FilledAreas(ind1)      = -Inf;
[max2, ind2] = max(FilledAreas);
FilledAreas(ind2)      = -Inf;
[max3, ind3] = max(FilledAreas);
FilledAreas(ind3)      = -Inf;
[max4, ind4] = max(FilledAreas);

%Show bounding box on crest. The 4th biggest region.
figure;
imshow(template_fill);
hold on
rectangle('Position',boundingboxes(ind4,:),'EdgeColor','r');
% Find dimensions and area of crest and coordinates of top left corner
template_crest_x = boundingboxes(ind4,1);
template_crest_y = boundingboxes(ind4,2);
template_crest_width = boundingboxes(ind4,3);
template_crest_height = boundingboxes(ind4,4);
template_crest_area = template_crest_width * template_crest_height;

disp('Beginning For loop:');
for k = 1:length(pngFiles)

    baseFileName = pngFiles(1).name;
    fullFileName = fullfile(myFolder, baseFileName);
    script_recovered = imread(fullFileName);
    [recovered_height, recovered_width] = size(rgb2gray(script_recovered));
    % Conver to binary and fill holes in crest
    script_binary = im2bw(255 - script_recovered);
    script_binary = imclearborder(script_binary);
    figure;
    imshow(script_binary);
    fill = imfill(script_binary, 'holes');
    figure;
    imshow(fill);

    %// Get the region properties and select that with the largest area.
    S = regionprops(fill,'BoundingBox','FilledArea','PixelIdxList');
    boundingboxes = cat(1, S.BoundingBox);
    FilledAreas = cat(1,S.FilledArea);
    [~,MaxAreaIndex] = max(FilledAreas);

    %Show bounding box on crest
    figure;
    imshow(script_binary);
    rectangle('Position',boundingboxes(MaxAreaIndex,:),'EdgeColor','r');

    % Find dimensions and area of crest and top left coordinate
    crest_x = round(boundingboxes(MaxAreaIndex,1));
    crest_y = round(boundingboxes(MaxAreaIndex,2));
    crest_width = boundingboxes(MaxAreaIndex,3);
    crest_height = boundingboxes(MaxAreaIndex,4);
    crest_area = crest_width * crest_height;

    %Resize template to overlay recovered script using dimensions of crest
    % Find ratio of change of recovered chest compared to template crest
    scale_factor = crest_area / template_crest_area;
    %Rescale template image
    template = imresize(scriptTemplate,scale_factor);
    figure();imshow(template);
    [template_height, template_width] = size(template); 
    %find coords of top left of crest in scaled template
    template_crest_x = round(scale_factor * template_crest_x);
    template_crest_y = round(scale_factor * template_crest_y);
  
    % Distances to edge of recovered frame relative to top left of crest
    dist_to_top = crest_y;
    dist_to_bottom = (recovered_height - crest_y);
    dist_to_left = crest_x;
    dist_to_right = (recovered_width - crest_x);

    % Distances to edge of template relative to top left of crest
    dist_to_top_template = template_crest_y;
    dist_to_bottom_template = (template_height - template_crest_y);
    dist_to_left_template = template_crest_x;
    dist_to_right_template = (template_width - template_crest_x);
    
    %Crop template or pad template to make it the same size as the video frame
    %Top of template
    if dist_to_top > dist_to_top_template
       template =  padarray(template, [round((dist_to_top - dist_to_top_template)) 0],0,'pre');
    else
        %If template is higher in y direction, crop top of template to match
        template = template(1:end, (dist_to_top_template - dist_to_top): end);
    end
    %if template does not exceed bottom of frame
    if dist_to_bottom > dist_to_bottom_template
        %extend template
        template = padarray(template, [(dist_to_bottom - dist_to_bottom_template) 0], 0, 'post');
    else
        %Crop bottom of template
        template = template(1:end - (dist_to_bottom_template - dist_to_bottom) , 1:end);
    end
    
    %Left of template
    if dist_to_left > dist_to_left_template
        template = padarray(template, [0 (dist_to_left - dist_to_left_template)], 0, 'pre');
    else
        %crop left of template to match
        template = template(1:end, (dist_to_left_template - dist_to_left): end);
    end
    %if template does not exceed right of frame
    if dist_to_right > dist_to_right_template
        %extend template
        template = padarray(template, [0 (dist_to_right - dist_to_right_template)], 0, 'post');
    else
        %Crop right of template
        template = template(1:end, 1: end - (dist_to_right_template - dist_to_right));
    end
    
    crop_x_neg = 100;
    crop_x_pos = 2300;
    crop_y_neg = 150;
    crop_y_pos = 1000;
    
    template_crop = template(crest_y - crop_y_neg : end, crest_x - crop_x_neg : crest_x + crop_x_pos);
    script_recovered_crop = script_recovered(crest_y - crop_y_neg : end, crest_x - crop_x_neg : crest_x + crop_x_pos);

    figure();imshowpair(script_recovered_crop, template_crop);
    
    imwrite(template_crop, 'C:\Users\ELong\Documents\MATLAB\gradientWarp\templateResizedtoFrame_crop.png');
    imwrite(script_recovered_crop, 'C:\Users\ELong\Documents\MATLAB\gradientWarp\videoFrame_crop.png');
    pause(10)
end



figure();
imshow(template);hold on
plot(crest_y,crest_x,'o'); 







