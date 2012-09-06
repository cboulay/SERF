classdef Linearize < handle
    methods (Static = true)
        function [X_sin,coeffs]=sinusoidal(X,Y)
            %function [X_sin,coeffs]=sinusoidal(X,Y)
            %This function takes inputs X and Y where Y varies as a
            %sinusoidal function of X, then returns X_sin which is a
            %transformed version of X such X_sin varies sinusoidally with X
            %and Y varies linearly with X_sin
            %Also returns coeffs, where coeffs(1) is the amplitude and coeffs(2) is the
            %phase-offset of the sinusoid from -pi to pi.
            fX = @(b,x) b(1).*cos(x-b(2))+b(3); %Declare the function.
            [coeffs,~,~,covb]=nlinfit(X,Y,fX,[1 0 100]); %Fit the data to the function.
            if any(any(isinf(covb))) %If the data don't fit the function
                X_sin=zeros(size(Y));
            else
                %Bring the phase offset to within [0 pi]
                coeffs(2)=mod(coeffs(2),2*pi);
                if coeffs(1)<0
                    if coeffs(2)>=pi
                        coeffs(2)=coeffs(2)-pi;
                    else
                        coeffs(2)=coeffs(2)+pi;
                    end
                    coeffs(1)=abs(coeffs(1));
                end
                X_sin=fX([0.5 coeffs(2) 0.5],X); %Set X_sin to between 0 and 1
            end
        end
        
        function [X_piece,pp]=piecewise(X,Y)
            %function [X_piece,pp]=piecewise(X,Y)
            %This function takes inputs X and Y where Y varies as a
            %non-linear function of X, then returns X_piece which is a
            %transformed version of X such that X_piece is a piecewise
            %polynomion of X and Y varies linearly with X_piece
            %Also returns pp, where pp is the piecewise polynomial object.
            %X_piece is scaled between 0 and 1.
            nTrials=length(X);
            
            %Remove upper and lower 5%
            [sortX,I]=sort(X);
            sortY=Y(I);
            sortY=smooth(sortY,floor(nTrials/10),'moving');
            sortX=sortX(floor(nTrials/20):end-floor(nTrials/20));
            sortY=sortY(floor(nTrials/20):end-floor(nTrials/20));
            
            %Only one Y per each X
            uniqueX=unique(sortX);
            nXs=length(uniqueX);
            uniqueY=NaN(nXs,1);
            uniqueTrials=NaN(nXs,1);
            for nn=1:nXs
                these=sortX==uniqueX(nn);
                uniqueY(nn)=mean(sortY(these));
                uniqueTrials(nn)=sum(these); %Number of trials at this X
            end
            
            %Only keep X/Y pairs where there were at least 10 trials.
            uniqueX=uniqueX(uniqueTrials>=10);
            uniqueY=uniqueY(uniqueTrials>=10);
            
            X_pieceRange=[min(uniqueY) max(uniqueY)];
            if length(uniqueX)>2
                pp=pchip(uniqueX,uniqueY);
                X_piece=ppval(pp,X);
                %The tails of the estimate can extrapolate wildly, so set
                %the lower tail and the upper tail to the smallest and
                %largest real observed value.
                X_piece(X<uniqueX(1))=uniqueY(1);
                X_piece(X_piece<X_pieceRange(1))=X_pieceRange(1);
                X_piece(X_piece>X_pieceRange(2))=X_pieceRange(2);
                %Scale between 0 and 1
                X_piece=X_piece-min(X_piece);
                X_piece=X_piece./max(X_piece);
            else
                X_piece=repmat(mean(uniqueY),nTrials,1);
                pp=NaN;
            end
        end
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
        end
        function [YX,bX]=sigmoidal(X,Y)
            %function [YX,bX]=sigmoidal(X,Y)
            %This function takes inputs X and Y where Y varies sigmoidally
            %with X, and returns YX which is an estimate of Y at each
            %provided X and bX which are the parameters of the sigmoid
            %estimated by a nonlinear fit of X and Y.
            %bX in order is [Rmax S50 K];
            %fX = @(b,s) b(1) ./ (1 + exp((b(2)-s)/b(3)));
            fX = @(b,s) b(1) ./ (1 + exp((b(2)-s)/b(3)));
            [X,I]=sort(X);
            Y=Y(I);
            [bX,~,~,covb]=nlinfit(X,Y,fX,[max(Y) 100 10]);
            %What if, for a given subject, the data don't fit this model?
            if any(any(isinf(covb)))
                YX=zeros(size(Y));
            else
                YX=fX(bX,X);
            end
        end
        
    end
end