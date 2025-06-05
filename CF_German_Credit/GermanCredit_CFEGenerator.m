classdef GermanCredit_CFEGenerator < PROBLEM
    % <multi/many> <real> <large/none> <expensive/none>
    properties
        OriginalX = [0.732142857142857	1	0	1	0	0	1	0	1	0	0	0	1	0	0	0.0522174535050072	0.294117647058824	1	0	0	0	0	0	0]';
        TargetY = 0;
        MAD = zeros(1,3);
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            if isempty(obj.M); obj.M = 3; end % 设置目标数量
            if isempty(obj.D); obj.D = 24; end % 设置决策变量的维度
            obj.lower = zeros(100, obj.D); % 决策变量的下界
            obj.upper = ones(100, obj.D); % 决策变量的上界
            obj.encoding = [1	4	4	4	4	4	4	4	4	4	4	4	4	4	4	1	1	4	4	4	4	4	4	4];
        end
        %% Calculate objective values 计算优化目标，每一行对应一个解的三个目标值
        function PopObj = CalObj(obj, PopDec)
            % 加载模型
            loadedModel = load('GermanCreditModel.mat');
            % 提取模型
            net = loadedModel.net;
            % 加载CSV数据
            data = readtable('GermanCreditdata.csv');
            features = data{:, 1:end-1};
            features = normalize(features, 'range', [0 1]);
            % obj.OriginalX = obj.parameter{1,1}(:,1:end-1);
            % obj.OriginalX = obj.OriginalX';
            % obj.TargetY = 1 - obj.parameter{1,1}(:,end);
            continuous_indices = [1, 16, 17];
    
            % 计算每个连续变量的绝对中位差MAD
            for i = 1:length(continuous_indices)
                p = continuous_indices(i);
                median_p = median(features(:, p));
                obj.MAD(i) = median(abs(features(:, p) - median_p));
            end            

            %% 目标1: 最小化输入的修改
            categorical_indices = setdiff(1:obj.D, continuous_indices);% 得到分类变量的index
            % 计算连续变量的距离
            dist_cont = sum(abs(PopDec(:, continuous_indices) - obj.OriginalX(continuous_indices)') ./ obj.MAD, 2);
            % 计算分类变量的距离
            dist_cat = sum(PopDec(:, categorical_indices) ~= obj.OriginalX(categorical_indices)', 2);
            % 计算DiffX
            DiffX = (dist_cont + dist_cat) / obj.D;       
            %% 目标2: 使用铰链损失计算
            logits = net(PopDec');
            z = 2 * obj.TargetY - 1; % 如果TargetY为1, z为1; 如果TargetY为0, z为-1
            DiffY = max(0, 1 - z * logits);
            %% 目标3：L1惩罚
            DiffZ = sum(abs(obj.OriginalX' - PopDec),2);
            %% 综合
            PopObj = [DiffX,DiffY',DiffZ];
        end
         %% Generate points on the Pareto front
         function R = GetOptimum(obj,N)
             % 随机生成初始种群
             PopDec = rand(N, obj.D); % N 个随机解
             PopObj = obj.CalObj(PopDec); % 计算目标值

             % 使用非支配排序提取真实帕累托前沿
             [FrontNo,~] = NDSort(PopObj, N);
             R = PopObj(FrontNo == 1, :); % 返回非支配解
         end
        %% Generate the image of Pareto front
        function R = GetPF(obj)
            if obj.M == 2
                R = obj.GetOptimum(100);
            elseif obj.M == 3
                R = obj.GetOptimum(200);
            else
                R = [];
            end
        end
    end

end