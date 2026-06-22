function seg_yeast = yeast_segmentation_automated
%%
% Summary: This function automatically segments the fluorescent microscopy images of
% yeast cells.
%
% Description: This function is designed to segment - and isolate- the
% nuclei of the yeast cells undergoing S phase (cells having PCNA-mNG
% foci). To isolate S phase nuclei, a threshold on the standard deviation of
% the intensities within the regions was used, as an indicator of heterogenous 
% intensity caused by ﬂuorescent foci. In order to use this function, first use Smooth Manifold
% Extraction (SME) projection method on your PCNA-mNG z stack. Then call
% this function and give the SME_projection image as the input to the
% function. The output of the function is a "binary mask" of the input image such that 
% S phase nuclei regions have the intensity values of 1, and anywhere else
% intensity of zero.
%
% Author: Nitin Kapadia
% Date created: Jul 1, 2020
% Documentation: created on Feb 27, 2023 by Masoumeh Shafieidarabi
%
% inputs: - Brightfield image of yeast cells carrying PCNA-mNG (image
% created from SME projection of z stack)
%         - The initial threshold on the standard deviation of intensities for segmentation
%
% output: Binary mask of the input where S phase nuclei regions have the intensity values of 1, 
% and anywhere else intensity of zero.

% Usage: To use this function simply call the function
%% 
% getting the path of input image. Note that the name of the file should end with "SME_projection.tif" string:
%**** try having multiselect on
%***** create a directory to save the files 
filename = uigetfile('*GFP.tif','Pick your SME file');
%getting the initial threshold of the standard deviation of intensities (defult: 3000):
% Since the PCNA-mNG foci cause heterogeneous intensity, for segmenting the S phase nuclei, we set a threshold
% on the standard deviation of the intensities rather than the intensity
user_input_std_initial = inputdlg('STD threshold','Set an Initial Standard Deviation Threshold',[1 80],{'3000'}); 
std_thresh = str2num(user_input_std_initial{1}); % converting the output of inputdlg (array of char vector) to number
%std_thresh = 1800;
rd2 = imread(filename); % loading the image
rd2 = uint16(rd2);
%figure, imshow(rd2,[min(min(rd2)), max(max(rd2))]); % showing the image
%while scaling the intensity values to the intensity range in unint8
%imcontrast % to manually adjust the contrast of the image to be displayed
%% 1. Background equalization and isolating small bright objects (S phase nuclei)
% defining the shape and the size of structural element (kernel) for
% further filtering:
se = strel('disk', 11, 4);% default 11 and 4
% top hat filtering (morphological opening of the image and subtracting it
% from the original image:
tophatFiltered = imtophat(rd2, se);
%figure, imshow(tophatFiltered)
%imcontrast
%% 2. Image segmentation (creating binary mask)
%thresh_crit = adaptthresh(tophatFiltered,0.00005,'Statistic','Gaussian');%ddefault 0.02
% binarizing the image using locally adaptive threshold 
bw1 = imbinarize(tophatFiltered,'adaptive');
% figure, imshow(bw1)
%% 3. Noise reduction in the binary mask (removing the pixels falsely labled as forground) 
bw2 = bwareaopen(bw1, 200); % default = 150 % removing the objects smaller than 200 pixels
%figure, imshow(bw2);
%% 
bw3 = mat2gray(bw2);
bw4 = imgaussfilt(bw3, 0.5); %default 1.7
%figure, imshow(bw4);
%% 
%thresh_crit2=adaptthresh(bw4,0.02,'Statistic','Gaussian');%default 0.02
thresh2=imbinarize(bw4,'adaptive');
 %figure,imshow(thresh2);

%% 
bw5 = bwareaopen(thresh2,300);%default 100
bw6 = uint16(bw5);
 %figure,imshow(bw5);
 %cc=bwconncomp(bw5)
 stats = regionprops(bw5,rd2,'Image','PixelList','PixelValues');
 PixelValues = {stats.PixelValues}.';
 PixelList = {stats.PixelList}.';

%% 
while(1)
image_replace = rd2;
bin_image = bw5;
for i = 1:length(PixelValues)
    std_int = std(double(PixelValues{i}));
    mean_int = mean(double(PixelValues{i}));
    %fprintf('std intensity of %d is %d .\n',i, std_int)
    %fprintf('mean intensity of %d is %d .\n',i, mean_int)
    px_coordinates = PixelList{i};
    if  mean_int < std_thresh%mean_int < std_thresh%std_int < std_thresh | mean_int < int_thresh 
        for j = 1:length(px_coordinates)
        image_replace(px_coordinates(j,2), px_coordinates(j,1)) = 0;
        bin_image(px_coordinates(j,2), px_coordinates(j,1)) = 0;
        end
    else
        continue
    end
end
bin_image = uint16(bin_image);
fused_image = imfuse(bin_image, rd2,'blend');
%figure,imshow(image_replace,[min(min(image_replace)), max(max(image_replace))])
%figure, imshow(bin_image,[min(min(bin_image)), max(max(bin_image))]) 
figure, imshow(rd2,[min(min(rd2)), max(max(rd2))]);
title('this is the original image')
figure, imshow(fused_image)
title('this is the fused image')
figure, imshow(bin_image, [min(min(bin_image)), max(max(bin_image))])
title('this is the mask image')
% mkdir for Paulina
savename=strrep(filename,'*GFP.tif','binary_auto');
user_input = inputdlg ('Is the segmentation good?','Yeast Segmentation',[1 50],{'NO'});
    if user_input{1} == 'Y'| user_input {1} == 'y'
        close all
        imwrite(bin_image,savename,'tif') 
        %change the direcroty that saves the new data
        return
    else 
        close all
        default_std_thresh = num2str(std_thresh);
        user_input_std = inputdlg('Std threshold','Set a new threshold',[1 50],{default_std_thresh});
        std_thresh = str2num(user_input_std{1});
    end
end
%imwrite(bin_image,savename,'tif')
end
