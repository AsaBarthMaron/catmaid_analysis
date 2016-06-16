function [groups] = randomize_grouping(objList)
% Needs description
nObj = size(objList, 1);
% Chose a random number of groups
nGroups = ceil((rand(1) * (nObj - 1))) + 1;
% Randomly assign group sizes
minGrpInds = randsample(1:nGroups, nGroups);
groups = num2cell(objList(minGrpInds));
objList(minGrpInds) = [];
groupAdd = [];
nRem = length(objList);
while nRem ~= 0
    nAdd = ceil(rand(1) * nRem);
    groupAdd = [groupAdd nAdd];
    nRem = nRem - nAdd;
end
for i = 1:length(groupAdd)
    igroup = mod(i, nGroups);
    if igroup == 0
        igroup = length(groups);
    end
    tmpGrpInds = randsample(1:groupAdd(i), groupAdd(i));
    groups{igroup} = [groups{igroup}...
                                 objList(tmpGrpInds)'];
    objList(tmpGrpInds) = [];
end