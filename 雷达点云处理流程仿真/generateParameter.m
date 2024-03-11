% 参数设置
function parameter = generateParameter()
 
    parameter.c = 3e8;             %光速
    parameter.stratFreq = 76.5e9;  %起始频率


    parameter.Tr = 10e-6;          %扫频时间 也就是周期
    parameter.Samples = 256;       %采样点
    parameter.Fs = 25.6e6;         %采样率

    parameter.rangeBin = parameter.Samples ;      %rangebin
    parameter.Chirps = 512;        %chirp数
    parameter.dopplerBin = parameter.Chirps;    %dopplerbin

    parameter.Slope = 30e12;       %chirp斜率
    parameter.Bandwidth = parameter.Slope * parameter.Tr ; %发射信号有效带宽
    parameter.BandwidthValid = parameter.Samples/parameter.Fs*parameter.Slope; %发射信号带宽
    parameter.centerFreq = parameter.stratFreq + parameter.Bandwidth / 2; %中心频率
    parameter.lambda = parameter.c / parameter.centerFreq; %波长

    parameter.txAntenna = ones(1,3); %发射天线个数
    parameter.rxAntenna = ones(1,4); %接收天线个数
    parameter.txNum = length(parameter.txAntenna);
    parameter.rxNum = length(parameter.rxAntenna);
    parameter.virtualAntenna = length(parameter.txAntenna) * length(parameter.rxAntenna);
    
    parameter.dz = parameter.lambda / 2; %接收天线俯仰间距
    parameter.dx = parameter.lambda / 2; %接收天线水平间距
    parameter.doaMethod = 2; %测角方法选择 1-dbf  2-fft 3-capon
    parameter.target = [
                        100 -20 0; %target1 range speed angle
                        0  10  -30;  %target2 range speed angle
                        0  20   30;  %target2 range speed angle
                        ];
end
