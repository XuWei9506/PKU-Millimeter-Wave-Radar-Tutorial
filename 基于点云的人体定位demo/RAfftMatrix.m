%% 2DFFT得到距离-角度热力图

function fft2dData = RAfftMatrix(rawData)

    rawData = squeeze(rawData);
    [angleBin,rangeBin] = size(rawData);

    angleWin = hanning(angleBin);
    angleWin2D = repmat(angleWin,1,rangeBin);

    rangeWin = hanning(rangeBin)';
    rangeWin2D = repmat(rangeWin,angleBin,1);

    rawDataWin = rawData .* angleWin2D;
    fft1dData = fftshift(fft(rawDataWin,angleBin,1));

    fft1dDataWin = fft1dData .* rangeWin2D;
    fft2dData = fft(fft1dDataWin,rangeBin,2);
end
