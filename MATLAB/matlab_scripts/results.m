%%%%%%%%%%%%%% GET DATA %%%%%%%%%%%%

% clear all
%close all

%Get images and sort after date modified
originals = dir('../to_matlab/origs_terrible/*.png');
fakes = dir('../to_matlab/fakes_terrible/*.png');
% originals = dir('C:\Users\davwa\Desktop\CT-image-enhancement\CycleGAN\datasets\Quality\testA/*.png');
% fakes = dir('C:\Users\davwa\Desktop\CT-image-enhancement\CycleGAN\test_Quality/*.png');
test = false; 
[originals, fakes, L] = get_data(originals, fakes, test);

%%%%% Testing
%% 
n = 40090;
figure(80)
orig = originals(n).name
orig_path = strcat('../to_matlab/origs_terrible/', orig);
imshow(orig_path)

figure(81)
fake = fakes(n).name
fakepath = strcat('../to_matlab/fakes_terrible/', fake);
imshow(fakepath)

%%%%%%%%%%%%%% INITIATE DATA STRUCTURES %%%%%%%%%%%%
%%
images_per_epoch = 1478;
% images_per_epoch = 12628;
% images_per_epoch = 12624;
% images_per_epoch = 4096;
n_of_epochs = floor(L/images_per_epoch); %data sampled from X epochs 

%For BA, takes all values from one (last) epoch
orig_SNR_vector = zeros(images_per_epoch,1);
fake_SNR_vector = zeros(images_per_epoch,1);
orig_CNR_vector = zeros(images_per_epoch,1);
fake_CNR_vector = zeros(images_per_epoch,1);

SNR_vector = zeros(n_of_epochs,1);
ratio_SNR_vector = zeros(n_of_epochs,1);
CNR_vector = zeros(n_of_epochs,1);
ratio_CNR_vector = zeros(n_of_epochs,1);
UIQI_vector = zeros(n_of_epochs,1);

SNR_epoch = 0;
ratio_SNR_epoch = 0;
CNR_epoch = 0;
ratio_CNR_epoch = 0;
UIQI_epoch = 0;

%%%%%%%%%%%%%% GIANT FOR LOOP, FILL VECTORS %%%%%%%%%%%%
%%
size = 256;
epoch = 1;
j=1;
for i = 1:L
    i
    % GET IMAGES ROIS AND BACKGROUNDS
    %Get original
    if test
        orig_index = mod(i-1,images_per_epoch)+1;
        orig_name = originals(orig_index).name;
    else
        orig_name = originals(i).name;
    end
    orig_path = strcat('../to_matlab/origs_terrible/', orig_name); 
    orig = get_image(orig_path);
    orig_outside = get_outside(orig, size, size);
    [orig_SNR, orig_CNR] = get_SNR_CNR(orig, orig_outside, size, size);

    % Get fake
    fake_name = fakes(i).name;
    fake_path = strcat('../to_matlab/fakes_terrible/', fake_name);
    fake = get_image(fake_path);
    [fake_SNR, fake_CNR] = get_SNR_CNR(fake, orig_outside, size, size); 
       
    % CALCULATIONS
    % SNR
    SNR_diff = fake_SNR - orig_SNR;
    SNR_ratio = SNR_diff / orig_SNR;
    if sign(SNR_diff) ~= sign(SNR_ratio)
        SNR_ratio = SNR_ratio * -1;
    end
    SNR_epoch = SNR_epoch + SNR_diff;
    ratio_SNR_epoch = ratio_SNR_epoch + SNR_ratio;
    % CNR
    CNR_diff = fake_CNR - orig_CNR;
    CNR_ratio = CNR_diff / orig_CNR;
    if sign(CNR_diff) ~= sign(CNR_ratio)
        CNR_ratio = CNR_ratio * -1;
    end
    CNR_epoch = CNR_epoch + CNR_diff;
    ratio_CNR_epoch = ratio_CNR_epoch + CNR_ratio;
    % UIQI
    [UIQI, ~] = get_uiqi(orig, fake);
    UIQI_epoch = UIQI_epoch + UIQI;

    if mod(i,images_per_epoch) == 0 % End of epoch?
        %CALCULATE MEAN
        mean_SNR = SNR_epoch / images_per_epoch;
        mean_SNR_ratio = ratio_SNR_epoch / images_per_epoch;
        mean_CNR = CNR_epoch / images_per_epoch;
        mean_CNR_ratio = ratio_CNR_epoch / images_per_epoch;
        mean_UIQI = UIQI_epoch / images_per_epoch;
        %ADD TO VECTOR
        SNR_vector(epoch) = mean_SNR;
        ratio_SNR_vector(epoch) = mean_SNR_ratio;
        CNR_vector(epoch) = mean_CNR;
        ratio_CNR_vector(epoch) = mean_CNR_ratio;
        UIQI_vector(epoch) = mean_UIQI;
        %RESET EPOCH VALUE
        SNR_epoch = 0;
        ratio_SNR_epoch = 0;
        CNR_epoch = 0;
        ratio_CNR_epoch = 0;
        UIQI_epoch = 0;
        %STEP EPOCH
        epoch = epoch + 1;
    end
    
    %If it is the last epoch, start saving for BA
    if i > (L-images_per_epoch+1)
        orig_SNR_vector(j) = orig_SNR;
        fake_SNR_vector(j) = fake_SNR;
        orig_CNR_vector(j) = orig_CNR;
        fake_CNR_vector(j) = fake_CNR;
        j = j + 1;
    end
