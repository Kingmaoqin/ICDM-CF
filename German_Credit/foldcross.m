rng(42);
% 导入数据
data = readtable('GermanCreditdata.csv');
data = table2array(data);

% 获取数据集的大小
[numRows, numCols] = size(data);
trainRatio = 0.8; 
numTrain = floor(numRows * trainRatio); % 训练集的大小
numTest = numRows - numTrain; % 测试集的大小
idx = randperm(numRows); % 创建随机索引
trainIdx = idx(1:numTrain); % 训练集索引
testIdx = idx(numTrain+1:end); % 测试集索引

Xtrain = data(trainIdx, 1:end-1); % 训练集输入
Xtest = data(testIdx, 1:end-1); % 测试集输入
Ytrain = data(trainIdx, end); % 训练集目标
Ytest = data(testIdx, end); % 测试集目标

% 设置5折交叉验证
k = 5;
cv = cvpartition(length(Ytrain), 'KFold', k);

% 初始化存储准确率的变量
val_accuracies = zeros(k, 1);
test_accuracies = zeros(k, 1);

% 创建网络配置
hiddenLayerSize = 20; % 隐藏层节点数
net = feedforwardnet(hiddenLayerSize);
for i = 1:k
    fprintf('Processing fold %d of %d...\n', i, k);
    
    % 获取当前fold的训练和验证索引
    trainIdxCV = cv.training(i);
    valIdxCV = cv.test(i);
    
    % 获取当前fold的数据
    XtrainCV = Xtrain(trainIdxCV, :);
    YtrainCV = Ytrain(trainIdxCV, :);
    XvalCV = Xtrain(valIdxCV, :);
    YvalCV = Ytrain(valIdxCV, :);

    
    % 设置训练参数
    net.trainParam.epochs = 1000;
    net.trainParam.goal = 1e-3;
    net.trainParam.lr = 0.001;
    net.trainParam.showWindow = false; % 不显示训练窗口
    
    % 训练网络
    net = train(net, XtrainCV', YtrainCV');
    
    % 验证集预测
    Yval_pred = net(XvalCV');
    Yval_pred_binary = Yval_pred >= 0.5;
    val_accuracy = sum(Yval_pred_binary' == YvalCV) / length(YvalCV);
    val_accuracies(i) = val_accuracy;
    
    % 测试集预测（在整个测试集上）
    Ytest_pred = net(Xtest');
    Ytest_pred_binary = Ytest_pred >= 0.5;
    test_accuracy = sum(Ytest_pred_binary' == Ytest) / numTest;
    test_accuracies(i) = test_accuracy;
end

% 计算平均准确率和标准差
mean_val_accuracy = mean(val_accuracies);
std_val_accuracy = std(val_accuracies);
mean_test_accuracy = mean(test_accuracies);
std_test_accuracy = std(test_accuracies);

% 输出结果
fprintf('\n交叉验证结果:\n');
fprintf('平均验证集准确率: %.2f%% ± %.2f%%\n', mean_val_accuracy * 100, std_val_accuracy * 100);
fprintf('平均测试集准确率: %.2f%% ± %.2f%%\n', mean_test_accuracy * 100, std_test_accuracy * 100);

% 训练最终模型（在所有训练数据上）
fprintf('\n训练最终模型在所有训练数据上...\n');
final_net = feedforwardnet(hiddenLayerSize);
final_net.trainParam.epochs = 1000;
final_net.trainParam.goal = 1e-3;
final_net.trainParam.lr = 0.001;
final_net = train(final_net, Xtrain', Ytrain');

% 在测试集上评估最终模型
Ytest_pred_final = final_net(Xtest');
Ytest_pred_binary_final = Ytest_pred_final >= 0.5;
final_test_accuracy = sum(Ytest_pred_binary_final' == Ytest) / numTest;

fprintf('最终模型测试集准确率: %.2f%%\n', final_test_accuracy * 100);

% 保存模型
modelFileName = 'GermanCreditModel.mat';
save(modelFileName, 'final_net');