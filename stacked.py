import numpy as np
import matplotlib.pyplot as plt


def bargraph(data, blabels=None, glabels=None, plabels=None):
    """
    bargraph takes in a n x m numpy array and plots m bars grouped in n groups
    """

    # Determines the optimal number of subplots

    N, M, S = data.shape

    width = 0.9       # the width of the bars
    ind = np.arange(N)  # the x locations for the groups
    c = colorlist(M)  # the colors for the bars

    fig, ax = plt.subplots()

    rects = []
    for i_N in range(N):
        for i_S in range(S):
            data[i_N, :, i_S] = data[i_N, :, i_S] / data[i_N, :, i_S].sum()

    for i_group in np.arange(S):
        spacer = i_group * (N + 0.3)
        rects.append(ax.bar(ind + spacer, data[:, 0, i_group], width, color=c[0]))
        bottom = data[:, 0, i_group]
        for i_subgroup in range(M)[1:]:
            rects.append(ax.bar(ind + spacer, data[:, i_subgroup, i_group], width, color=c[i_subgroup],
                                bottom=bottom))
            bottom += data[:, i_subgroup, i_group]


    # add some text for labels, title and axes ticks
    ax.set_ylabel('contacts by %')
    # ax.set_xticks([0.5, 1.5, )

    try:
        if glabels is None:
            pass
        elif len(glabels) == N:
            ax.set_xticklabels(glabels)
        else:
            raise BadGroupLabels

        if blabels is None:
            pass
        elif len(blabels) == M:
            ax.legend(blabels)
        else:
            raise BadBarLabels
    except BadGroupLabels:
        print("Improper number of group labels")
    except BadBarLabels:
        print("Improper number of bar labels")

    # def autolabel(rects):
    #     # attach some text labels
    #     for rect in rects:
    #         height = rect.get_height()
    #         ax.text(rect.get_x()+rect.get_width()/2., 1.05*height, '%d'%int(height),
    #                 ha='center', va='bottom')
    #
    # autolabel(rects1)
    # autolabel(rects2)

    plt.show()

def colorlist(ncolors):
    clist = ('g', 'm', 'b', 'r', 'y', 'c')
    full_list = clist * (ncolors / len(clist))
    remainder = ncolors % len(clist)
    full_list = full_list + clist[:remainder]
    return full_list


class BadGroupLabels(Exception):
    pass


class BadBarLabels(Exception):
    pass

class BadSubplotLabels(Exception):
    pass__author__ = 'asa'
