from glob import glob
import json, datetime, time, os, random, platform, sys

import scipy
from tslearn import metrics as tsm

from scipy import ndimage, signal
import scipy.spatial.distance as distance
from scipy.spatial.distance import euclidean, pdist, squareform, cdist
from scipy.cluster import hierarchy
from scipy.cluster.hierarchy import dendrogram, linkage, fcluster
from scipy.ndimage.filters import gaussian_filter1d

import numpy as np
from numpy.lib.stride_tricks import as_strided
np.set_printoptions(precision=3, suppress=True)  # suppress scientific float notation

from chromatogram.dataset import get_file, mts2df, df2mts, MTS
from chromatogram import visualization

class Codebook:
    def __init__(self, mts):
        self.mts = mts
        self.distilled = False
        self.extracted = False

    def distill(self, cull_threshold):
        sss = self.mts.samples
        word_shape = self.mts.word_shape

        # Sample using greedy k-centers clustering
        N = sss.shape[0]
        first_center = random.randint(0, N)
        first_center = N // 2
        seed = sss[first_center]
        code_sample = np.delete(sss, first_center, 0)

        # Construct distance metric
        dtw = make_multivariate_dtw(word_shape)

        self.centers = sample_kcenters(code_sample, [seed], dtw, cull_threshold)
        M = self.centers.shape[0]
        print('Sampled M={} centers, {:.2f}%% of original N={} sequences'.format(M, (M / N) * 100, N))
        print("--------------------------------------------------")

        # Hierarchical clustering and pruning
        print('Hierarchical clustering...', end='\r')
        self.linkage_matrix = linkage(self.centers, method='complete', metric=dtw)
        print("Generated hierarchical cluster")
        self.distilled = True

    def extract(self, K):
        if not self.distilled:
            print("Must call Codebook.distill() before extract")
            return

        self.K = K
        word_shape = self.mts.word_shape
        dtw = make_multivariate_dtw(word_shape)

        clusters = fcluster(self.linkage_matrix, K, criterion='maxclust')

        # Codeword extraction
        codebook = {}
        for i in range(len(clusters)):
            cluster_id = clusters[i]
            if not cluster_id in codebook:
                codebook[cluster_id] = []
            codebook[cluster_id].append(self.centers[i])


        for i in range(1, K+1):
            print("Codeword {}: Cluster size={}".format(i, len(codebook[i])))

        # Computer centroid
        for k in codebook:
            codeset = np.array(codebook[k])
            dist = np.sum(squareform(distance.pdist(codeset, metric=dtw)), 0)
            clustroid = np.argmin(dist)
            codebook[k] = codeset[clustroid]

        self.codebook = codebook
        self.extracted = True
        return codebook

    def visualize_linkage(self, d=0):
        if not self.distilled:
            print("Must call Codebook.distilled() before visualize_linkage")

        return visualization.fancy_dendrogram(self.linkage_matrix, truncate_mode='lastp',
                                            p=12,
                                            leaf_rotation=90.,
                                            leaf_font_size=12.,
                                            show_contracted=True,
                                            annotate_above= 0.4, 
                                            max_d=d)

    def visualize(self):
        if not self.extracted:
            print("Must call Codebook.extract() before visualize_codewords")

        return visualization.vis_codewords(self.codebook, self.K, self.mts.word_shape, self.mts.feat_class.title())

    def apply(self, smoothing_window=0, sigma=4):
        assert self.extracted, "Must call Codebook.extract() before applying codebook"
        
        return Chromatogram(self.mts, self)

