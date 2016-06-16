clear
folderPath = 'Z:\Data\Catmaid_exports\Catmaid3\2016-06-13';
neuronData = loadjson(fullfile(folderPath, 'adjacency_matrix.json'));
load(fullfile(folderPath, 'adj_m.mat'));
LN_DM6 = load(fullfile(folderPath, 'LN_DM6.mat'));
DM6_ORN = load(fullfile(folderPath, 'DM6_ORN.mat'));
Left_ORN = load(fullfile(folderPath, 'Left_ORN.mat'));
Right_ORN = load(fullfile(folderPath, 'Right_ORN.mat'));
Left_PN = load(fullfile(folderPath, 'Left_PN.mat'));

nnames = neuronData.nnames;
nids = neuronData.nids;
skids = neuronData.skids;

%% Decrease matrix size
% Compress the matrix down to only include things that syanpse with LNs in
% the left DM6.

% Find index of all LNs
iLNs = NaN(length(LN_DM6.nids), 1);
for i = 1:length(LN_DM6.nids)
    iLNs(i) = find(LN_DM6.nids(i) == nids);
end

% Find location of all skeletons that have at least 1 synapse with any LN.
LNToAll = adj_m(iLNs, :);
allToLN = adj_m(:, iLNs);
isPostLN = sum(LNToAll,1);
isPreLN = sum(allToLN,2);
isSynLN = isPostLN' + isPreLN;
isSynLN = isSynLN > 0;

% Get rid of everything that does not have at least 1 synapse with any LN.
adj_m(~isSynLN, :) = [];
adj_m(:, ~isSynLN) = [];
nnames(~isSynLN) = [];
nids(~isSynLN) = [];
skids(~isSynLN) = [];

%% Check data
checkData = 0
if checkData
    imagesc(adj_m)
    pause
    plot(sum(adj_m, 1))
    hold on
    plot(sum(adj_m, 2))
end

