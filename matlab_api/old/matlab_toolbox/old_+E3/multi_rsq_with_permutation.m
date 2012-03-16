function [realRSq,simRSq,realP,realB]=multi_rsq_with_permutation(y,controlX,testX,nSims)
%[realRSq,simRSq,realP]=multi_rsq_with_permutation(y,controlX,testX)
%Performs a multiple linear regression on y using controlX to determine the
%control variance accounted for. Then the incremental variance accounted
%for and the sign of the slope for each testX is returned in realRSq. For
%each testX a permutation test is performed to get a distribution
%under the null hypothesis that testX is not correlated with y. The realP
%for each testX is calculated using this null distribution. The null
%distribution is also returned in simRSq.

%Correlating the residual of the control regression with testX is NOT the
%same as calculating the VAC BECAUSE the multiple regression method allows
%for interaction of testX with controlX.

controlX=controlX(:,any(controlX~=0));
nTest=size(testX,2);
SStot=sum((y-mean(y)).^2);
%[~,~,r]=regress(y,[ones(size(y)) controlX]);
%Would it be faster to generate the coefficients b = X\y, then generate the
%residuals with r=y-X*b?
X=[ones(size(y)) controlX];
b=X\y;
r=y-X*b;
controlVaf=1-(sum(r.^2)/SStot);
realRSq=NaN(1,nTest);
simRSq=NaN(nSims,nTest);
realP=NaN(1,nTest);
realB=NaN(nTest,1+size(controlX,2)+1);
for vv=1:nTest
    tempX=testX(:,vv);
    [b,~,~,~,stats]=regress(y,[ones(size(y)) controlX tempX]);
    realP(vv)=stats(3);

    %Either use the mathematically straight-forward method
%     X=[ones(size(y)) controlX tempX];
%     b=X\y;
%     r=y-X*b;
%     realRSq(vv)=sign(b(end)).*((1-(sum(r.^2)/SStot))-controlVaf);
%     realB(vv,:)=b;

    %or use the simple built-in method.
    realRSq(vv)=sign(b(end)).*(stats(1)-controlVaf);
    realB(vv,:)=b;
    
    if nSims>0
        %do Monte Carlo
        for ss=1:nSims
            [~,reorder]=sort(rand(length(tempX),1));
            %         [b,~,~,~,stats]=regress(y,[ones(size(y)) controlX tempX(reorder)]);
            %         simRSq(ss,vv)=sign(b(end)).*(stats(1)-controlVac);
            %         [~,~,r]=regress(y,[ones(size(y)) controlX tempX(reorder)]);
            X=[ones(size(y)) controlX tempX(reorder)];
            b=X\y;
            r=y-X*b;
            simRSq(ss,vv)=sign(b(end)).*((1-sum(r.^2)/SStot)-controlVaf);
        end
        
        %Calculate the realP
        NGE=sum(simRSq(:,vv)>=realRSq(vv));
        NLE=sum(simRSq(:,vv)<=realRSq(vv));
        pu=(NGE+1)/(nSims+1);
        pl=(NLE+1)/(nSims+1);
        realP(vv)=min(pu,pl);
    end
    
end