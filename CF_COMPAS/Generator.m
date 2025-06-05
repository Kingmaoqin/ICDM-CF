%% 调用代码计算种群
clear;
close;
% 读取.csv中数据
data = readtable('COMPASdata.csv');
data = data(2:end,:);
numColumns = 100;
for i = 1:numColumns 
    parameter = data(i,:); 
    platemo('problem',{@COMPAS_CFEGenerator,parameter},'algorithm',@MaOEADPP123,'save',1)
end

% 
% folderPath = 'E:\CF\PlatEMO\PlatEMO\Data\compas\';
% filePrefix = 'MaOEADPP123_COMPAS_CFEGenerator_M3_D11_';
% fileSuffix = '.mat';
% totalRuntime = 0;
% for i = 2:101
%     filePath = [folderPath, filePrefix, num2str(i), fileSuffix];
%     data = load(filePath);
%     runtime = data.metric.runtime;
%     totalRuntime = totalRuntime + runtime;
% end
% disp(['运行总时间为: ', num2str(totalRuntime),' 秒']);