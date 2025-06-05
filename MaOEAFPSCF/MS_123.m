function [ParentC] = MS_123(CA,DA,N,z,znad)
% The mating selection of Two_Arch2
% CA:当前种群 (Current Archive)，包含候选解；DA:新生成的种群 (Diverse Archive)，与 CA 合并形成完整的种群
% N: 选择的父代种群的目标大小；z:理想点（Ideal Point）；znad:非理想点（Nadir Point）
% ParentC: 选择出的父代种群，大小为 2 * N
EA=[CA,DA];
%     ND = NDSort(EA.objs,1);
%     EA = EA(ND==1);
N2=length(CA);
% 目标值的归一化
CAObj=EA.objs;
[N1,M]=size(CAObj);
CAObj2 = (CAObj-repmat(z,N1,1))./(repmat(znad,N1,1)-repmat(z,N1,1));
[~,cc]=max(CAObj2);
% 计算个体之间的相似性
D = pdist2(CAObj2,CAObj2,'cosine');
D=D+eye(N1);
[cos,mincos]=min(D);
% 计算个体的适应性值
CAO=sum(CAObj2.^2,2);
minCAO=CAO(mincos);
ch=(minCAO-CAO)>0;
ch3=(1-ch).*mincos'+(ch).*(1:N1)';
% 归一化最小余弦距离
cos=1-cos;
cos=(cos-min(cos))./repmat((max(cos)-min(cos)),1,N1);
% 父代选择
ParentC=[];
for i=1:1:2*N
    k=randi(N1);
    if rand<cos(k)
        ParentC=[ParentC,EA(ch3(k))];
    else
        ParentC=[ParentC,EA(k)];
    end
end

end