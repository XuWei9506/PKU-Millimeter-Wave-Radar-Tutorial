%% 生成混频信号

function rawData = generateSignal(Parameter)

    c = Parameter.c;                 %光速
    stratFreq = Parameter.stratFreq; %起始频率

    Tr = Parameter.Tr;            %扫频时间
    samples = Parameter.Samples;  %采样点
    fs = Parameter.Fs;        %采样率

    rangeBin = Parameter.rangeBin;     %rangeBin
    chirps = Parameter.Chirps;         %chirp数
    dopplerBin = Parameter.dopplerBin; %dopplerBin

    slope = Parameter.Slope;           %chirp斜率
    bandwidth = Parameter.Bandwidth;   %发射信号带宽
    centerFreq = Parameter.centerFreq; %中心频率
    lambda = Parameter.lambda;
    txAntenna = Parameter.txAntenna; %发射天线
    txNum = length(txAntenna);       %发射天线数
    rxAntenna = Parameter.rxAntenna; %接收天线
    rxNum = length(rxAntenna);       %接收天线数
    dz = Parameter.dz;          %俯仰间距
    dx = Parameter.dx;          %水平间距
    
    target = Parameter.target;  %目标
    targetNum = size(target,1); %目标数
    rawData = zeros(txNum*rxNum,rangeBin,dopplerBin);

    t = 0:1/fs:Tr-(1/fs); %chirp采样的时间序列
    for chirpId = 1:chirps
       for txId = 1:txNum 
            St = exp((1i*2*pi)*(centerFreq*(t+(chirpId-1)*Tr)+slope/2*t.^2)); %发射信号

            for rxId = 1:rxNum
                Sif = zeros(1,rangeBin);
                for targetId = 1:targetNum

                    %%连续帧 目标设置，如果不需要连续帧，令Parameter.frame=0，即可。
                    if targetId==1
                        targetRange = target(targetId,1)-Parameter.frame; 
                        targetSpeed = target(targetId,2); 
                        targetAngle = target(targetId,3);
                    elseif targetId==2
                        targetRange = target(targetId,1)+0.5*Parameter.frame; 
                        targetSpeed = target(targetId,2); 
                        targetAngle = target(targetId,3);
                    elseif targetId==3
                        targetRange = target(targetId,1)+Parameter.frame; 
                        targetSpeed = target(targetId,2); 
                        targetAngle = target(targetId,3);
                    end

                    tau = 2 * (targetRange + targetSpeed * (txId - 1) * Tr) / c;
                    fd = 2 * targetSpeed / lambda;
                    wx = ((txId-1) * rxNum + rxId) / lambda * dx * sind(targetAngle);
                    Sr = 10*exp((1i*2*pi)*((centerFreq-fd)*(t-tau+(chirpId-1) * Tr)+slope/2*(t-tau).^2 -wx));  %回波信号
                    Sif = Sif + St .* conj(Sr);
                    %叠加20dB高斯白噪声
                    Sif = awgn(Sif,20);
                end
                rawData((txId-1) * rxNum + rxId,:,chirpId) = Sif;
            end
        end
    end
end