end

%%%%%%%%%%%%%% PLOT RESULTS WITH TRENDS%%%%%%%%%%%%
%%
%maybe redo this to one single function call
close all;

do_plot(SNR_vector , 1, 'SNR', 'SNR difference');
do_plot(ratio_SNR_vector, 2, 'SNR ratio', 'SNR difference / original SNR');
do_plot(CNR_vector, 3, 'CNR', 'CNR difference');
do_plot(ratio_CNR_vector, 4, 'CNR', 'CNR difference / original CNR (percentage development)');
do_plot(UIQI_vector, 7, 'UIQI', 'UIQI');

%%%%%%%%%%%%%% BLAND ALTMAN AND CORRELATION %%%%%%%%%%%%
%%
close all;
[rpc, ~, stats] = BlandAltman(orig_SNR_vector, fake_SNR_vector, {'Orig SNR','Fake SNR'},...
    'Correlation plot and Bland Altman', 'data', 'baYLimMode', 'Auto', 'data1Mode', 'Truth');
[rpc, ~, stats] = BlandAltman(orig_CNR_vector, fake_CNR_vector, {'Orig CNR','Fake CNR'},...
    'Correlation plot and Bland Altman', 'data', 'baYLimMode', 'Auto', 'data1Mode', 'Truth');

diff_SNR_last_vector = fake_SNR_vector - orig_SNR_vector;
diff_CNR_last_vector = fake_CNR_vector - orig_CNR_vector;
ratio_SNR_last_vector = diff_SNR_last_vector ./ orig_SNR_vector;
ratio_CNR_last_vector = diff_CNR_last_vector ./ orig_CNR_vector;

figure(10)
% plot(orig_SNR_vector, diff_SNR_last_vector,'*')
plot(orig_SNR_vector, ratio_SNR_last_vector,'*')
title('SNR ratio vs original values')

figure(11)
% plot(orig_CNR_vector, diff_CNR_last_vector,'*')
plot(orig_CNR_vector, ratio_CNR_last_vector,'*')
title('CNR ratio vs original values')
%%
%Save workspace
total_epochs = 17;
saved_every = 4;
save('batch8_17epochs', 'SNRvector', 'CNRvector', 'ratioSNRvector',...
    'ratioCNRvector', 'total_epochs', 'saved_every', 'UIQIvector', ...
    'origSNRvector', 'fakeSNRvector', 'origCNRvector', 'fakeCNRvector')