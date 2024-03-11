%% 生成CFAR所需的参数

function parameter = generateCfarParameter()

    parameter.dopplerMethod = 1; %1：ca-cfar 2：so-cfar 3：go-cfar
    parameter.dopplerSNR = 10;
    parameter.dopplerWinGuardLen = 2;
    parameter.dopplerWinTrainLen = 8;

    parameter.rangeMethod = 1; %1：ca-cfar 2：so-cfar 3：go-cfar
    parameter.rangeSNR = 10;
    parameter.rangeWinGuardLen = 2;
    parameter.rangeWinTrainLen = 4;
end
