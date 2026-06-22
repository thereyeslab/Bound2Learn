%%%No speed factor compensation
% This program lands the tracks within the nucleus and discard the ones that
% are outside of the nucleus. Also, filters the tracks based on some parameters such as track length.
% The out put of this program will be used in the ML classification.
% Inputs:
% - binary_auto.tif (binary mask (tif)): The binary mask from segmentation
% of cells or nucleus (only the ones in S Phase or all of them)
% - spots files (csv):  has 5 coloumns: [tr_identifi, tr_fram, x_tr, y_tr, inten]
% - tracks files (csv): has 18 coloumns : [Track_IDs, spt_tr, spt_widt, mean_sp, max_sp, min_sp, med_sp,
% std_sp, mean_q, max_q_tr, min_q_tr, med_q_tr, std_q_tr, tr_dur, tr_start, tr_fin, x_lc, y_lc]
% - Propmt user for tracks information: 1) The time interval in which the data was collected (default = 1) 
% 2) Min #of localizations for track : The min number of the track length. Tracks
% shorter than this number will get discarded. (default = 4)
% 3) # of localizations for Intensity: 
% 3) Intensity Thresh: The radius of the spots chosed
% 4) 
% Note: The only parameters usded 
% outputs: 
% _ 
% 
% Notes: The binary mask should be based on your research. If you want to
% study cells undergoing S phse, then your mask should be the result of
% segmentation of nuclei in the green channel projected image(based on the foci of PCNA_mNeonGreen)

filenames_images = uigetfile('*.png', 'Pick Binary Image Files', 'Multiselect', 'on');
filenames_spots = uigetfile('*spots.csv', 'Pick spots.csv', 'Multiselect', 'on');
filenames_tracks = uigetfile('*tracks.csv', 'Pick tracks.csv', 'Multiselect', 'on');
num_files_images = length(filenames_images);
% Asking user 
%num_files_images = 1;
%filenames_images = {filenames_images};
%filenames_spots = {filenames_spots};
%filenames_tracks = {filenames_tracks};
user_input_tracks = inputdlg({'What was the time interval','Min # of localizations for track',' # of localizations for Intensity','Intensity Thresh', 'Track Window' , 'Spot Thresh'},'Tracks Information',...
    [1 50; 1 50; 1 50; 1 50; 1 50; 1 50;],{'1','4','4', '500', '3', '1.5'}); % The default values
folder_save = strcat('AnalysisMLnew_S','_','Time_Int',num2str(user_input_tracks{1}),'_',num2str(user_input_tracks{4}),'_','Trkwd_',num2str(user_input_tracks{5}),'_','datpt_',num2str(user_input_tracks{2}),'_','Spt_Thr_', num2str(user_input_tracks{6}));
mkdir(folder_save);
time_scale = str2num(user_input_tracks{1});
data_point = str2num(user_input_tracks{2});

data_point_intensity = str2num(user_input_tracks{3});
spt_thresh = str2num(user_input_tracks{6});
for j = 1:num_files_images
bin_image = imread(filenames_images{1,j});
%%
% % make a copy of the original image
%image = bin_image;
%Create a disk-shaped structuring element with a radius of 5 pixels
%se = strel('disk', 1);
%Dilate the binary mask
%bin_image = imdilate(image, se);

%Display the original and dilated masks for comparison
%figure;
%subplot(1, 2, 1);
%imshow(image, [min(image(:)) max(image(:))]);
%title('Original Mask');

%subplot(1, 2, 2);
%imshow(bin_image, [min(bin_image(:)) max(bin_image(:))]);
%title('Dilated Mask');
%%
[row, column, v] = find (bin_image > 0);
%% 

filename_spot = filenames_spots{1,j};
filename_track = filenames_tracks{1,j};
Table_Track = csvread(filename_track);
Table_Spot = csvread(filename_spot);


%% 

Quality_Tracks = Table_Track;%.data;
%the tracks landed in the s phase (binary mask =1)
Quality_Tracks_seg = zeros(length(Quality_Tracks(:,1)),18);
for i = 1:length(Quality_Tracks(:,1))
    x_coord = round(Quality_Tracks(i,17));
    y_coord = round(Quality_Tracks(i,18));
    row_find = find (row(:,1) == y_coord);
    if isempty(row_find) ==1
        continue
    end
    if ismember (x_coord, column(row_find,1)) == 1
         Quality_Tracks_seg (i,:) = Quality_Tracks(i,:);
    else 
        continue
    end
  
    
end
save_name_tracks_seg = strrep(filename_track, 'tracks.csv', 'seg.mat');   

%% 
Quality_Tracks_seg = Quality_Tracks_seg(any(Quality_Tracks_seg,2),:);

% if the track length is lower than 4 it discards it (cause its too short)
thresh_find = find (Quality_Tracks_seg(:,2)<data_point);
Quality_Tracks_seg(thresh_find,:) = [];


%% 
intensities_track = zeros(length(Quality_Tracks_seg(:,1)),1);
spot_widths_track = zeros(length(Quality_Tracks_seg(:,1)),1);
%SNR_track = zeros(length(Quality_Tracks_seg(:,1)),1);
Track_mate_training = zeros(length(Quality_Tracks_seg(:,1)),13);
spot_dat = Table_Spot;%.data;
Quality_Tracks_Seg2 = zeros(length(Quality_Tracks_seg(:,1)),18);
for i = 1:length(Quality_Tracks_seg(:,1))
    ID = Quality_Tracks_seg(i,1);
    
    ID_find = find(spot_dat(:,1)==ID);
    %spot_dat = Table_Spot.data;
    ID_spots = spot_dat(ID_find,:);
    [~, idx] = sort(ID_spots(:,2),1);
    rev_spots = ID_spots(idx,:);
    intensities_track_spot = rev_spots(:,5);

    mean_track_intensity_all = mean(intensities_track_spot(1:end,1));

    max_track_intensity = max(intensities_track_spot(1:end,1));
    % 14 th column = the track duration

    if Quality_Tracks_seg(i,2)/(Quality_Tracks_seg(i,14)+1)>spt_thresh
        continue
    else
        %Track_mate_training = [spt width, 2:6 : speed values,7:11 :quality values ,mean intensity, max intensity]
        %3: spot width
    Track_mate_training(i,1) = Quality_Tracks_seg(i,3);
    Track_mate_training(i,13) = max_track_intensity;

    % speed values 
    Track_mate_training(i,2:6) = Quality_Tracks_seg(i,4:8);
    Track_mate_training(i,7:11) = Quality_Tracks_seg(i,9:13);
    Track_mate_training(i,12) = mean_track_intensity_all;
    Quality_Tracks_Seg2(i,:) = Quality_Tracks_seg(i,:);

    end
end
Quality_Tracks_Seg2 = Quality_Tracks_Seg2(any(Quality_Tracks_Seg2,2),:);
Track_mate_training = Track_mate_training(any(Track_mate_training,2),:);

save_name_tracks = strrep(filename_track, '.csv', 'data.mat');
% saves 3 fields:1) Segmented_Tracks which is the tracks landed in the s
% phase noclei
%2. Training : contains the 13 columns (taken from the tracks.csv and spot.csv :%Track_mate_training = [spt width, 2:6 : speed values,7:11 :quality values ,mean intensity, max intensity]
data_tracks = struct ('Segmented_Tracks',Quality_Tracks_Seg2, 'Training', Track_mate_training);
save(strcat(folder_save,'/',save_name_tracks), 'data_tracks')
end

    
    
%% 