%% Find index of all ORNs, PNs, LNs, and other.
iLNs = find_multiple(LN_DM6.nids, nids');
iORNs = find_multiple(DM6_ORN.nids, nids');
iLORNs = find_multiple(Left_ORN.nids, nids');
iRORNs = find_multiple(Right_ORN.nids, nids');
iPNs = find_multiple(Left_PN.nids, nids');

% Special case: ORN 53 is only on the right side, and therefore should be
% discluded.
iORN53 = find(6151 == Right_ORN.nids); % Careful, nid for ORN 53 might change
iRORNs(iORN53) = [];
Right_ORN.nids(iORN53) = [];
Right_ORN.nnames(iORN53) = [];
iORN53 = find(6151 == DM6_ORN.nids); % Careful, nid for ORN 53 might change
iORNs(iORN53) = [];
DM6_ORN.nids(iORN53) = [];
DM6_ORN.nnames(iORN53) = [];

%% Get inputs and outputs by group
% Pass in group of interest (usually LNs), and group indexes. Get back total
% # of synapses to and from each group for each member of interest group.

grpLN = synapses_by_group(iLNs, [{iLORNs}, {iRORNs}, {iPNs}, {iLNs}], adj_m,...
    'includeOther', 0);
%% Normalize synapse counts
normMethod{1} = 'nodeCount';
normMethod{2} = 'nodeCount';

for i = 1:length(normMethod)
    
    switch normMethod{i}
        % Method 1: by node count
        case 'nodeCount'
            grpLN(:,:,i) = bsxfun(@rdivide, grpLN(:,:,i), LN_DM6.nodeNr);
            % Method 2: as a % of synapses for individual neuron
        case 'asPercentage'
            grpLN(:,:,i) = bsxfun(@rdivide, grpLN(:,:,i), sum(grpLN(:,:,i), 2));
            % Method 3: No normalization.
        case 'none'
    end
end
grpLN(isnan(grpLN)) = 0;
%% Cluster 
%% Select LN groups
% What I actually want to do here is much more complicated than what I am
% about to do. What I would like to do is to go through each possible
% number of groups (nGroups), from 1 to nLNs. For each nGroups I want to
% find all possible ways of splitting LNs into nGroups, with variable group
% sizes, and the constraint that each group must have at least one LN.
%
% What I think I will do in the interim, is to just pick a random number of
% groups, and then a random split of LNs into those groups. I will iterate
% this a bunch of times. Using this along with some sort of cost function
% might be better anyway because it might not be possible to sample the
% whole space described above.
randomGroups = 0;
if randomGroups
    clear copDist meanInconsistency lnGroups
    rng(1)
    tic
    for i = 1:1000000
        
        lnGroups{i} = randomize_grouping(iLNs);
        grpLN = synapses_by_group(iLNs, [{iLORNs}, {iRORNs}, {iPNs}, lnGroups{i}'], adj_m,...
            'includeOther', 0);
        % Cluster goi members by synapses they make on to other groups.
        % This should probably be a separate function eventually.
        for j = 1:2
            grpLN(:,:,j) = bsxfun(@rdivide, grpLN(:,:,j), LN_DM6.nodeNr);
            [~, ~, copDist(i, j), meanInconsistency(i, j)] = cluster_goi(grpLN(:,:,j));
        end
    end
    toc
end
%% Inspect top hit
% Find best group labels, as determined by maximum mean inconsistency
if randomGroups
    mmInc = mean(meanInconsistency, 2);
    max(mmInc)
    bestGroupInd = find(mmInc == max(mmInc))
    bestGroup = lnGroups{bestGroupInd};
    
    % Recalculate group data since it would be ridiculous to save it for each
    % shuffle.
    grpLN = synapses_by_group(iLNs, [{iLORNs}, {iRORNs}, {iPNs},...
        lnGroups{bestGroupInd}'], adj_m, 'includeOther', 0);
    
    % Recluster
    for j = 1:2
        grpLN(:,:,j) = bsxfun(@rdivide, grpLN(:,:,j), LN_DM6.nodeNr);
        [Y{j}, Z{j}, copDist(i, j), meanInconsistency(i, j)] = cluster_goi(grpLN(:,:,j));
    end
    
    figure
    subplot(3,1,1)
    T = cluster(Z{2},'cutoff',1);
    [~,~, iNs] = dendrogram(Z{2},40);
    nNs = length(iNs);
    ax = gca; ax.XTickLabel = T(iNs);
    title('Clustered on input synapses to LNs (PSDs)')
    T(iNs);
    sortedGrps = grpLN(iNs,:,:);
    subplot(3,1,2)
    bar(sortedGrps(:,:,1), 'stacked')
    ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
    axis tight
    subplot(3,1,3)
    bar(sortedGrps(:,:,2), 'stacked')
    ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
    axis tight
    
    figure
    subplot(3,1,1)
    T = cluster(Z{1},'cutoff',1);
    [~,~, iNs] = dendrogram(Z{1},40);
    title('Clustered on LN output synapses (T-Bars)')
    nNs = length(iNs);
    ax = gca; ax.XTickLabel = T(iNs);
    T(iNs);
    sortedGrps = grpLN(iNs,:,:);
    subplot(3,1,2)
    bar(sortedGrps(:,:,1), 'stacked')
    ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
    axis tight
    subplot(3,1,3)
    bar(sortedGrps(:,:,2), 'stacked')
    ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
    axis tight
    
    for i = 1:length(bestGroup)
        bestGroupLNNames{i} = nnames(bestGroup{i});
    end
end
%% Further reduce matrix size to only ORNs, PNs and LNs
n.LNs = length(iLNs);
n.LORNs = length(iLORNs);
n.RORNs = length(iRORNs);
n.PNs = length(iPNs);

iAll = [iLNs; iLORNs; iRORNs; iPNs];
iLNs = 1:n.LNs;
iLORNs = n.LNs+1:n.LNs+n.LORNs;
iRORNs = n.LNs+n.LORNs+1:n.LNs+n.LORNs+n.RORNs;
iPNs = n.LNs+n.LORNs+n.RORNs+1:n.LNs+n.LORNs+n.RORNs+n.PNs;
adj_m = adj_m(iAll, iAll);
adj_m
%%
compressEx = 1;
if compressEx
    % Compress ORNs and PNs into one mega right ORN, left ORN and PN.
    X = adj_m(iLNs, iLNs);
    X(n.LNs+1, iLNs) = sum(adj_m(iLORNs, iLNs), 1);
    X(iLNs, n.LNs+1) = sum(adj_m(iLNs, iLORNs), 2);
    X(n.LNs+2, iLNs) = sum(adj_m(iRORNs, iLNs), 1);
    X(iLNs, n.LNs+2) = sum(adj_m(iLNs, iRORNs), 2);
    X(n.LNs+3, iLNs) = sum(adj_m(iPNs, iLNs), 1);
    X(iLNs, n.LNs+3) = sum(adj_m(iLNs, iPNs), 2);
else
    X = adj_m;
end
%% PCA on adjacency matrix
pX = double([X(:,1:n.LNs); X(1:n.LNs,:)']);
% pX = double([X; X']);
pX = pX';
% pX = bsxfun(@rdivide, pX, LN_DM6.nodeNr);
pX = bsxfun(@rdivide, pX, sum(pX, 2));
pX = pX'
[u,s,v] = svd(pX);

projPC = pX' * u;
figure;
subplot(2,2,1)
plot(projPC(:,1), projPC(:,2), '*')
subplot(2,2,2)
plot(diag(s), '*')
subplot(2,2,3)
plot(u(:,1))
subplot(2,2,4)
plot(u(:,2))


%% Clustering
clear cX Y Z
% clusterMethod = 'individual';
clusterMethod = 'combined';
switch clusterMethod
    case 'individual'
        cX(:,:,1) = double(X(:,1:n.LNs)');
        cX(:,:,2) = double(X(1:n.LNs,:));
        for j = 1:2
            cX(:,:,j) = bsxfun(@rdivide, cX(:,:,j), LN_DM6.nodeNr);
            [Y{j}, Z{j}, copDist(j), meanInconsistency(j)] = cluster_goi(cX(:,:,j));
            figure
            subplot(3,1,1)
            T = cluster(Z{2},'cutoff',1);
            [~,~, iNs] = dendrogram(Z{2},40);
            nNs = length(iNs);
            ax = gca; ax.XTickLabel = T(iNs);
            title('Clustered on input synapses to LNs (PSDs)')
            T(iNs);
            sortedGrps = cX(iNs,:,:);
            subplot(3,1,2)
            bar(sortedGrps(:,:,1), 'stacked')
            ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
            axis tight
            subplot(3,1,3)
            bar(sortedGrps(:,:,2), 'stacked')
            ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
            axis tight
            
            figure
            subplot(3,1,1)
            T = cluster(Z{1},'cutoff',1);
            [~,~, iNs] = dendrogram(Z{1},40);
            title('Clustered on LN output synapses (T-Bars)')
            nNs = length(iNs);
            ax = gca; ax.XTickLabel = T(iNs);
            T(iNs);
            sortedGrps = cX(iNs,:,:);
            subplot(3,1,2)
            bar(sortedGrps(:,:,1), 'stacked')
            ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
            axis tight
            subplot(3,1,3)
            bar(sortedGrps(:,:,2), 'stacked')
            ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
            axis tight
        end
    case 'combined'
        cX = [double(X(:,1:n.LNs)'), double(X(1:n.LNs,:))];
        cX = bsxfun(@rdivide, cX, LN_DM6.nodeNr);
        [Y, Z, copDist, meanInconsistency] = cluster_goi(cX);
        figure
        subplot(2,1,1)
        T = cluster(Z,'cutoff',1);
        [~,~, iNs] = dendrogram(Z,40);
        nNs = length(iNs);
        ax = gca; ax.XTickLabel = T(iNs);
        title('Clustered on input synapses to LNs (PSDs)')
        T(iNs);
        sortedGrps = cX(iNs,:,:);
        subplot(2,1,2)
        bar(sortedGrps, 'stacked')
        ax = gca; ax.XTick = 1:nNs; ax.XTickLabel = LN_DM6.simpleNames(iNs);
        axis tight
end
%% Things to do:
% Add in options to normalize in various ways. The most logical way of
% normalizing would be to normalize to path length (or node # in the interim
% - which is easier and more immediate). It might also be fun to try a
% normalization that is based on the fraction of the receiving cell's
% inputs.
%
% Add in code to cluster and visualize clusters
%
% Add in code to try many random permutations of LN groupings, and see which one
% maximizes cluster separation. Perhaps an existing machine learning algorithm
% can do something like this.
% figure
% subplot(2,1,1)
% bar(grpLN(:,:,1), 'stacked')
% subplot(2,1,2)
% bar(grpLN(:,:,2), 'stacked')