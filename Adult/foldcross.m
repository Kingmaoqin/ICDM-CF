rng(42);
% 导入数据
data = readtable('Adultdata.csv');
data = table2array(data);
data = data(2:end, 2:end);  % 跳过第一行（列名）和第一列（标签列）

% 获取数据集的大小
[numRows, numCols] = size(data);
trainRatio = 0.8; 
numTrain = floor(numRows * trainRatio); % 训练集的大小
numTest = numRows - numTrain; % 测试集的大小
idx = randperm(numRows); % 创建随机索引
trainIdx = idx(1:numTrain); % 训练集索引
testIdx = idx(numTrain+1:end); % 测试集索引

% 划分数据
Xtrain_full = data(trainIdx, [1:6, 8:end]); % 完整训练集输入
Ytrain_full = data(trainIdx, 7); % 完整训练集目标
Xtest = data(testIdx, [1:6, 8:end]); % 测试集输入
Ytest = data(testIdx, 7); % 测试集目标

% 设置神经网络参数
hiddenLayerSize = 20; % 隐藏层节点数
epochs = 1000; % 迭代次数
goal = 1e-3; % MSE目标
lr = 0.001; % 学习率

% 初始化五折交叉验证
k = 5;
indices = crossvalind('Kfold', numTrain, k); % 生成交叉验证索引

% 初始化存储准确率的变量
val_accuracies = zeros(k, 1); % 验证集准确率
train_accuracies = zeros(k, 1); % 训练集准确率（每次用不同折训练后的模型）
    net = feedforwardnet(hiddenLayerSize);
for fold = 1:k
    fprintf('正在进行第 %d 折交叉验证...\n', fold);
    
    % 划分训练集和验证集（仅在原始训练集内部）
    valIdx = (indices == fold);
    trIdx = ~valIdx;
    
    Xtr = Xtrain_full(trIdx, :); % 本折训练集
    Xval = Xtrain_full(valIdx, :); % 本折验证集
    Ytr = Ytrain_full(trIdx, :); 
    Yval = Ytrain_full(valIdx, :);
    
    % 设置训练参数
    net.trainParam.epochs = epochs;
    net.trainParam.goal = goal;
    net.trainParam.lr = lr;
    
    % 训练网络
    net = train(net, Xtr', Ytr');
    
    % 使用训练集进行预测
    Ytrain_pred = net(Xtr');
    Ytrain_pred_binary = Ytrain_pred >= 0.5;
    train_accuracy = sum(Ytrain_pred_binary' == Ytr) / sum(trIdx);
    train_accuracies(fold) = train_accuracy;
    
    % 使用验证集进行预测
    Yval_pred = net(Xval');
    Yval_pred_binary = Yval_pred >= 0.5;
    val_accuracy = sum(Yval_pred_binary' == Yval) / sum(valIdx);
    val_accuracies(fold) = val_accuracy;
    
    fprintf('第 %d 折 - 训练集准确率: %.2f%%, 验证集准确率: %.2f%%\n', ...
            fold, train_accuracy * 100, val_accuracy * 100);
end

% 输出交叉验证结果
fprintf('\n交叉验证结果:\n');
fprintf('训练集平均准确率: %.2f%% ± %.2f%%\n', mean(train_accuracies) * 100, std(train_accuracies) * 100);
fprintf('验证集平均准确率: %.2f%% ± %.2f%%\n', mean(val_accuracies) * 100, std(val_accuracies) * 100);

% 在所有训练数据上训练最终网络
finalNet = feedforwardnet(hiddenLayerSize);

% 设置最终网络训练参数
finalNet.trainParam.epochs = epochs;
finalNet.trainParam.goal = goal;
finalNet.trainParam.lr = lr;

% 在所有训练数据上训练最终网络
finalNet = train(finalNet, Xtrain_full', Ytrain_full');

% 使用最终模型在测试集上进行预测
Ytest_pred_final = finalNet(Xtest');
Ytest_pred_binary_final = Ytest_pred_final >= 0.5;
test_accuracy_final = sum(Ytest_pred_binary_final' == Ytest) / numTest;

% 输出最终模型的测试集准确率
fprintf('\n最终模型在测试集上的准确率: %.2f%%\n', test_accuracy_final * 100);

%% 保存最终模型
modelFileName = 'AdultModel.mat';  % 设置保存文件名
save(modelFileName, 'finalNet');   % 保存训练好的模型
