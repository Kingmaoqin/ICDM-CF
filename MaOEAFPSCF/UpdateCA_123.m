function [CA] = UpdateCA_123(CA, New, MaxSize, z, znad, DAobj, theta, Global)
% Update CA：当前种群

CA = [New, CA];
ND = NDSort(CA.objs, 1);
CA = CA(ND == 1);    %%%%注释-----------------------------------------------
CAObj = CA.objs;
[~, ia, ~] = unique(CAObj, 'rows');
CA = CA(ia);
N = length(CA);
if N <= MaxSize
return;
end
CAObj = CA.objs;
CAObj2 = (CAObj - repmat(z, N, 1)) ./ (repmat(znad, N, 1) - repmat(z, N, 1));
nad = max(DAobj) + 1e-6;
nn = sum((nad - CAObj) < 0, 2);
[N1, M] = size(DAobj);
DAobj = (DAobj - repmat(z, N1, 1)) ./ (repmat(znad, N1, 1) - repmat(z, N1, 1));
big = max(sqrt(sum(DAobj.^2, 2))) + 1e-6;
nbig = sqrt(sum(CAObj2.^2, 2)) > big;
nn = nn + nbig;
% FPS Algorithm starts here
% 计算对余弦距离矩阵
D = pdist2(CAObj2, CAObj2);
D(1:size(D, 1) + 1:end) = 0; % 将对角线元素设为 0
% 初始化
idx = 1;
Choose = idx;
minDist = D(idx, :);
% 迭代，直到我们选择了足够多的点
while length(Choose) < MaxSize
% 查找离当前集合最远的点
[~, idx] = max(minDist);
% 将新索引添加到所选集合中
Choose = [Choose, idx];
% 更新最小距离
distToNewPoint = D(:, idx);
%minDist = min(minDist, distToNewPoint);
minDist = [minDist;distToNewPoint'];
% 取每列的最小值
[minDist, ~] = min(minDist, [], 1);
end
CA = CA(Choose);
end