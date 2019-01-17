from glob import glob
import json, datetime, time, os, random, platform, sys

import scipy
from tslearn import metrics as tsm

from scipy import ndimage, signal
import scipy.spatial.distance as distance
from scipy.spatial.distance import euclidean, pdist, squareform, cdist
from scipy.cluster import hierarchy
from scipy.cluster.hierarchy import dendrogram, linkage, fcluster

import numpy as np
from numpy.lib.stride_tricks import as_strided
np.set_printoptions(precision=3, suppress=True)  # suppress scientific float notation

from chromatogram.dataset import get_file

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

def subsequenceMTS(umts, L):
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
    return L

def sample_sss(A, n):
    return A[np.random.choice(A.shape[0], n, replace=False), :]

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
##############
# ALGORITHMS #
##############

def distill(mts, L, cull_threshold, K):
    # Extract all sequence from MTS
    sss, bounds, word_shape = subsequenceMTS(mts, L)
    N = sss.shape[0]
    print("Extracted N={} sequences with shape {}".format(N, word_shape))
    print("------------------------------------------")
    # Sample using greedy k-centers clustering
    first_center = random.randint(0, N)
    seed = sss[first_center]
    code_sample = np.delete(sss, first_center, 0)

    # Construct distance metric
    dtw = make_multivariate_dtw(word_shape)

    samples = sample_kcenters(code_sample, [seed], dtw, cull_threshold)
    M = samples.shape[0]
    print('Sampled M={} codewords, {:.2f}%% of original N={} sequences'.format(M, (M / N) * 100, N))
    print("------------------------------------------")

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
    return samples, linkage_matrix, codebook

def apply(mts, codebook):
    pass

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