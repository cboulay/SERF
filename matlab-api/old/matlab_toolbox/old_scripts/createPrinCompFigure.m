function createPrinCompFigure(memFreqs,prinComps)
n_freqs=length(memFreqs);
n_anis=size(prinComps,3);

%shift the input prinComps so that components 1:3 represent same/similar
%things.
% for aa=1:n_anis
%     plot(memFreqs,prinComps(:,:,aa))
%     title(num2str(aa));
%     w=waitforbuttonpress;
% end
component_shift=[-1 2 -3; -1 3 -2; -1 2 4; -1 2 -4; -1 2 -4; -1 2 -5; -1 2 -4; -1 2 -3; -1 2 -3; -1 2 -3;...
    -1 2 -3; -1 2 -3; -1 2 -4; -1 3 -4; -1 3 -4; -1 2 -4; -1 3 -4; -1 3 -4; -1 3 -4; -1 2 5;...
    -1 2 -4; -1 2 3; -1 2 -3; -1 2 -4; -1 2 -4; -1 2 -3; -1 2 -3; -1 2 -4; -1 2 -4; -1 3 -4;...
    -1 -3 -2; -1 2 -3; -1 2 -4; -1 2 -3; -1 2 -3; -1 2 -4; -1 3 -2; -1 2 -3; -1 2 -3; -1 2 -4; -1 2 -5];
temp=NaN(n_freqs,3,n_anis);
for aa=1:n_anis
    for pc=1:3
        temp(:,pc,aa)=prinComps(:,abs(component_shift(aa,pc)),aa).*sign(component_shift(aa,pc));
    end
end
prinComps=temp;
prinComps=permute(prinComps,[3 1 2]);

climits=[min(min(min(prinComps(:,2:end,1:3)))) max(max(max(prinComps(:,2:end,1:3))))];

%climits=[-1*max(max(max(prinComps))) max(max(max(prinComps)))];
% Create figure
figure1 = figure;
diffFreqs=memFreqs(2)-memFreqs(1);
xlims=[memFreqs(1)-diffFreqs/2 memFreqs(end)+diffFreqs/2];
ylims=[0.5 n_anis+0.5];
% Create subplot
subplot1 = subplot(3,1,1,'Parent',figure1,'YTick',zeros(1,0),...
    'YDir','reverse',...
    'XTick',zeros(1,0),...
    'LineWidth',3,...
    'Layer','top',...
    'CLim',climits,...
    'Position',[0 0.6666 1 0.3333]);
box(subplot1,'on');
hold(subplot1,'all');
% Create image
image(memFreqs,1:size(prinComps,1),prinComps(:,:,1),'Parent',subplot1,'CDataMapping','scaled');
xlim(xlims)
ylim(ylims)
%caxis(climits)

% Create subplot
subplot2 = subplot(3,1,2,'Parent',figure1,'YTick',zeros(1,0),...
    'YDir','reverse',...
    'XTick',zeros(1,0),...
    'LineWidth',3,...
    'Layer','top',...
    'CLim',climits,...
    'Position',[0 0.3333 1 0.3333]);
box(subplot2,'on');
hold(subplot2,'all');
% Create image
image(memFreqs,1:size(prinComps,1),prinComps(:,:,2),'Parent',subplot2,'CDataMapping','scaled');
xlim(xlims)
ylim(ylims)
%caxis(climits)

% Create subplot
subplot3 = subplot(3,1,3,'Parent',figure1,'YTick',zeros(1,0),...
    'YDir','reverse',...
    'XTick',zeros(1,0),...
    'LineWidth',3,...
    'Layer','top',...
    'CLim',climits,...
    'Position',[0 0 1 0.3333]);
box(subplot3,'on');
hold(subplot3,'all');
% Create image
image(memFreqs,1:size(prinComps,1),prinComps(:,:,3),'Parent',subplot3,'CDataMapping','scaled');
xlim(xlims)
ylim(ylims)
%caxis(climits)