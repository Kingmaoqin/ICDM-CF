function [DA]= UpdateDA_123(DA,New,MaxSize,Global)
% Update DA：更新diverse种群
%% Find the non-dominated solutions

DA = [New,DA];
CAObj=DA.objs;

[N,M] = size(CAObj);

if N <= MaxSize
    return;
end

cunum=ceil((MaxSize)/(3*M));
CAObj2 = CAObj;
CAObj3=CAObj2.^2;
CAO=sum(CAObj3,2);
CHIndex = [];
minIndex2=[];
for i=1:M
    minfx=CAObj(:,i);
    tempminfx=min(minfx)+1E-6;

    if sum(minfx<tempminfx)>cunum
        mindex=find((minfx<tempminfx));
        [~,minIndex]=sort(CAO(mindex));
        minIndex=mindex(minIndex(1:cunum));
    else
        [~,minIndex]=sort(minfx);
        minIndex=minIndex(1:cunum);
    end

    minfx2=CAO-CAObj3(:,i);
    tempminfx=min(minfx2)+1E-6;


    if sum(minfx2<tempminfx)>2*cunum
        mindex=find((minfx2<tempminfx));
        [~,minndex]=sort(CAO(mindex));
        index=mindex(minndex(1:2*cunum));
    else
        [~,index]=sort(minfx2);
        index=index(1:2*cunum);
    end

    CHIndex = [CHIndex,index'];

    minIndex2=[minIndex2,minIndex'];
end

Choose=[CHIndex,minIndex2];
DA=DA(Choose);
%if mod(Global.gen,9)==0
%fprintf('%d \n',Global.gen);
%    fprintf('%d \n',size(DA));
%end

end