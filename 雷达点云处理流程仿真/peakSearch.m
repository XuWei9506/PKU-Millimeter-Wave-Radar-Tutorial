%% 寻找峰值

function [RD_pearkSearch,peakSearchList] = peakSearch(RD_cfar,cfarTargetList)

    peakSearchList = [];
    [rangeLen, dopplerLen] = size(RD_cfar);
    RD_pearkSearch = zeros(rangeLen, dopplerLen);
    length = size(cfarTargetList,2);

    for targetIdx = 1:length

        rangeIdx   = cfarTargetList(1,targetIdx); 
        dopplerIdx = cfarTargetList(2,targetIdx); %坐标

        if rangeIdx > 1 && rangeIdx < rangeLen && dopplerIdx > 1 && dopplerIdx < dopplerLen %边界点不考虑  
           
            if RD_cfar(rangeIdx,dopplerIdx) > RD_cfar(rangeIdx - 1,dopplerIdx) && ...
                    RD_cfar(rangeIdx,dopplerIdx) > RD_cfar(rangeIdx + 1,dopplerIdx) && ...
                    RD_cfar(rangeIdx,dopplerIdx) > RD_cfar(rangeIdx,dopplerIdx - 1) && ...
                    RD_cfar(rangeIdx,dopplerIdx) > RD_cfar(rangeIdx,dopplerIdx + 1)

                    RD_pearkSearch(rangeIdx,dopplerIdx) = RD_cfar(rangeIdx,dopplerIdx);

                    cfarTarget = [rangeIdx ; dopplerIdx];

                    peakSearchList = [peakSearchList cfarTarget];
            end   
        end
    end  
end
