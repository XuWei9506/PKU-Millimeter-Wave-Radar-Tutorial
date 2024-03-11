clear;close all;clc;

%% 雷达参数（使用mmWave Studio默认参数）
global parameter;
parameter = generateParameter();
Range_Res=parameter.c/(2*parameter.BandwidthValid);  %距离分辨率
Range_Index=Range_Res*(1:parameter.rangeBin);
Speed_Res=parameter.lambda/(2*parameter.dopplerBin*parameter.Tc);
Speed_Index=(-parameter.dopplerBin/2:1:parameter.dopplerBin/2-1)*Speed_Res;
Azimuth_Index=(-parameter.angleBin/2:1:parameter.angleBin/2-1);
global frame;
frame = 1;  %第frame帧

%% 读取原始ADC数据
fname='C:\ti\mmwave_studio_02_01_01_00\mmWaveStudio\PostProc\adc_data.bin';
data_radar=DCA1000_Read_Data(fname);

%% 距离FFT
range_win = hamming(parameter.Samples);   %加海明窗
doppler_win = hamming(parameter.Chirps);
range_profile = zeros(parameter.Samples,parameter.Chirps,parameter.txNum*parameter.rxNum);
for k=1:parameter.txNum*parameter.rxNum
   for m=1:parameter.Chirps
      temp=data_radar(:,m,k).*range_win;    %加窗函数
      temp_fft=fft(temp,parameter.rangeBin);    %对每个chirp做N点FFT
      range_profile(:,m,k)=temp_fft;
   end
end

%% 多普勒FFT
speed_profile = zeros(parameter.Samples,parameter.Chirps,parameter.txNum*parameter.rxNum);
for k=1:parameter.rxNum
    for n=1:parameter.rangeBin
      temp=range_profile(n,:,k).*(doppler_win)';    
      temp_fft=fftshift(fft(temp,parameter.dopplerBin));    %对rangeFFT结果进行M点FFT
      speed_profile(n,:,k)=temp_fft;  
    end
end

%% 方位角FFT
angle_profile = zeros(parameter.Samples,parameter.Chirps,parameter.angleBin);
for n=1:parameter.rangeBin   %range
    for m=1:parameter.dopplerBin   %chirp
      temp=speed_profile(n,m,:);   
      temp=temp(1:8);
      temp_fft=fftshift(fft(temp,parameter.angleBin));    %对2D FFT结果进行Q点FFT
      angle_profile(n,m,:)=temp_fft;  
    end
end

%% 绘制2D FFT的三维视图
figure(1);
speed_profile_temp = reshape(speed_profile(:,:,1),parameter.rangeBin,parameter.dopplerBin);   
speed_profile_Temp = speed_profile_temp';
[X,Y]=meshgrid((0:parameter.rangeBin-1)*parameter.Fs*parameter.c/parameter.rangeBin/2/parameter.Slope,(-parameter.dopplerBin/2:parameter.dopplerBin/2-1)*parameter.lambda/parameter.Tc/parameter.dopplerBin/2);
mesh(X,Y,(abs(speed_profile_Temp)));
xlabel('距离(m)');ylabel('速度(m/s)');zlabel('信号幅值');
title('2D FFT处理三维视图');
xlim([0 (parameter.rangeBin-1)*parameter.Fs*parameter.c/parameter.rangeBin/2/parameter.Slope]); ylim([(-parameter.dopplerBin/2)*parameter.lambda/parameter.Tc/parameter.dopplerBin/2 (parameter.dopplerBin/2-1)*parameter.lambda/parameter.Tc/parameter.dopplerBin/2]);

%% 得到Range-Azimuth热力图
angle_profile_display=abs(angle_profile);
angle_profile_display=squeeze(sum(angle_profile_display,2));
figure(2);
imagesc(Azimuth_Index,Range_Index,angle_profile_display);
set(gca,'YDir','normal');
title('Range-Azimuth Heatmap', 'FontWeight', 'bold');
xlabel('Azimuth(°)');
ylabel('Range(m)');
