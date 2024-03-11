%% 功能：毫米波雷达点云生成流程MATLAB仿真
%% 思考：如何将IWR1843EVM+DCA1000采集得到的数据移植到这份代码上

clc;clear;close all;

Frame =1; %帧数设置；

for frame =1:Frame %帧数设置
    
%% 雷达参数设置
parameter  = generateParameter();
parameter.frame = frame;

%% 雷达回波信号建模
rawData    = generateSignal(parameter);
firstChirp = rawData(1,:,1);

figure(1);
plot(real(firstChirp));
hold on;
plot(imag(firstChirp));
xlabel('采样点数'); ylabel('幅值');title('原始数据实虚部');%第1个chirp。

%% 雷达信号处理
rangeRes     = parameter.c / (2 * parameter.BandwidthValid); %距离分辨率 有效带宽
rangeIndex   = (0:parameter.rangeBin-1) * rangeRes;
speedRes     = parameter.lambda / (2 * parameter.dopplerBin * parameter.Tr);
dopplerIndex = (-parameter.dopplerBin/2:1:parameter.dopplerBin/2 - 1) * speedRes;
angleRes     = parameter.lambda / (parameter.virtualAntenna * parameter.dx) * 180 / pi;
angleIndex   = (-parameter.virtualAntenna/2:1:parameter.virtualAntenna/2 - 1) * angleRes;

%% 1D FFT
fft1dData    = fft(firstChirp);
figure(2);
plot(rangeIndex,db(abs(fft1dData)./max(abs(fft1dData))));
xlabel('距离(m)'); ylabel('幅值(dB)');title('距离维FFT');

%% 2D FFT
%% 距离-多普勒谱
channelNum    = size(rawData,1);
rangebinNum   = size(rawData,2);
dopplerbinNum = size(rawData,3);
fft2dDataPower= zeros(size(rawData));
fft2dDataDB   = zeros(size(rawData));
fftRADataPower= zeros(size(rawData));
for chanId = 1:1:channelNum
    fft2dDataPower(chanId,:,:) = RDfftMatrix(rawData(chanId,:,:));
end

figure(3);
mesh(dopplerIndex',rangeIndex,db(abs(squeeze(fft2dDataPower(chanId,:,:)))));
view(2);
xlabel('速度(m/s)'); ylabel('距离(m)'); zlabel('幅值');
title('距离-多普勒谱');
mesh(abs(squeeze(fft2dDataPower(chanId,:,:))));
display_static=[30,100,400,300];
set(gcf,'Position',display_static); % [左下角x,左下角y,宽度,高度]

%% 距离-角度谱
for dopplerId = 1:1:dopplerbinNum
    fftRADataPower(:,:,dopplerId) = RAfftMatrix(rawData(:,:,dopplerId));
end

figure(4);
imagesc(rangeIndex,angleIndex,(abs(squeeze(fftRADataPower(:,:,dopplerId)))));
view(2);
xlabel('距离(m)'); ylabel('角度'); zlabel('幅值');
title('距离-角度谱');

%% 多通道非相干积累
accumulateRD = chan_Accumulate((fft2dDataPower));
figure(5);
imagesc(dopplerIndex',rangeIndex,db(accumulateRD));
view(2);
xlabel('速度(m/s)'); ylabel('距离(m)'); zlabel('幅值');
title(['通道积累 第',num2str(frame),'帧']);
pause(0.01);

%% CFAR检测
cfarParameter = generateCfarParameter(); %生成cfar数据
[pointList,cfarRD] = cfar(cfarParameter,db(accumulateRD));
figure(6);
mesh(dopplerIndex',rangeIndex,cfarRD);
xlabel('速度(m/s)'); ylabel('距离(m)'); zlabel('幅值');
title('cfar');
display_static=[30,100,400,300];
set(gcf,'Position',display_static); % [左下角x,左下角y,宽度,高度]

%% peakSearch
[RD_pearkSearch,peakSearchList] = peakSearch(cfarRD,pointList);
detectPointNum = size(peakSearchList,2);

%% DOA估计
for targetIdx = 1:detectPointNum
    rangeBin = peakSearchList(1,targetIdx);
    speedBin = peakSearchList(2,targetIdx);
    range = (rangeBin - 1) * rangeRes;
    speed = (speedBin - parameter.dopplerBin/2 - 1) * speedRes;
    ant = squeeze(fft2dDataPower(:,rangeBin,speedBin));
    [angle,doa_abs] = doa(parameter,ant);
    
    figure(7);
    angleIndex = asin((-512:1:512-1)/512) * 180 / pi;
    hold on;
    plot(angleIndex,doa_abs);grid on
    title('测角结果');
    xlabel('角度');ylabel('幅值');
    fprintf('目标%d的距离为%f,速度为%f,角度为%f\n',targetIdx,range,speed,angle);
    
end

end
