%% 三种角度估计的方法

function [angle,doa_abs] = doa(parameter,antVec)

    doaMethod = parameter.doaMethod;
    if doaMethod == 1
        [angle,doa_abs] = dbfMethod(parameter,antVec);
    elseif doaMethod == 2
        [angle,doa_abs] = fftMethod(parameter,antVec);
    elseif doaMethod == 3
        [angle,doa_abs] = caponMethod(parameter,antVec);
    else
    end
end

function [angle,doa_abs] = dbfMethod(parameter,antVec)

    txAntenna = parameter.txAntenna;
    rxAntenna = parameter.rxAntenna;
    virtualAntenna = parameter.virtualAntenna;
    lambda = parameter.lambda;
    txNum = length(txAntenna);
    rxNum = length(rxAntenna);
    dx = parameter.dx;
    deg = -90:0.1:90;
    weightVec = zeros(virtualAntenna,1);
    doa_dbf = zeros(length(deg),1);
    kk = 1;
    for degscan = deg
        for txId = 1:txNum
            for rxId = 1:rxNum
                dphi = ((txId-1) * rxNum + rxId - 1) * 2 * pi / lambda * dx * sind(degscan);
                weightVec((txId-1) * rxNum + rxId) = exp(-1i * dphi);
            end
        end
        doa_dbf(kk) = antVec'*weightVec;
        kk = kk + 1;
    end
    doa_abs = abs(doa_dbf);
    [pk,loc]=max(doa_abs);
    angle = deg(loc);
end

function [angle,doa_abs] = fftMethod(parameter,antVec)
    angleIndex = asin((-512:1:512-1)/512) * 180 / pi;
    doa_fft=fftshift(fft(antVec,1024));
    doa_abs=abs(doa_fft);
    [pk,loc]=max(doa_abs);
    angle = angleIndex(loc);
end

function [angle,doa_abs] = caponMethod(parameter,antVec)

    txAntenna = parameter.txAntenna;
    rxAntenna = parameter.rxAntenna;
    txNum = length(txAntenna);
    rxNum = length(rxAntenna);
    lambda = parameter.lambda;
    dx = parameter.dx;
    virtualAntenna = parameter.virtualAntenna;
    Rx = antVec * antVec' / virtualAntenna; 
    deg = -90:0.1:90;
    a = zeros(virtualAntenna,1);
%     a = zeros(1,virtualAntenna);
    kk = 1;
    for degscan = deg
        for txId = 1:txNum
            for rxId = 1:rxNum
                virtualAntennaId = (txId-1) * rxNum + rxId - 1;
                dphi = 2 * pi / lambda * dx * virtualAntennaId * sind(degscan);
                a((txId-1) * rxNum + rxId) = exp(-1i * dphi);
            end
        end
        RxInv = inv(Rx);
        P_out(kk) = 1/(a'*RxInv*a);
        kk = kk + 1;
    end
    doa_abs = abs(P_out);
    [pk,loc]=max(doa_abs);
    angle = deg(loc);
    figure;
    plot(deg,20*log10(abs(P_out)));
end