class Chromatogram:
    def __init__(self, mts, codebook):
        self.mts = mts
        self.codebook = codebook

    def render(self, smoothing_window=0, sigma=3):
        if smoothing_window > 0:
            assert smoothing_window % 2 == 1, 'Smoothing window must be odd'
        dtw = make_multivariate_dtw(self.mts.word_shape)

        def normalize(word):
            for i in range(word.shape[0]):
                std = np.std(word[i])
                if std == 0:
                    word[i] = word[i] - np.mean(word[i])
                else:
                    word[i] = (word[i] - np.mean(word[i])) / np.std(word[i])
            return word.flatten()

        def window_smooth(data, S):
            output = []
            M = len(data)
            for i in range(M):
                min_val = max(i-(S // 2), 0)
                max_val = min(i+(S // 2), M)

                dsum = np.sum(data[min_val:max_val], axis=0)
                most_common = np.argmax(dsum) + 1
                output.append(most_common)
            return np.array(output)

        def gaussian_smooth(data, sigma):
            return gaussian_filter1d(data, sigma)

        sss = self.mts.samples
        N = len(sss)

        results = []
        for i in range(N):
            w = normalize(sss[i].reshape(self.mts.word_shape))
            cw_dists = [dtw(cw, w) for cw in self.codebook.codebook.values()]
            results.append(cw_dists)

        bounds = self.mts.bounds
        sizes = []
        for i in range(len(bounds)-1):
            start = bounds[i]
            end = bounds[i+1]
            sizes.append(end-start)
        tn = max(sizes)

        chromatogram = np.zeros((len(bounds) - 1, tn))
        raw = np.zeros((len(bounds) - 1, tn))

        for i in range(len(sizes)):
            data = np.array(results[bounds[i]:bounds[i+1]])

            if smoothing_window > 0 and sigma > 0:
                chromatogram[i, :sizes[i]] = window_smooth(gaussian_smooth(data, sigma), smoothing_window)

            elif sigma > 0 and smoothing_window == 0:
                chromatogram[i, :sizes[i]] = np.argmax(gaussian_smooth(data, sigma), axis=1) + 1

            elif sigma == 0 and smoothing_window > 0:
                chromatogram[i, :sizes[i]] = window_smooth(data, smoothing_window)

            else:
                chromatogram[i, :sizes[i]] = np.argmax(data, axis=1) + 1

            raw[i, :sizes[i]] = np.argmax(data, axis=1) + 1

        self.chromatogram = chromatogram
        self.raw = raw
        self.smoothing_stats()

    def smoothing_stats(self):
        U, T = self.raw.shape

        raw_changes = 0
        smooth_changes = 0
        raw_len = []
        smooth_len = []

        for u in range(U):
            raw_row = self.raw[u]
            smooth_row = self.chromatogram[u]

            last_raw = raw_row[0]
            last_smooth = smooth_row[0]
            max_len_raw = 1
            max_len_smooth = 1

            for i in range(1, len(raw_row)):
                curr_raw = raw_row[i]
                curr_smooth = smooth_row[i]
                if curr_raw == 0:
                    break

                if curr_raw != last_raw:
                    raw_changes += 1

                    raw_len.append(max_len_raw)
                    max_len_raw = 1
                else:
                    max_len_raw += 1

                if curr_smooth != last_smooth:
                    smooth_changes += 1

                    smooth_len.append(max_len_smooth)
                    max_len_smooth = 1
                else:
                    max_len_smooth += 1 

                last_raw = curr_raw
                last_smooth = curr_smooth

        print("SMOOTHING STATS: Δ_raw={}, Δ_smooth={}, ratio={:.4f}".format(raw_changes, smooth_changes, raw_changes / smooth_changes))
        print("CW LENGTH STATS: μ_raw   ={:.4f}, σ_raw   ={:.4f}\n                 μ_smooth={:.4f}, σ_smooth={:.4f}"\
            .format(np.mean(raw_len), np.std(raw_len), 
                                                                                     np.mean(smooth_len), np.std(smooth_len)))

    def visualize(self):
        visualization.plot_chromatogram(self, self.mts.users)

    def plot_user(self, user, sigma=3):
        visualization.plot_user(self, user, sigma)

    def get_codeword_distribution(self):
        dist = {i+1: 0 for i in range(self.codebook.K)}

        for row in self.chromatogram:
            for cw in row:
                cw = int(cw)
                if cw == 0:
                    break
                dist[cw] += 1

        total = sum(dist.values())

        for cw in dist.keys():
            dist[cw] /= total

        return dist

    def get_codeword_length_distribution(self):
        lengths = {i+1: [] for i in range(self.codebook.K)}

        K = self.codebook.K

        for i in range(len(self.mts.users)):
            row = self.chromatogram[i]

            last_cw = int(row[0])
            max_len = 1
            for j in range(1, len(row)):
                if row[j] == 0:
                    break

                curr_cw = int(row[j])

                if curr_cw == last_cw:
                    max_len += 1
                else:
                    lengths[last_cw].append(max_len)
                    max_len = 1

                last_cw = curr_cw

        return lengths

    def get_lengths_per_user(self):
        users = self.mts.users
        K = self.codebook.K

        len_per_user = {}

        for i in range(len(users)):
            len_per_cw = {i+1: [] for i in range(K)}

            row = self.chromatogram[i]

            last_cw = int(row[0])
            max_len = 1
            for j in range(1, len(row)):
                if row[j] == 0:
                    break

                curr_cw = int(row[j])

                if curr_cw == last_cw:
                    max_len += 1
                else:
                    len_per_cw[last_cw].append(max_len)
                    max_len = 1

                last_cw = curr_cw

            len_per_user[users[i]] = len_per_cw

        return len_per_user

    def get_markov_model(self):
        markov = {}

        K = self.codebook.K
        users = self.mts.users

        for i in range(len(users)):
            transition_matrix = np.zeros((K, K))
            row = self.chromatogram[i]

            for j in range(len(row) - 1):
                if row[j+1] == 0:
                    break

                curr_cw = int(row[j]) - 1
                next_cw = int(row[j+1]) -1
                transition_matrix[curr_cw, next_cw] += 1

            row_sums = transition_matrix.sum(axis=1) + 1e-12
            transition_matrix = transition_matrix / row_sums[:, np.newaxis]
            markov[users[i]] = transition_matrix

        return markov

############
# SAMPLING #
############

def subsequences(a, L):
    n, m = a.shape
    windows = int(m/L)    
    window_range = np.linspace(0, windows-1, (windows-1) * 2 + 1)
    ss = []
    for x in window_range:
        ss.append(a[:, int(x*L):int((x+1)*L)])
    return np.array(ss)

def extract_samples(umts, L):
    sss = np.array([])
    bounds = [0]
    for u in umts: 
        mts = umts[u]
        ss = subsequences(mts, L)
        bounds.append(bounds[-1] + ss.shape[0])
        if sss.shape[0] == 0:
            sss = ss
        else:
            sss = np.concatenate((sss, ss))
    word_shape = sss.shape[-2:]
    sss = sss.reshape(sss.shape[0], -1)
    return sss, bounds, word_shape

def time2L(users, mts, seconds):
    u = users[0]
    samples = mts[u].shape[1]
    contents, f = get_file(os.path.join("irb", str(u)), "sessionmetadata")
    total_time = contents["elapsed_time"]
    L = int(seconds/total_time * samples)

    # always make L even (for 50% overlap math)
    if L % 2 == 1:
        L += 1

    return L

def sample_sss(A, n):
    return A[np.random.choice(A.shape[0], n, replace=False), :]


def sample_kcenters(words, kcenters, dist_metric, cull_threshold=100):    
    if len(words) <= 1: 
        return np.array(kcenters)

    sys.stdout.write("\033[K")
    print("Sampling ... (words: {}, centers: {})".format(words.shape[0], len(kcenters)), end='\r')
    
    n = words.shape[0]
    dist = [dist_metric(kcenters[-1], words[i]) for i in range(0, n)]
    dists = np.array(dist)
    
    idx = np.argsort(dists)
    kcenters.append(words[idx[-1]])    
    dists = np.sort(dists)
    cull_at = np.argmax(dists>cull_threshold)
    
    cull_indices = idx[:cull_at]
    cull_indices = np.append(cull_indices, idx[-1])
    words = np.delete(words, cull_indices, 0)
    
    return np.array(sample_kcenters(words, kcenters, dist_metric, cull_threshold))

####################
# DISTANCE METRICS #
####################

def EuclideanDistance(t1, t2):
    return np.sqrt(np.sum((t1-t2)**2))

# Dynamic Time Warping Distance
def DTWDistance(s1, s2):
    # Initialize distance matrix (nxn), pad filling with inf  
    DTW= {}
    n1 = range(len(s1))
    n2 = range(len(s2))
    for i in n1:
        DTW[(i, -1)] = float('inf')
    for i in n2:
        DTW[(-1, i)] = float('inf')
    DTW[(-1, -1)] = 0
    
    # Compute the distances (O(nm) time)
    for i in n1:
        for j in n2:
            dist = (s1[i]-s2[j])**2
            DTW[(i, j)] = dist + min(DTW[(i-1, j)], DTW[(i, j-1)], DTW[(i-1, j-1)])
    return np.sqrt(DTW[len(s1)-1, len(s2)-1])

def DTWDistanceD(t1, t2):
    arr = []
    for i in range(0, t1.shape[0]):
        arr.append(DTWDistance(t1[i], t2[i]))
    return sum(arr)

def DTWDistance2D(t1, t2):
    t1 = t1.reshape(WORD_SHAPE)
    t2 = t2.reshape(WORD_SHAPE)
    arr = []
    for i in range(0, t1.shape[0]):
        arr.append(DTWDistance(t1[i], t2[i]))
    return sum(arr)

def dtw2(a, b, word_shape):
    a = a.reshape(word_shape)
    b = b.reshape(word_shape)
    return tsm.dtw(a, b)

def make_multivariate_dtw(word_shape):
    def dtw(a, b):
        a = a.reshape(word_shape)
        b = b.reshape(word_shape)
        return tsm.dtw(a, b)
    return dtw

###########################
# CHROMATOGRAPHY FUNCTION #
###########################

def distill(mts_df, window_size, cull_threshold, K, return_meta=False):
    # Reformat MTS from pandas df to dict user --> matrix
    mts, users, features = df2mts(mts_df)

    # Compute sample width
    L = time2L(users, mts, window_size)

    # Extract all sequence from MTS
    sss, bounds, word_shape = extract_samples(mts, L)
    N = sss.shape[0]
    print("Extracted N={} sequences with shape (F={}, L={})".format(N, word_shape[0], word_shape[1]))
    print("--------------------------------------------------")

    # Sample using greedy k-centers clustering
    first_center = random.randint(0, N)
    first_center = N // 2
    seed = sss[first_center]
    code_sample = np.delete(sss, first_center, 0)

    # Construct distance metric
    dtw = make_multivariate_dtw(word_shape)

    samples = sample_kcenters(code_sample, [seed], dtw, cull_threshold)
    M = samples.shape[0]
    print('Sampled M={} codewords, {:.2f}%% of original N={} sequences'.format(M, (M / N) * 100, N))
    print("--------------------------------------------------")

    # Hierarchical clustering and pruning
    linkage_matrix = linkage(samples, method='complete', metric=dtw)
    clusters = fcluster(linkage_matrix, K, criterion='maxclust')

    # Codeword extraction
    codebook = {}
    for i in range(len(clusters)):
        cluster_id = clusters[i]
        if not cluster_id in codebook:
            codebook[cluster_id] = []
        codebook[cluster_id].append(samples[i])

    # Computer centroid
    for k in codebook:
        codeset = np.array(codebook[k])
        dist = np.sum(squareform(distance.pdist(codeset, metric=dtw)), 0)
        clustroid = np.argmin(dist)
        codebook[k] = codeset[clustroid]

    print('Extracted {} codewords'.format(K))

    meta = {
        "L": L,
        "window_size": window_size,
        "bounds": bounds,
        "word_shape": word_shape,
        "users": users, 
        "features": features, 
        "subsequences": sss.tolist(),
        "linkage_matrix": linkage_matrix.tolist()
    }

    if return_meta:
        return codebook, meta
    else:
        return codebook

def apply(codebook, mts_df, window_size, smoothing_window=None):
    mts, users, features = df2mts(mts_df)
    # Compute sample width
    L = time2L(users, mts, window_size)

    sss, bounds, word_shape = extract_samples(mts, L)
    dtw = make_multivariate_dtw(word_shape)

    results = []
    for i, window in enumerate(sss):
        codeword = np.argmin([dtw(codeword, window) for codeword in codebook.values()])
        results.append(codeword + 1)

    sizes = []
    for i in range(len(bounds)-1):
        start = bounds[i]
        end = bounds[i+1]
        sizes.append(end-start)
    tn = max(sizes)

    chromatogram = np.zeros((len(bounds) - 1, tn))

    for i in range(len(sizes)):
        data = np.array(results[bounds[i]:bounds[i+1]])
        if smoothing_window:
            raise NotImplementedError
            return None
        else:
            chromatogram[i, :sizes[i]] = data

    return chromatogram

