function data_radar=DCA1000_Read_Data(fname)
    global parameter;
    global frame;
    
    %% 读取回波数据
    fid = fopen(fname,'rb');
    %16bits，复数形式(I/Q两路)，4RX,3TX,有符号16bit
    sdata = fread(fid,frame*parameter.Samples*parameter.Chirps*4*3*2,'int16');    
    sdata = sdata((frame-1)*parameter.Samples*parameter.Chirps*4*3*2+1:frame*parameter.Samples*parameter.Chirps*4*3*2);

    %% 1843+DCA1000
    fileSize = size(sdata, 1);
    lvds_data = zeros(1, fileSize/2);
    count = 1;
    for i=1:4:fileSize-5
       lvds_data(1,count) = sdata(i) + 1i*sdata(i+2);
       lvds_data(1,count+1) = sdata(i+1)+1i*sdata(i+3);
       count = count + 2;
    end
    lvds_data = reshape(lvds_data, parameter.Samples*parameter.txNum*parameter.rxNum, parameter.Chirps);
    lvds_data = lvds_data.';
    cdata = zeros(parameter.txNum*parameter.rxNum,parameter.Chirps*parameter.Samples);
    for row = 1:parameter.txNum*parameter.rxNum
      for i = 1: parameter.Chirps
          cdata(row,(i-1)*parameter.Samples+1:i*parameter.Samples) = lvds_data(i,(row-1)*parameter.Samples+1:row*parameter.Samples);
      end
    end
    fclose(fid);
    data_radar_1 = reshape(cdata(1,:),parameter.Samples,parameter.Chirps);   %TX1 RX1
    data_radar_2 = reshape(cdata(2,:),parameter.Samples,parameter.Chirps);   %TX1 RX2
    data_radar_3 = reshape(cdata(3,:),parameter.Samples,parameter.Chirps);   %TX1 RX3
    data_radar_4 = reshape(cdata(4,:),parameter.Samples,parameter.Chirps);   %TX1 RX4
    data_radar_5 = reshape(cdata(5,:),parameter.Samples,parameter.Chirps);   %TX2 RX1
    data_radar_6 = reshape(cdata(6,:),parameter.Samples,parameter.Chirps);   %TX2 RX2
    data_radar_7 = reshape(cdata(7,:),parameter.Samples,parameter.Chirps);   %TX2 RX3
    data_radar_8 = reshape(cdata(8,:),parameter.Samples,parameter.Chirps);   %TX2 RX4
    data_radar_9 = reshape(cdata(9,:),parameter.Samples,parameter.Chirps);   %TX3 RX1
    data_radar_10 = reshape(cdata(10,:),parameter.Samples,parameter.Chirps);   %TX3 RX2
    data_radar_11 = reshape(cdata(11,:),parameter.Samples,parameter.Chirps);   %TX3 RX3
    data_radar_12 = reshape(cdata(12,:),parameter.Samples,parameter.Chirps);   %TX3 RX4
    data_radar=[];            
    data_radar(:,:,1)=data_radar_1; %三维雷达回波数据
    data_radar(:,:,2)=data_radar_2;
    data_radar(:,:,3)=data_radar_3;
    data_radar(:,:,4)=data_radar_4;
    data_radar(:,:,5)=data_radar_5;
    data_radar(:,:,6)=data_radar_6;
    data_radar(:,:,7)=data_radar_7;
    data_radar(:,:,8)=data_radar_8;
    data_radar(:,:,9)=data_radar_9;
    data_radar(:,:,10)=data_radar_10;
    data_radar(:,:,11)=data_radar_11;
    data_radar(:,:,12)=data_radar_12;

end