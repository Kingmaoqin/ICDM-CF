clear
rng(42);
folder = 'E:\CF\PlatEMO\PlatEMO\Data\MaOEADPP123';
mat_files = dir(fullfile(folder, '*.mat'));
all_data = struct();
% 初始化一个计数器，用于存储符合条件的文件数据
count = 1;
% 循环遍历所有文件，筛选符合条件的文件保存在all_data 结构体数组中
for i = 1:length(mat_files)
    file_name = mat_files(i).name;
    if startsWith(file_name, 'MaOEADPP123_Adult_CFEGenerator_M3_D108_')
        file_path = fullfile(folder, file_name);
        data = load(file_path);
        % 将数据存入结构体数组中
        all_data(count).name = file_name;  % 文件名
        all_data(count).data = data;  % 文件数据
        count = count + 1;
    end
end
% 加载模型
loadedModel = load('AdultModel.mat');
model = loadedModel.net;
all_results = {};
% 读原始数据
Original_Data = readtable('Adultdata.csv');
Original_Data = normalize(Original_Data, 'range', [0 1]);
%%  循环计算
for s = 1:length(all_data)
    dAta = all_data(s).data;
    predicted_Y = [];
    Data_X = [];
    for i =1: length(dAta.result{1,2})
        Data = dAta.result{1,2}(1,i).dec;
        Data_X(i,:) = Data;
        A = model(Data');
        predicted_Y(i) = A;
    end
    predicted_Y = predicted_Y';
    Original_Data = readtable('Adultdata.csv');
    Original_Data = table2array(Original_Data);
    Original_Data = Original_Data(2:end,2:end);
    Original_X = Original_Data(s,[1:6, 8:end]);
    Original_X = Original_X';
    Original_Y = Original_Data(s,7);
    % 找出需要删除的行索引
    Delete = abs(Original_Y-predicted_Y)<=0.5;
    Data_XKept = Data_X(~Delete, :); % 保留不需要删除的行
    Data_YKept = predicted_Y(~Delete, :);
    continuous_indices = 1:6;
    categorical_indices = setdiff(1:108, continuous_indices); % 假设除了连续特征外的都是分类特征
    data = Original_Data;
    compute_pre_MAD = data(:,[1:6, 8:end]);
    % 计算每个连续变量的MAD
    MAD = zeros(1, length(continuous_indices));
    for i = 1:length(continuous_indices)
        p = continuous_indices(i);
        median_p = median(compute_pre_MAD(:, p));
        MAD(i) = median(abs(compute_pre_MAD(:, p) - median_p));
    end
    % 找到值为0的元素
    zeroIndices = MAD == 0;
    % 给这些元素
    MAD(zeroIndices) = MAD(zeroIndices) + 0.05;
    % 将数据打乱随机顺序
    Data_XKept = Data_XKept(randperm(size(Data_XKept,1)),:);
    % 计算需要遍历的组合数
    num_groups = floor(size(Data_XKept,1)/10);
    % 初始化结果cell数组
    results = cell(num_groups,1);
    % 遍历每一组10个个体
    for i = 1:num_groups
        group_data = Data_XKept((i-1)*10+1:i*10,:);
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
        %% 计算多样性
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
        results{i} = {diversity_cont, diversity_cat, Continuous_Proximity, proximity_cat, Continuous_sparsity, Catgorical_sparsity};
    end
    % 处理最后一组(如果样本数不是10的整数倍)
    if mod(size(Data_XKept,1),10) ~= 0
        last_group_data = Data_XKept(num_groups*10+1:end,:);
        % 存储结果
        results{end+1} = {diversity_cont, diversity_cat, Continuous_Proximity, proximity_cat, Continuous_sparsity, Catgorical_sparsity};
    end
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
    all_results{s} = results;
end
% 辅助函数  计算Sparsity
function sparsity = calculateSparsity(originalInput, counterfactual)
    differences = 0;
    for i = 1:size(counterfactual,1)
        differences = differences + sum(originalInput ~= counterfactual(i,:));
    end
    sparsity = 1 - differences/(size(counterfactual,1)*length(originalInput));
end