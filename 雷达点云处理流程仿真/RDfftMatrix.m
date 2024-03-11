%% 2DFFT得到距离-速度热力图

function fft2dData = RDfftMatrix(rawData)
    rawData = squeeze(rawData);
    [rangeBin,dopplerBin] = size(rawData);
    rangeWin = hanning(rangeBin);
    rangeWin2D = repmat(rangeWin,1,dopplerBin);
    dopplerWin = hanning(dopplerBin)';
    dopplerWin2D = repmat(dopplerWin,rangeBin,1);
    rawDataWin = rawData .* rangeWin2D;
    fft1dData = fft(rawDataWin,rangeBin,1);
    fft1dDataWin = fft1dData .* dopplerWin2D;
    fft2dData = fftshift(fft(fft1dDataWin,dopplerBin,2),2);
end
