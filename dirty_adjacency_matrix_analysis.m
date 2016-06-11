% clear
% close all
% load('Z:\Data\adjacency.mat')
% lnSkids(23) = [];
% lnNames(23) = [];
% allSkids = [lnSkids; pnSkids; leftORNSkids; rightORNSkids];
% allNames = [lnNames; pnNames; leftORNNames; rightORNNames];
% 
% for i = 1:length(lnNames)
% simpleNames{i} = allNames{i};
% simpleNames{i}(end-3:end) = [];
% simpleNames{i} = simpleNames{i}(4:end);
% end
% simpleNames{35} = 'PN'; simpleNames{36} = 'LORN'; simpleNames{37} = 'RORN'; 
% simpleNames{38} = 'other';
% simpleNames{12} = '25a';
% simpleNames{13} = '25b';
% simpleNames{23} = '43b';
% exp_title = 'Combined-pca-normalized';
%%
clear
% close all
load('Z:\Data\adjacency.mat')
lnSkids(23:24) = [];
lnNames(23:24) = [];
allSkids = [lnSkids; pnSkids; leftORNSkids; rightORNSkids];
allNames = [lnNames; pnNames; leftORNNames; rightORNNames];
nLNs = length(lnNames);

for i = 1:length(lnNames)
simpleNames{i} = allNames{i};
simpleNames{i}(end-3:end) = [];
simpleNames{i} = simpleNames{i}(4:end);
end
simpleNames{nLNs+1} = 'PN'; simpleNames{nLNs+2} = 'LORN'; simpleNames{nLNs+3} = 'RORN'; 
simpleNames{nLNs+4} = 'other';
simpleNames{12} = '25a';
simpleNames{13} = '25b';
% simpleNames{23} = '43b';
exp_title = 'Combined-pca-normalized';
%%
skid_to_i = [];
for i = 1:length(allSkids)
    skid_to_i(i) = find(sk_ids == allSkids(i));
    totalInputs(i) = sum(matrix(:,skid_to_i(i)));
    totalOutputs(i) = sum(matrix(skid_to_i(i),:));
end
compressedMat = matrix(skid_to_i, skid_to_i);
compressedMat = double(compressedMat);

% Do this if you want to combine multi-fragment DM6 portions
compressedMat(12,:) = sum(compressedMat(12:13,:));
compressedMat(:,12) = sum(compressedMat(:,12:13),2);
compressedMat(13,:) = []; compressedMat(:,13) = [];
totalInputs(12) = sum(totalInputs(12:13)); totalInputs(13) = [];
totalOutputs(12) = sum(totalInputs(12:13)); totalOutputs(13) = [];
simpleNames{12} = '25'; simpleNames(13) = [];
lnSkids(13) = []; lnNames(13) = [];
nLNs = nLNs-1;

compressedMat(nLNs+1,:) = sum(compressedMat((1:2:5)+nLNs, :),1);
compressedMat(:,nLNs+1) = sum(compressedMat(:,(1:2:5)+nLNs),2);
totalInputs(nLNs+1) = sum(totalInputs((1:2:5)+nLNs));
totalOutputs(nLNs+1) = sum(totalOutputs((1:2:5)+nLNs));

compressedMat(nLNs+2,:) = sum(compressedMat((6:32)+nLNs, :),1);
compressedMat(:,nLNs+2) = sum(compressedMat(:,(6:32)+nLNs),2);
totalInputs(nLNs+2) = sum(totalInputs((6:32)+nLNs));
totalOutputs(nLNs+2) = sum(totalOutputs((6:32)+nLNs));

compressedMat(nLNs+3,:) = sum(compressedMat((33+nLNs):end, :),1);
compressedMat(:,nLNs+3) = sum(compressedMat(:,(33+nLNs):end),2);
totalInputs(nLNs+3) = sum(totalInputs((33+nLNs):end));
totalOutputs(nLNs+3) = sum(totalOutputs((33+nLNs):end));

