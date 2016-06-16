function [synapses] = synapses_by_group(goi, grpInds, adj, varargin)
% synapses_by_group takes a list of indices (length N) belonging to a group of
% interest (goi), and finds total # of input and  output synapses that each
% goi member makes on to other predefined groups. grpInd must be a cell
% array of length M, where M = the number of groups, and each entry in
% grpInd is a list of indices for each of the M groups.
%
% synapses is N x M x 2, where the first entry of the third dimension is
% output synapses (T-bars), and the second entry of the third dimension is
% input synapses (PSDs).

p = inputParser;
p.KeepUnmatched = false;
p.StructExpand = false;
p.CaseSensitive = false;

p.addParamValue('includeOther',0,@isnumeric);

p.parse(varargin{:});
includeOther = p.Results.includeOther;

if includeOther
    iOther = ones(size(adj, 1), 1);
    for i = length(grpInds)
        iOther(grpInds{i}) = 0;
    end
    grpInds{end + 1} = find(iOther);
end
for i = 1:length(grpInds)
    synapses(:, i, 1) = sum(adj(goi, grpInds{i}),2);
    synapses(:, i, 2) = sum(adj(grpInds{i}, goi),1);
end
end