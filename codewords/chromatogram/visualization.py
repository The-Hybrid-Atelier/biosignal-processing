import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
import numpy as np
from scipy.cluster.hierarchy import dendrogram, linkage, fcluster
from scipy.ndimage.filters import gaussian_filter1d
import pylab as pl
import matplotlib.gridspec as gridspec
import seaborn as sns
import matplotlib.font_manager as font_manager

COLOR_PALETTE = {
    'motion':  [],

    'emotion': [],

    'jupyter': []
}

def plot_chromatogram(cgram, users):
    sns.set_style('white')
    plt.figure(figsize=(20, 10))
    plt.title("{} Process Chromatogram".format(cgram.mts.feat_class.title()), name='CMU Bright', size=34, weight='bold', y=1.02, horizontalalignment='center')
    ax = plt.gca()

    data = cgram.chromatogram
    im = plt.imshow(data, aspect='auto', cmap='Set3')

    # https://stackoverflow.com/questions/25482876/how-to-add-legend-to-imshow-in-matplotlib
    values = list(range(cgram.codebook.K + 1))
    colors = [im.cmap(im.norm(value)) for value in values]
    perc = cgram.get_codeword_distribution()
    patches = [mpatches.Patch(color=colors[0], label="Codeword 0")] # don't display % for null codeword
    patches += [mpatches.Patch(color=colors[i], label="Codeword {} ({:.2f}%)".format(values[i], 100*perc[i])) for i in values[1:]]
    ax.set_yticks(list(range(len(users))))
    ax.set_yticklabels(users)
    plt.setp(ax.get_yticklabels(), name='CMU Bright', size=18, weight='bold')
    plt.ylabel('User', name='CMU Bright', size=25, weight='bold', labelpad=15)
    plt.setp(ax.get_xticklabels(), name='CMU Bright', size=15, weight='bold')
    font = font_manager.FontProperties(family='CMU Bright',
                                   weight='bold', size=18)
    plt.legend(handles=patches, bbox_to_anchor=(1.01, 1), loc=2, borderaxespad=0., borderpad=0, frameon=False, prop=font)
    plt.show()

def fancy_dendrogram(*args, **kwargs):
    max_d = kwargs.pop('max_d', None)
    if max_d and 'color_threshold' not in kwargs:
        kwargs['color_threshold'] = max_d
    annotate_above = kwargs.pop('annotate_above', 0)

    ddata = dendrogram(*args, **kwargs)

    if not kwargs.get('no_plot', False):
        plt.title('Hierarchical Clustering Dendrogram (truncated)')
        plt.xlabel('Sample index or (cluster size)')
        plt.ylabel('Distance')
        for i, d, c in zip(ddata['icoord'], ddata['dcoord'], ddata['color_list']):
            x = 0.5 * sum(i[1:3])
            y = d[1]
            if y > annotate_above:
                plt.plot(x, y, 'o', c=c)
                plt.annotate("%.3g" % y, (x, y), xytext=(0, -5),
                             textcoords='offset points',
                             va='top', ha='center')
        ax = plt.gca()
        for tick in ax.xaxis.get_major_ticks():
            tick.label.set_fontsize(pl.rcParams['xtick.labelsize']) 
        if max_d:
            plt.axhline(y=max_d, c='grey', lw=2, linestyle='dashed')

    return ddata

def vis_codewords(codebook, K, word_shape, title):
    F = word_shape[0]
    W = word_shape[1]
    cm = plt.get_cmap("Set3")
    colors = [cm(i) for i in np.linspace(0, 1, K+1)]

    # SETUP
    sns.set_style('whitegrid')
    fig = plt.figure(figsize=(20, 8))
    if K % 2 == 1:
        cols = K // 2 + 1
    else:
        cols = K // 2
    outer = gridspec.GridSpec(2, cols, wspace=0.1, hspace=0.3)      
    fig.suptitle("{} Codebook".format(title), name='CMU Bright', size=30, weight='bold', y=1., horizontalalignment='center')

    # axs = axs.reshape(-1)

    for i, cw in codebook.items():
        inner = gridspec.GridSpecFromSubplotSpec(F, 1, subplot_spec=outer[i-1], hspace=0.03)
        cw = cw.reshape((F, -1))

    #     outer[i-1].suptitle("Codeword {}".format(i), name='CMU Bright', size=15, weight='bold')

        for j in range(F):
            x = cw[j]
            ax = plt.Subplot(fig, inner[j])
            
            ax.set_ylim(-3, 3)
            ax.set_yticks([-1.5, 0, 1.5, 3])
            ax.set_xlim(0, W-1)
            
            if j == 0:
                ax.set_title("Codeword {}".format(i), name='CMU Bright', size=20, weight='bold')
            
            x_smooth = gaussian_filter1d(x, sigma=0.75)
            ax.plot(x, color='k', alpha=0.4, linewidth=1.5)
            ax.plot(x_smooth, color='k', alpha=1, linewidth=1)
            
            ax.axvspan(0, W, facecolor=colors[i], alpha=0.5)
            
            plt.setp(ax.get_yticklabels(), name='serif', size=9)
            
            if j != F-1:
                plt.setp(ax.get_xticklabels(), visible=False)
            else:
                plt.setp(ax.get_xticklabels(), name='CMU Bright', size=10, weight='bold');
            fig.add_subplot(ax)

def plot_user(cgram, user, sigma):
    sns.reset_orig()

    plt.figure(figsize=(20, 4))
    plt.suptitle("User {} {} Chromatogram".format(user, cgram.mts.feat_class.title()), 
                    name='CMU Bright', size=30, weight='bold', y=1.05)
    plt.subplots_adjust(hspace=0.08)
    plt.margins(0)

    F = len(cgram.mts.features)
    B = len(cgram.mts[user][0])
    axs = []
    for i in range(F):
        ax = plt.subplot(F, 1, i+1)

        axs.append(ax)
        ax.set_xlim(0, B-1)
        # ax.set_ylim(-3, 3)
        # ax.set_yticks([-1.5, 0, 1.5, 3])

        x_raw = cgram.mts[user][i]
        x_smooth = gaussian_filter1d(x_raw, sigma=sigma)
        ax.plot(x_raw, color='k', alpha=0.4, linewidth=0.75)
        ax.plot(x_smooth, color='k', alpha=1, linewidth=0.75)

        ax.yaxis.grid(True)
        ax.set_ylabel(cgram.mts.features[i], name='CMU Bright', size=15, weight='bold')

        if i == F-1:
            plt.setp(ax.get_xticklabels(), name='CMU Bright', size=15, weight='bold')
        else:
            plt.setp(ax.get_xticklabels(), visible=False)

        plt.setp(ax.get_yticklabels(), name='serif', size=9)


    window_size = cgram.mts.word_shape[1]

    K = cgram.codebook.K
    cm = plt.get_cmap("Set3")
    colors = [cm(i) for i in np.linspace(0, 1, K+1)]

    uid = cgram.mts.users.index(user)
    codes = cgram.chromatogram[uid]

    for i in range(len(codes)):
        cw = int(codes[i])
        if cw == 0:
            break
        
        for ax in axs:
            start = i * (window_size // 2)
            stop = start + window_size
            ax.axvspan(start, stop, 
                       facecolor=colors[cw], edgecolor=None, alpha=0.5)
    plt.show()