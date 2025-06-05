%% 调用代码计算种群
clear;
close;
% 读取.csv中数据
data = readtable('GermanCreditdata.csv');
data = data{:, 1:end};
numColumns = 100;
tic;
for i = 1:numColumns 
    parameter = data(i,:); 
    platemo('problem',{@GermanCredit_CFEGenerator,parameter},'algorithm',@MaOEADPP123,'save',1)
end
elapsedTime = toc; % 记录结束时间并计算运行时间
disp(['循环运行时间: ', num2str(elapsedTime), ' 秒']);


% folderPath = 'E:\CF\PlatEMO\PlatEMO\Data\CFFPS\';
% filePrefix = 'CFFPS_GermanCredit_CFEGenerator_M3_D24_';
% fileSuffix = '.mat';
% totalRuntime = 0;
% for i = 108:207
%     filePath = [folderPath, filePrefix, num2str(i), fileSuffix];
%     data = load(filePath);
%     runtime = data.metric.runtime;
%     totalRuntime = totalRuntime + runtime;
% end
% disp(['运行总时间为: ', num2str(totalRuntime),' 秒']);