""" Bargraph plots data in up to 3 dimensions, where the first is groupings of bars, the second is bars within each
    group, and the third is subplots. If only one dimension is presented the default will be multiple bars, not groups.
"""
import numpy as np
import matplotlib.pyplot as plt


def bargraph(data, blabels=None, glabels=None, plabels=None, sem=None):
    """
    bargraph takes in a n x m numpy array and plots m bars grouped in n groups
    """
    if sem is None:
        sem = np.zeros(data.shape)

    # Determines the optimal number of subplots
    n_rows = n_cols = 1  # default value for number of subplots
    if len(data.shape) == 3:
        N, M, S = data.shape
        sqrt_s = np.sqrt(S)
        if sqrt_s == int(sqrt_s):
            if S == 1:
                data = data.squeeze(axis=2)
                sem = sem.squeeze(axis=2)
                plabels = plabels[0]
            else:
                n_rows = n_cols = int(sqrt_s)
        elif sqrt_s != int(sqrt_s):
            n_for_rectangle = np.floor(sqrt_s) * np.ceil(sqrt_s)
            if n_for_rectangle >= S:
                n_rows = int(np.floor(sqrt_s))
                n_cols = int(np.ceil(sqrt_s))
            else:
                n_rows = n_cols = int(np.ceil(sqrt_s))
    elif len(data.shape) == 2:
        N, M = data.shape
    elif len(data.shape) == 1:
        N = 1
        M = data.shape

    width = 1.0 / (M + 2)       # the width of the bars
    ind = np.arange(N)  # the x locations for the groups
    c = colorlist(M)  # the colors for the bars

    fig, ax = plt.subplots(n_rows, n_cols)
    if n_rows * n_cols == 1:
        plot(data, width, ind, N, M, c, ax, glabels, blabels, plabels, sem)
    elif (n_rows == 1) ^ (n_cols == 1):
        for i_plot in range(S):
            plot(data[:, :, i_plot], width, ind, N, M, c, ax[i_plot], glabels, blabels, plabels[i_plot], sem[:, :, i_plot])
    elif (n_rows > 1) and (n_cols > 1):
        i_data = 0
        for i_row in range(n_rows):
            for i_col in range(n_cols):
                plot(data[:, :, i_data], width, ind, N, M, c, ax[i_row][i_col], glabels, blabels, plabels[i_data], sem[:, :, i_data])
                i_data += 1


def plot(data, width, ind, N, M, c, ax, glabels, blabels, title, sem):

    rects = []
    for i_group in range(M):
        rects.append(ax.bar(ind + (width * i_group), data[:, i_group], width, color=c[i_group], yerr=sem[:, i_group]))


    # add some text for labels, title and axes ticks
    ax.set_ylabel('# contacts')
    ax.set_title(str(title))
    ax.set_xticks(ind+width)

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
            pass
        else:
            raise BadBarLabels
    except BadGroupLabels:
        print("Improper number of group labels")
    except BadBarLabels:
        print("Improper number of bar labels")
    #
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
    pass