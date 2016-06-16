function [Y, Z, copDist, meanInconsistency] = cluster_goi(data)

Y = pdist(data,'euclidean');
Z = linkage(Y,'average');
copDist = cophenet(Z,Y);

I = inconsistent(Z);
meanInconsistency = mean(I(:,4));