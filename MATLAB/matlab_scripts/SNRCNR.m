%%%%%%%%%%%%%% INITIATE DATA STRUCTURES %%%%%%%%%%%%

%clear all
%close all

%Get images and sort after date modified
%images = dir('E:\david\development\MATLAB\to_matlab/*.png');
originals = dir('P:\result\originals1/*.png');
fields = fieldnames(originals);
cells = struct2cell(originals);
sz = size(cells);
cells = reshape(cells, sz(1), []);
cells = cells';
% Sort by field "date"
cells = sortrows(cells, 3);
cells = reshape(cells', sz);
originals = cell2struct(cells, fields, 1);

fakes = dir('P:\result\fakes1/*.png');
fields = fieldnames(fakes);
cells = struct2cell(fakes);
sz = size(cells);
cells = reshape(cells, sz(1), []);
cells = cells';
% Sort by field "date"
cells = sortrows(cells, 3);
cells = reshape(cells', sz);
fakes = cell2struct(cells, fields, 1);

if length(originals) ~= length(fakes)
    disp('Not same length of directories');
    disp('Terminating script');
    return
end


%%%%%%%%%%%%%% GIANT FOR LOOP, FILL VECTORS %%%%%%%%%%%%
%%
SNRimprove = zeros(16,1);
CNRimprove = zeros(16,1);
epochSNRimprove = 0;
epochCNRimprove = 0;

SNRactual = zeros(16,1);
CNRactual = zeros(16,1);
epochSNRactual = 0;
epochCNRactual = 0;

epoch = 1;

for i = 1:length(originals)
    i
    %Get original
    originalName = originals(i).name;
    originalPath = strcat('../to_matlab/originals1/', originalName);
    %path = strcat('E:\david\development\MATLAB\to_matlab/', name);
    %path = strcat('C:\Users\davwa\Desktop\Exjobb\Development\MATLAB\to_matlab/', name);
    original = im2double(imread(originalPath));

    %Get original ROI
    [height,width] = size(original);
    originalC = centerOfMass(original);
    originalCenterX = round(originalC(2));
    originalCenterY = round(originalC(1));

    mask = double(zeros(height, width));
    maskSizeX = round(width/4);
    maskSizeY = round(height/4);
    mask(originalCenterY-maskSizeY:originalCenterY+maskSizeY,originalCenterX-maskSizeX:originalCenterX+maskSizeX) = 1;
    maskedImage = original .* mask;
    originalROI = maskedImage(originalCenterY-maskSizeY:originalCenterY+maskSizeY,originalCenterX-maskSizeX:originalCenterX+maskSizeX);

    %Get original background
    %Values in image range from 0 to 1, so by assigning the values
    %of ROI to 2, the background can be found
    original(originalCenterY-maskSizeY:originalCenterY+maskSizeY,originalCenterX-maskSizeX:originalCenterX+maskSizeX) = 2;
    %twos = sum(image(:) == 2)
    backgroundIndices = find(original < 2);
    backgroundValues = original(backgroundIndices);

    originalMeanROI = mean(mean(originalROI));
    %Add 1 to normalize over number of pixels
    originalStdBackground = std(backgroundValues, 1);
    originalMeanBackground = mean(backgroundValues);

    % Get fake image
    fakeName = fakes(i).name;
    fakePath = strcat('../to_matlab/fakes1/', fakeName);
    %path = strcat('E:\david\development\MATLAB\to_matlab/', name);
    %path = strcat('C:\Users\davwa\Desktop\Exjobb\Development\MATLAB\to_matlab/', name);
    fake = im2double(imread(fakePath));
    fake = rgb2gray(fake);

    %Get fake ROI
    [height,width] = size(fake);
    fakeC = centerOfMass(fake);
    fakeCenterX = round(fakeC(2));
    fakeCenterY = round(fakeC(1));

    mask = double(zeros(height, width));
    maskSizeX = round(width/4);
    maskSizeY = round(height/4);
    mask(fakeCenterY-maskSizeY:fakeCenterY+maskSizeY,fakeCenterX-maskSizeX:fakeCenterX+maskSizeX) = 1;
    maskedImage = fake .* mask;
    fakeROI = maskedImage(fakeCenterY-maskSizeY:fakeCenterY+maskSizeY,fakeCenterX-maskSizeX:fakeCenterX+maskSizeX);

    fakeMeanROI = mean(mean(fakeROI));

    originalSNR = originalMeanROI / originalStdBackground;
    originalCNR = originalMeanROI - originalMeanBackground;
    fakeSNR = fakeMeanROI / originalStdBackground;
    fakeCNR = fakeMeanROI - originalMeanBackground;

    SNRdifference = fakeSNR - originalSNR;
    CNRdifference = fakeCNR - originalCNR;
    epochSNRimprove = epochSNRimprove + SNRdifference;
    epochCNRimprove = epochCNRimprove + CNRdifference;

    epochSNRactual = epochSNRactual + fakeSNR;
    epochCNRactual = epochCNRactual + fakeCNR;

    % End of epoch?
    if mod(i,1478) == 0
        meanSNR = epochSNRimprove / 1478;
        meanCNR = epochCNRimprove / 1478;
        SNRimprove(epoch) = meanSNR;
        CNRimprove(epoch) = meanCNR;
        epochSNRimprove = 0;
        epochCNRimprove = 0;

        meanSNR = epochSNRactual / 1478;
        meanCNR = epochCNRactual / 1478;
        SNRactual(epoch) = meanSNR;
        CNRactual(epoch) = meanCNR;
        epochSNRactual = 0;
        epochCNRactual = 0;
        epoch = epoch + 1;
    end
end

%%%%%%%%%%%%%% PLOT RESULTS %%%%%%%%%%%%
%%
figure(70)
hist(SNRimprove);
title('SNR improvement')
xlabel('SNR difference')
ylabel('Epochs')

figure(77)
hist(CNRimprove);
title('CNR improvement')
xlabel('CNR difference')
ylabel('Epochs')

%%
figure(1)
plot(SNRimprove);
title('SNR improvement')
xlabel('Epoch')
ylabel('SNR difference')

figure(2)
plot(CNRimprove);
title('CNR improvement')
xlabel('Epoch')
ylabel('CNR difference')

figure(3)
plot(SNRactual);
title('Actual SNR')
xlabel('Epoch')
ylabel('SNR')

figure(4)
plot(CNRactual);
title('Actual CNR')
xlabel('Epoch')
ylabel('CNR')
