rng(42);
% 导入数据
data = readtable('Adultdata.csv');
data = table2array(data);
data = data(2:end,2:end);

% 获取数据集的大小
[numRows, numCols] = size(data);
trainRatio = 0.8; 
numTrain = floor(numRows * trainRatio); % 训练集的大小
numTest = numRows - numTrain; % 测试集的大小
idx = randperm(numRows); % 创建随机索引
trainIdx = idx(1:numTrain); % 训练集索引
testIdx = idx(numTrain+1:end); % 测试集索引

Xtrain = data(trainIdx, [1:6, 8:end]); % 训练集输入
Xtest = data(testIdx, [1:6, 8:end]); % 测试集输入
Ytrain = data(trainIdx, 7); % 训练集目标
Ytest = data(testIdx, 7); % 测试集目标

% 创建网络
hiddenLayerSize = 20; % 隐藏层节点数
net = feedforwardnet(hiddenLayerSize); % 创建一个具有20个隐藏层节点的前馈神经网络
% 设置训练参数
net.trainParam.epochs = 1000;   % 迭代次数
net.trainParam.goal = 1e-3;     % MSE 均方误差小于这个值训练结束
net.trainParam.lr = 0.001;       % 学习率
% 训练网络
net = train(net, Xtrain', Ytrain');
% 使用训练集进行预测
Ytrain_pred = net(Xtrain');
% 二值化预测结果（假设二分类问题，且阈值为0.5）
Ytrain_pred_binary = Ytrain_pred >= 0.5;
% 计算训练集的准确率
train_accuracy = sum(Ytrain_pred_binary' == Ytrain) / numTrain;
% 使用测试集进行预测
Ytest_pred = net(Xtest');
% 二值化预测结果
Ytest_pred_binary = Ytest_pred >= 0.5;
% 计算测试集的准确率
test_accuracy = sum(Ytest_pred_binary' == Ytest) / numTest;
% 输出训练集和测试集的预测准确率
fprintf('训练集预测准确率: %.2f%%\n', train_accuracy * 100);
fprintf('测试集预测准确率: %.2f%%\n', test_accuracy * 100);
%%保存模型
% 假设你的模型已经训练完毕，并且保存在变量 net 中
modelFileName = 'AdultModel.mat';
save(modelFileName, 'net');