compressedMat(nLNs+4:end,:) = [];
compressedMat(:, nLNs+4:end) = [];
totalInputs(nLNs+4:end) = [];
totalOutputs(nLNs+4:end) = [];
otherInputs = totalInputs - sum(compressedMat,1);
otherOutputs = totalOutputs' - sum(compressedMat,2);
%% Tack on total synapse numbers
% otherInputs(38) = 0;
% compressedMat(:,38) = otherOutputs;
% compressedMat(38,:) = otherInputs;
adjMat = compressedMat;
%% Normalize within outputs
% Values of matrix are the fraction of output contacts dedicated to a given
% post-synaptic partner.
onMat = compressedMat;
for i = 1:size(onMat,1)
    onMat(i,:) = onMat(i,:) ./ sum(onMat(i,:));
end

%% Normalize within inputs
% Values of matrix are the fraction of input contacts received from a given
% pre-synaptic partner.
inMat = compressedMat;
for i = 1:size(compressedMat,1)
    inMat(:, i) = inMat(:, i) ./ sum(inMat(:, i));
end

%%
figure
imagesc(inMat(:,orderOn), [0 0.7])  
ax = gca;
ax.XTick = 1:size(compressedMat,2); ax.YTick = 1:size(compressedMat,1);
ax.XTickLabel = simpleNames; ax.YTickLabel = simpleNames;
%% output pca 
co = onMat';
% co = compressedMat';
co(:,end-2:end) = [];
% [u,s,v] = svd(co);
% s = diag(s);
% projPc = co' * u;


% figure
% subplot(2,2,1); plot(u(:,1)); title('pc1')
% subplot(2,2,2); plot(u(:,2)); title('pc2')
% subplot(2,2,3); plot(diag(s)./sum(s(:)), '*'); title('scree') 
% subplot(2,2,4); plot(projPc1, projPc2, '*')
%% Input pca 
ci = inMat;
% ci = compressedMat;
ci(:,end-2:end) = [];
% [u,s,v] = svd(ci);
% s = diag(s);
% projPc = ci' * u;

% figure
% subplot(2,2,1); plot(u(:,1)); title('pc1')
% subplot(2,2,2); plot(u(:,2)); title('pc2')
% subplot(2,2,3); plot(diag(s)./sum(s(:)), '*'); title('scree') 
% subplot(2,2,4); plot(projPc1, projPc2, '*')
%% Combined pca
c = [ci;co];
[u,s,v] = svd(c);
s = diag(s);
projPc = c' * u;
%% 
subplot = @(m,n,p) subtightplot (m, n, p, [0.02 0.01], [0.02 0.02], [0.02 0.02]);
c = ci;
figure
plot(s./sum(s), '*'); title(exp_title) 
savefig(['Z:\Data\DM6_LN_analysis\' exp_title '_scree.fig'])
figure
for i = 1:4
    subplot(2,4,i);
    plot(u(:,i))
    ax = gca;
    ax.XTick = 1:(2*size(simpleNames,2));
    ax.XTickLabel = [simpleNames, simpleNames]; 
end
for i = 5:8
    subplot(2,4,i);
    plot(projPc(:,i-4), '*')
    ax = gca;
    ax.XTick = 1:size(simpleNames,2);
    ax.XTickLabel = simpleNames; 
end
subplot(2,4,1); title(exp_title)
savefig(['Z:\Data\DM6_LN_analysis\' exp_title '_PCs.fig'])
%% Correlation with total synapse number
corrTypes = [{'totalOutput'}, {'totalInput'}, {'knownOutput'}, {'knownInput'}, {'otherOutput'}, {'otherInput'}];
correlations = zeros(4,length(corrTypes));
for i = 1:4
    correlations(i,1) = corr(projPc(:,i), totalOutputs(1:nLNs)');
    correlations(i,2) = corr(projPc(:,i), totalInputs(1:nLNs)');
end
for i = 1:4
    correlations(i,3) = corr(projPc(:,i), sum(compressedMat(1:nLNs, 1:nLNs), 2));
    correlations(i,4) = corr(projPc(:,i), sum(compressedMat(1:nLNs, 1:nLNs), 1)');
end
for i = 1:4
    correlations(i,5) = corr(projPc(:,i), otherOutputs(1:nLNs));
    correlations(i,6) = corr(projPc(:,i), otherInputs(1:nLNs)');
end
figure
plot(correlations)
ax = gca;
ax.XTick = 1:4; ax.XTickLabel = {'PC 1', 'PC 2', 'PC 3', 'PC 4'};
legend(corrTypes)
ylabel('Ccorrelation')
title(exp_title)
savefig(['Z:\Data\DM6_LN_analysis\' exp_title '_correlations.fig'])


    