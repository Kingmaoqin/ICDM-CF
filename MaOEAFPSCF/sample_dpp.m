 function Y = sample_dpp(L,k)

 n=size(L.D,1);
[~,i]=sort(L.D);
v=i(n-k+1:n);%？？？？？？？？？？？？？？？
k = length(v);
V = L.V(:,v);

% y=randperm(k);

% iterate
Y = zeros(k,1);
% V=orth(V);
for i = k:-1:1
  
   if size(V,2)==1 && i~=1
      V=abs(V);
      [~,b1]=sort(V);
      bb=b1(n-i+1:n);
      for ii=i:-1:1
          Y(ii)=bb(ii);
      end
      break;
      
  end
  % compute probabilities for each item
  P = sum(V.^2,2);
  P = P / sum(P);
  % choose a new item to include
  %v
%   Y(i) = find(rand <= cumsum(P),1);

  [~,Y(i)] = max(P);

  % choose a vector to eliminate
  j = find(V(Y(i),:),1);%找出第一个不为零的坐标
  Vj = V(:,j);
  V = V(:,[1:j-1 j+1:end]);

  % update V


  V = V - bsxfun(@times,Vj,V(Y(i),:)/Vj(Y(i)));

  % orthogonalize
  V=orth(V);
%  for a = 1:i-1
%    for b = 1:a-1
%      V(:,a) = V(:,a) - V(:,a)'*V(:,b)*V(:,b);
%    end
%    V(:,a) = V(:,a) / norm(V(:,a));
%  end
end

Y = sort(Y);
% Y(Y==0)=[];
end