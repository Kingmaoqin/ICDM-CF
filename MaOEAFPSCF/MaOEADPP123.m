classdef MaOEADPP123 < ALGORITHM
% <multi/many> <real/integer> <expensive>
% Adaptive dropout based surrogate-assisted particle swarm optimization
% k    ---   5 --- Number of re-evaluated solutions
% beta --- 0.5 --- Percentage of Dropout
% z: 理想点（Ideal Point）；znad: 非理想点（Nadir Point）
    methods
        function main(Algorithm, Problem)
            theta = Algorithm.ParameterSet(0);
            %% 随机初始化种群 population
            Population = Problem.Initialization();
            CA = Population;
            DA = Population;
            [z,znad]     = deal(min(Population.objs),max(Population.objs));
            nad=znad;

            %% Optimization
            while Algorithm.NotTerminated(CA)
                %t1=clock;
                [ParentC] = MS_123(CA,DA,Problem.N,z,znad); % 得到选择出的父代种群
                %       t1=clock;
                Offspring  = OperatorGA(Problem,ParentC); % 调用遗传算法，得到子代
                %        t2=clock;
                %        e=etime(t2,t1);
                %    fprintf('%d\n',e);
                z = min(z,min(Offspring.objs,[],1));
                [DA]= UpdateDA_123(DA,Offspring,Problem.N,Problem); % 更新diverse种群
                [CA] = UpdateCA_123(CA,Offspring,Problem.N,z,znad,DA.objs,theta,Problem);   % 更新current种群
                znad=max([max(DA.objs, [],1);max(CA.objs,[],1)]);   % 更新非理想点
            end
        end
    end
end