%% 请了解：什么是CFAR，以及什么是2D-CFAR

function [pointList,cfarRD] = cfar(parameter,accumulateRD)

    [rangeLen,dopplerLen] = size(accumulateRD);
    %% doppler维度搜索
    dopplerMethod = parameter.dopplerMethod;
    dopplerSNR = parameter.dopplerSNR;
    dopplerWinGuardLen = parameter.dopplerWinGuardLen;
    dopplerWinTrainLen = parameter.dopplerWinTrainLen;

    dopplerLeft = accumulateRD(:,dopplerLen - dopplerWinGuardLen - dopplerWinTrainLen + 1:dopplerLen);
    dopplerRight = accumulateRD(:,1:dopplerWinGuardLen+dopplerWinTrainLen);
    dopplercfar = [dopplerLeft accumulateRD dopplerRight];
    dopplerCfarList = [];
    for rangeIdx = 1:rangeLen
        for dopplerIdx = 1:dopplerLen
            dopplerCfarIdx = dopplerIdx + dopplerWinGuardLen + dopplerWinTrainLen;
            leftCell = dopplercfar(rangeIdx,dopplerIdx:dopplerIdx+dopplerWinTrainLen-1);
            rightCell = dopplercfar(rangeIdx,dopplerCfarIdx+dopplerWinGuardLen:dopplerCfarIdx+dopplerWinGuardLen+dopplerWinTrainLen-1);
            leftNoise = mean(leftCell);
            rightNoise = mean(rightCell);
            noise = (leftNoise + rightNoise) / 2;
            indexdb = dopplercfar(rangeIdx,dopplerCfarIdx);
            targetSnr = indexdb - noise;
            if  targetSnr > dopplerSNR
                dopplerCfarList = [dopplerCfarList dopplerIdx];
                cfarRDdoppler(rangeIdx,dopplerIdx) = indexdb;
            end
        end
    end
    dopplerCfarList = unique(dopplerCfarList);
    %% range维度搜索
    rangeMethod = parameter.rangeMethod;
    rangeSNR = parameter.rangeSNR;
    rangeWinGuardLen = parameter.rangeWinGuardLen;
    rangeWinTrainLen = parameter.rangeWinTrainLen;

    rangeUp = accumulateRD(rangeLen - rangeWinGuardLen - rangeWinTrainLen + 1:rangeLen,:);
    rangeDown = accumulateRD(1:rangeWinGuardLen+rangeWinTrainLen,:);
    rangecfar = [rangeUp;accumulateRD;rangeDown];
    rangeCfarList = [];
    cfarRD = zeros(rangeLen,dopplerLen);
    for dopplerIdx = dopplerCfarList
        for rangeIdx = 1:rangeLen

            rangeCfarIdx = rangeIdx + rangeWinGuardLen + rangeWinTrainLen;
            upCell = rangecfar(rangeIdx:rangeIdx+rangeWinTrainLen-1,dopplerIdx);
            downCell = rangecfar(rangeCfarIdx+rangeWinGuardLen:rangeCfarIdx+rangeWinGuardLen+rangeWinTrainLen-1,dopplerIdx);
            upNoise = mean(upCell);
            downNoise = mean(downCell);
            if rangeMethod == 1
                noise = (upNoise + downNoise) / 2;
                indexdb = rangecfar(rangeCfarIdx,dopplerIdx);
                targetSnr = indexdb - noise;
                if  targetSnr > rangeSNR
                    rangeCfarList = [rangeCfarList [rangeIdx;dopplerIdx]];
                    cfarRD(rangeIdx,dopplerIdx) = indexdb;
                end
            elseif dopplerMethod == 2
            elseif dopplerMethod == 3
            else
            end
        end
    end
    pointList = rangeCfarList;
end
