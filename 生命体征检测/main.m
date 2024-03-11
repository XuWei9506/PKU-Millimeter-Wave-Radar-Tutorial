%% 功能：单人呼吸心跳原始数据采集与MATLAB处理
%% 基于平台 IWR1642EVM+DCA1000
%% 思考：如何将IWR1843EVM+DCA1000采集得到的数据移植到这份代码上
%% ========================================================================
clc;clear;close all;
%% =========================================================================
%% 读取数据部分
numADCSamples = 200; % number of ADC samples per chirp
numADCBits = 16;     % number of ADC bits per sample
numRX = 4;           % number of receivers
numLanes = 2;        % do not change. number of lanes is always 2
isReal = 0;          % set to 1 if real only data, 0 if complex data0
chirpLoop = 2;

%% 雷达参数设置
Fs=4e6;             %ADC采样率 见配置说明
c=3*1e8;            %光速
ts=numADCSamples/Fs;%ADC采样时间
slope=70e12;        %调频斜率 
B_valid =ts*slope;  %有效带宽
detaR=c/(2*B_valid);%距离分辨率

%% 读取Bin文件
Filename = 'xxx.bin';  %文件名
fid = fopen(Filename,'r');
adcDataRow = fread(fid, 'int16');
if numADCBits ~= 16
    l_max = 2^(numADCBits-1)-1;
    adcDataRow(adcDataRow > l_max) = adcDataRow(adcDataRow > l_max) - 2^numADCBits;
end
fclose(fid);

fileSize = size(adcDataRow, 1);
PRTnum = fix(fileSize/(numADCSamples*numRX));
fileSize = PRTnum * numADCSamples*numRX;
adcData = adcDataRow(1:fileSize);
% real data reshape, filesize = numADCSamples*numChirps
if isReal
    numChirps = fileSize/numADCSamples/numRX;
    LVDS = zeros(1, fileSize);
    %create column for each chirp
    LVDS = reshape(adcData, numADCSamples*numRX, numChirps);
    %each row is data from one chirp
    LVDS = LVDS.';
else
    numChirps = fileSize/2/numADCSamples/numRX;     %含有实部虚部除以2
    LVDS = zeros(1, fileSize/2);
    %combine real and imaginary part into complex data
    %read in file: 2I is followed by 2Q
    counter = 1;
    for i=1:4:fileSize-1
        LVDS(1,counter) = adcData(i) + sqrt(-1)*adcData(i+2);
        LVDS(1,counter+1) = adcData(i+1)+sqrt(-1)*adcData(i+3); counter = counter + 2;
    end
    % create column for each chirp
    LVDS = reshape(LVDS, numADCSamples*numRX, numChirps);
    %each row is data from one chirp
    LVDS = LVDS.';
end

%% 重组数据
adcData = zeros(numRX,numChirps*numADCSamples);
for row = 1:numRX
    for i = 1:numChirps
        adcData(row, (i-1)*numADCSamples+1:i*numADCSamples) = LVDS(i, (row-1)*numADCSamples+1:row*numADCSamples);
    end
end

retVal= reshape(adcData(1, :), numADCSamples, numChirps); %取第二个接收天线数据，数据存储方式为一个chirp一列

process_adc = retVal(:,1:4:end);

	
%% 距离维FFT（1个chirp)
% figure;
% plot((1:numADCSamples)*detaR,db(abs(fft(process_adc(:,1)))));
% xlabel('距离（m）');
% ylabel('幅度(dB)');
% title('距离维FFT（1个chirp）');
% figure;
% plot(db(abs(fft(process_adc(:,1)))))

%% 相位解缠绕部分
RangFFT = 512;
fft_data_last = zeros(1,RangFFT); 
range_max = 0;
adcdata = process_adc;
numChirps = size(adcdata, 2);

%% 距离维FFT
fft_data = fft(adcdata,RangFFT); 
fft_data = fft_data.';
fft_data_abs = abs(fft_data);
fft_data_abs(:,1:4)=0; %去除直流分量
real_data = real(fft_data);
imag_data = imag(fft_data);


for i = 1:numChirps
    for j = 1:RangFFT  %对每一个距离点取相位 extract phase
        angle_fft(i,j) = atan2(imag_data(i, j),real_data(i, j));
    end
end

% Range-bin tracking 找出能量最大的点，即人体的位置  
for j = 1:RangFFT
    for i = 1:numChirps % 进行非相干积累
        fft_data_last(j) = fft_data_last(j) + fft_data_abs(i,j);
    end
    if ( fft_data_last(j) > range_max)
        range_max = fft_data_last(j);
        max_num = j;
    end
end 

%% 取出能量最大点的相位  extract phase from selected range bin
angle_fft_last = angle_fft(:,max_num);

%% 进行相位解缠  phase unwrapping(手动解)，自动解可以采用MATLAB自带的函数unwrap()
n = 1;
for i = 1+1:numChirps
    diff = angle_fft_last(i) - angle_fft_last(i-1);
    if diff > pi
        angle_fft_last(i:end) = angle_fft_last(i:end) - 2*pi;
        n = n + 1;
    elseif diff < -pi
        angle_fft_last(i:end) = angle_fft_last(i:end) + 2*pi;  
    end
end

