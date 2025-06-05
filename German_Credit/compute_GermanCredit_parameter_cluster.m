%% 计算GermanCredit数据集的各种指标
clear
rng(42);
% 读取遗传算法+FPS的计算结果（.mat文件）
filePath = 'E:\CF\PlatEMO\PlatEMO\Data\MaOEADPP123/MaOEADPP123_GermanCredit_CFEGenerator_M3_D24_3.mat';
dAta = load(filePath);
% 加载模型
loadedModel = load('GermanCreditModel.mat');
% 提取模型
model = loadedModel.net;

predicted_Y = [];
Data_X = [];
for i =1:100
    Data = dAta.result{1,2}(1,i).dec;
    Data_X(i,:) = Data;
    A = model(Data');
    predicted_Y(i) = A;
end
predicted_Y = predicted_Y';
Original_Data = readtable('GermanCreditdata.csv');    % GermanCredit数据集
Original_Data = normalize(Original_Data, 'range', [0 1]);
Original_X = table2array(Original_Data(1,1:end-1));  % 读第1行的原始数据
Original_X = Original_X';
Original_Y = Original_Data(:,end).Risk(1);
% 找出需要删除的行索引
Delete = abs(Original_Y-predicted_Y)<=0.5;
Data_XKept = Data_X(~Delete, :); % 保留不需要删除的行
Data_YKept = predicted_Y(~Delete, :);
continuous_indices = [1,16,17];
categorical_indices = setdiff(1:24, continuous_indices); % 假设除了连续特征外的都是分类特征

data = Original_Data;
compute_pre_MAD = table2array(removevars(data, 'Risk'));

% 计算每个连续变量的MAD
MAD = zeros(1, length(continuous_indices));
for i = 1:length(continuous_indices)
    p = continuous_indices(i);
    median_p = median(compute_pre_MAD(:, p));
    MAD(i) = median(abs(compute_pre_MAD(:, p) - median_p));
end

% 将数据打乱随机顺序
Data_XKept = Data_XKept(randperm(size(Data_XKept,1)),:);

% 初始化结果cell数组
results = cell(1,1);

% 生成 10 个聚类
numClusters = 10;
[clusterIdx, clusterCenters] = kmeans(Data_XKept, numClusters);

% 初始化一个空的矩阵来存储每个聚类的样本
group_data = zeros(numClusters, size(Data_XKept, 2));

% 对于每一个聚类
for i = 1:numClusters
    % 获取当前聚类的所有样本
    clusterSamples = Data_XKept(clusterIdx == i, :);
    
    % 从当前聚类的样本中选择一个样本（例如，选择第一个样本）
    if ~isempty(clusterSamples)
        group_data(i, :) = clusterSamples(1, :);
    end
end


% 初始化多样性的总和
sum_of_differences_cont = 0;
sum_of_differences_cat = 0;

% 计算连续特征的多样性diversity_continuous
valid_values = num2cell(group_data, 2);
for m = 1:length(valid_values)-1
    for j = m+1:length(valid_values)
        cont_diff = abs(valid_values{m}(:,continuous_indices) - valid_values{j}(:,continuous_indices)) ./ MAD;
        sum_of_differences_cont = sum_of_differences_cont + sum(cont_diff);
    end
end

% 计算分类特征的多样性diversity_categorical
for m = 1:length(valid_values)-1
    for j = m+1:length(valid_values)
        cat_diff = valid_values{m}(:,categorical_indices) ~= valid_values{j}(:,categorical_indices);
        sum_of_differences_cat = sum_of_differences_cat + sum(cat_diff);
    end
end

% 计算多样性
Ck_2 = length(valid_values) * (length(valid_values) - 1) / 2;
diversity_cont = sum_of_differences_cont / Ck_2 /length(continuous_indices);
diversity_cat = sum_of_differences_cat / Ck_2 / length(categorical_indices);

% 计算接近度和稀疏性
k = size(group_data,1);
features = group_data;

%% 计算连续接近度 (Continuous-Proximity)
proximity_cont = 0;
for j = 1:length(continuous_indices)
    p = continuous_indices(j);
    distances = abs(features(:, p) - Original_X(p)) ./ MAD(j);
    % distances = abs(features(:, p) - Original_X(p));
    proximity_cont = proximity_cont + distances;
end
dist_cont = proximity_cont / length(continuous_indices);
Continuous_Proximity = -1/k * sum(dist_cont);


%% 计算分类接近度 (Categorical-Proximity)
dist_cat = 0;
for j = 1:length(categorical_indices)
    p = categorical_indices(j);
    differences = features(:, p)' ~= Original_X(p);
    dist_cat = dist_cat + differences;
end
dist_cat = dist_cat/length(categorical_indices);
proximity_cat = 1 - sum(dist_cat) / k;

%% 计算Catgorical-sparsity
catgorical_x = Original_X(categorical_indices);
catgorical_c = features(:,categorical_indices);
Catgorical_sparsity = calculateSparsity(catgorical_x',catgorical_c);
%% 计算Continuous-sparsity
continuous_x = Original_X(continuous_indices);
continuous_c = features(:,continuous_indices);
Continuous_sparsity = calculateSparsity(continuous_x',continuous_c);
% 存储结果
results{1} = {diversity_cont, diversity_cat, Continuous_Proximity, proximity_cat, Continuous_sparsity, Catgorical_sparsity};


first_column_elements = cellfun(@(c)c{1}(1), results, 'UniformOutput', false);
[sorted_values, sort_indices] = sort(cell2mat(first_column_elements), 'descend');
sorted_results = results(sort_indices);
%%  打印结果
fprintf('Continuous-Diversity, Categorical-Diversity, Continuous-Proximity, Categorical-Proximity, Continuous_sparsity, Catgorical-sparsity')
fprintf('\n');
for i = 1:size(sorted_results, 1)
    current_cell_content = sorted_results{i};
    fprintf('Cell %d: ', i);
    fprintf('%f ', current_cell_content{:});
    fprintf('\n');
end


% 辅助函数  计算Sparsity
function sparsity = calculateSparsity(originalInput, counterfactual)
    differences = 0;
    for i = 1:size(counterfactual,1)
        differences = differences + sum(originalInput ~= counterfactual(i,:));
    end
    sparsity = 1 - differences/(size(counterfactual,1)*length(originalInput));
end
