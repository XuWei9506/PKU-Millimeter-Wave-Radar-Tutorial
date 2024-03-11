%% 雷达参数设置
function parameter = generateParameter()
 
    parameter.c = 3e8;                                  %光速
    
    parameter.stratFreq = 77e9;                         %起始频率

    parameter.Tr = 60e-6;                               %扫频时间
    parameter.Idle_time = 100e-6;                       %空闲时间
    parameter.Tc = parameter.Tr+parameter.Idle_time;    %Chirp之间的间隔
    parameter.Samples = 256;                            %采样点
    parameter.Fs = 10e6;                                %采样率
    parameter.Tframe_set = 80e-3;                       % 帧周期

    parameter.rangeBin = parameter.Samples ;            %rangebin
    parameter.Chirps = 128;                             %chirp数
    parameter.dopplerBin = parameter.Chirps;            %dopplerbin

    parameter.Slope = 29.982e12;                            %chirp斜率
    parameter.Bandwidth = parameter.Slope * parameter.Tr ;  %发射信号有效带宽
    parameter.BandwidthValid = parameter.Samples/parameter.Fs*parameter.Slope;  %发射信号带宽
    parameter.centerFreq = parameter.stratFreq + parameter.Bandwidth / 2;       %中心频率
    parameter.lambda = parameter.c / parameter.centerFreq;  %波长

    parameter.txAntenna = ones(1,3); %发射天线个数
    parameter.rxAntenna = ones(1,4); %接收天线个数
    parameter.txNum = length(parameter.txAntenna);
    parameter.rxNum = length(parameter.rxAntenna);
    parameter.virtualAntenna = length(parameter.txAntenna) * length(parameter.rxAntenna);
    parameter.angleBin = 180;            %anglebin
    
    parameter.dz = parameter.lambda / 2; %接收天线俯仰间距
    parameter.dx = parameter.lambda / 2; %接收天线水平间距
    
    parameter.numCPI = 50; % 帧数
    
end