%% phase difference 相位差分后的数据
angle_fft_last2=zeros(1,numChirps);
for i = 1:numChirps-1
    angle_fft_last2(i) = angle_fft_last(i+1) - angle_fft_last(i);
    angle_fft_last2(numChirps)=angle_fft_last(numChirps)-angle_fft_last(numChirps-1);
end 

% figure;
% plot(angle_fft_last2);
% xlabel('点数（N）');
% ylabel('相位');
% title('相位差分后的结果');

%%  IIR带通滤波 Bandpass Filter 0.1-0.6hz，得到呼吸的数据
fs =20; %呼吸心跳信号采样率
COE1=chebyshev_IIR; %采用fdatool生成函数
save coe1.mat COE1;
breath_data = filter(COE1,angle_fft_last2); 

% figure;
% plot(breath_data);
% xlabel('时间/点数');
% ylabel('幅度');
% title('呼吸时域波形');

%% 谱估计 -FFT -Peak interval
N1=length(breath_data);
fshift = (-N1/2:N1/2-1)*(fs/N1); % zero-centered frequency
breath_fre = abs(fftshift(fft(breath_data)));              %--FFT
% figure;
% plot(fshift,breath_fre);
% xlabel('频率（f/Hz）');
% ylabel('幅度');
% title('呼吸信号FFT  ');

breath_fre_max = 0; % 呼吸频率

breath_index1 = length(breath_fre)/2;

for i = 1:breath_index1%谱峰最大值搜索 对称其实可以取一半
    if (breath_fre(i) > breath_fre_max)    
        breath_fre_max = breath_fre(i);
        if(breath_fre_max<1e-2) %幅度置信 判断是否是存在人的呼吸
            breath_index=numChirps+1;
        else
            breath_index=i;
        end
    end
end

breath_count =(fs*(breath_index1-breath_index)/numChirps)*60; %呼吸频率解算

%% IIR带通滤波 Bandpass Filter 0.8-2hz 得到心跳的数据
COE2=chebyshev_IIR2;
save coe2.mat COE2;
heart_data = filter(COE2,angle_fft_last2); 

N1=length(heart_data);
fshift = (-N1/2:N1/2-1)*(fs/N1); % zero-centered frequency
heart_fre = abs(fftshift(fft(heart_data))); 
% figure;
% plot(fshift,heart_fre);
% xlabel('频率（f/Hz）');
% ylabel('幅度');
% title('心跳信号FFT');

heart_fre_max = 0; 
heart_index1 = length(heart_fre)/2 ;

for i = 1:heart_index1
    if (heart_fre(i) > heart_fre_max)    
        heart_fre_max = heart_fre(i);
        if(heart_fre_max<1e-2)%幅度置信 判断是否是存在人的心跳
            heart_index=numChirps+1;
        else
            heart_index=i;
        end
    end
end
heart_count =(fs*(heart_index1-(heart_index-1))/numChirps)*60%心跳频率解算

% 2399个帧，约为120s，
% 如果数据长度够长，则雷达会51.2s对呼吸数据和心跳数据进行一次刷新，
%以便实现更为精确的检测。

disp(['呼吸：',num2str(breath_count),'  心跳：',num2str(heart_count)])

%% 动画演示
%读入波形
breath_fre;
heart_fre;
count =0;
%显示波形长度
L =500;
T_frame =0.05 ;%50ms
for i = 1:length(breath_fre)-L-1
    figure(10);
    count=count+i;
    [breath_pks,breath_locs] = findpeaks(breath_data(i:i+L )) ;
    breath_fre =(60/ (L*T_frame))*length(breath_pks);

    [heart_pks,heart_locs] = findpeaks(heart_data(i:i+L )) ;
    heart_fre =(60/ (L*T_frame))*length(heart_pks);

    if count>500
        subplot(121);
        plot((i:i+L)*T_frame,breath_data(i:i+L ),'g');
        grid on
        xlim([i,i+L]*T_frame);
        ylim([-0.8,0.8]);
        hold on
        xlabel('时间（s）');
        ylabel('幅度');
        title(['呼吸时域波形',num2str(breath_fre),'次']);
        hold off
        
        subplot(122);
        plot((i:i+L)*T_frame,heart_data(i:i+L ),'r');
        grid on
        xlim([i,i+L]*T_frame);
        ylim([-0.8,0.8]);
        hold on
        xlabel('时间（s）');
        ylabel('幅度');
        title(['心跳时域波形:',num2str(heart_fre),'次']);
        hold off
    else
    
    %呼吸时域
    subplot(121);
    plot((i:i+L)*T_frame,breath_data(i:i+L ),'g');grid on
    xlim([i,i+L]*T_frame);
    ylim([-0.8,0.8]);
    hold on
    xlabel('时间（s）');
    ylabel('幅度');
    title(['呼吸时域波形:',num2str(breath_fre),'次']);
    hold off

    subplot(122);
    plot((i:i+L)*T_frame,heart_data(i:i+L ),'r');grid on
    xlim([i,i+L]*T_frame);
    ylim([-0.8,0.8]);
    hold on
    xlabel('时间（s）');
    ylabel('幅度');
    title(['心跳时域波形:',num2str(heart_fre),'次']);
    end
    hold off
end


