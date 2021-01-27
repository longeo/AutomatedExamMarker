% This code use uses Gradient Based Warp Estimation to find geometrically
% correct a rotated image of the crest. This is used to test the algorithm

%Solving system of linear equations
clear
close all

trinity_loc = 'trinity_crest.png';
trinity = imread(trinity_loc);
c = rgb2gray(trinity);
inputImage = double(c);

%Define target and source image
source_im = inputImage;
[rows, cols] = size(source_im);


% Create coordinate system with origin at the centre of the image
X = ones(rows, 1) * (-(cols-1)/2 : (cols-1)/2);
Y = (-(rows-1)/2 : (rows-1)/2)' * ones(1, cols);
coords = [X(:)'; Y(:)'];

shiftMatrix = zeros(2,1);
shiftMatrix(1,1) = 5;
shiftMatrix(2,1) = 5;
%Rotation Matrix (degrees)
theta = 5;         
rotationMatrix = zeros(2,2);
rotationMatrix(1,1)  = cosd(theta);
rotationMatrix(1,2)  = sind(theta);
rotationMatrix(2,1)  = -sind(theta);
rotationMatrix(2,2)  = cosd(theta);
%Create scaling Matrix
a = 1;
scalingMatrix = zeros(2,2);
scalingMatrix(1,1) = a;
scalingMatrix(2,2) = a;
%Combine scaling and rotation operation
transformationMatrix = scalingMatrix*rotationMatrix;

%Calculate transformed coordinate system
new_coords = transformationMatrix \ coords;
new_coords = new_coords + shiftMatrix;
X_lookup = reshape(new_coords(1, :), rows, cols);
Y_lookup = reshape(new_coords(2, :), rows, cols);
%Use coordinate system to find new image
newoutputOriginal = interp2(X, Y, inputImage, X_lookup, Y_lookup);
newoutputOriginal(isnan(newoutputOriginal))=0;
newoutput = newoutputOriginal;

figure();imshow(newoutput/255)


%Warp starting guess
A_start = [1 0; 0 1];
d_start = [0; 0];
v = [A_start(:); d_start(:)];
    
iteration_end = 100;
figure()
psnr_array = zeros(iteration_end,1);
for iteration = 1:iteration_end
    %Calculate the discrete frame difference between target and source
    DFD = source_im - newoutput;
%     figure();
%     imshow(DFD/255);
    zo = DFD(:);
    zo(isnan(zo))=0;

    %Calculate gradient in x and y directions
    [dx, dy] = gradient(source_im);
    x1 = coords(1, :);
    x2 = coords(2, :);
    gx = dx(:)';
    gy = dy(:)';
    G = [x1.*gx; x2.*gx; x1.*gy; x2.*gy; gx; gy]';
    G(isnan(G))=0;

    %Use Ordinary least squares to solve system of equations
    G_transpose = transpose(G);
    G_transpose_G = G_transpose * G;
    u = G_transpose_G \ (G_transpose * zo);

    %update guess
    v = v + u;

    %Assemble transformation matrix from variables
    A = [v(1) v(2); v(3) v(4)];
    d = [v(5); v(6)];

%     %For sanity check
%     A = [1 0; 0 1];
%     d = [0; 0];

    %Transform coordinate system
    updated_coords = (A * coords) + d; 
    X_lookup_update = reshape(updated_coords(1, :), rows, cols);
    Y_lookup_update = reshape(updated_coords(2, :), rows, cols);
    %Use coordinate system to find new image
    unwarped_im = interp2(X, Y, newoutputOriginal, X_lookup_update, Y_lookup_update);
%     figure();
%     title('unwarped');
%     imshowpair(unwarped_im/255, newoutput)

    %Calculate PSNR between two original images
    newoutput(isnan(newoutput))=0;
    unwarped_im(isnan(unwarped_im))=0;

    %Calcaulate PSNR - the higher, the better
    [peaksnr, snr] = psnr(unwarped_im/255, source_im/255);
    psnr_array(iteration,1) = peaksnr;
    
    newoutput = unwarped_im;
    
end

%Plot PSNR
figure()
plot(1:iteration_end, psnr_array, 'r')

figure()
plot(iteration, psnr_array'.', 'color','r','MarkerSize', 20); hold on

figure()
imshowpair(unwarped_im/255, newoutputOriginal)

figure();
imshowpair(unwarped_im/255, inputImage/255)

figure();
imshow(unwarped_im/255)

% figure()
% l=0;
% for i= 1:10
%     l = l+i;
%     disp(l)
%     plot(i,l,'.', 'color','r','MarkerSize', 20); hold on
% end



