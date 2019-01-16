from glob import glob
import json, datetime, time, os, random, platform

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

def time2L(users, mts, seconds):
    u = users[0]
    samples = mts[u].shape[1]
    contents, f = get_file(os.path.join("irb", str(u)), "sessionmetadata")
    total_time = contents["elapsed_time"]
    L = int(seconds/total_time * samples)
    return L

def compute(mts, L, cull_threshold=None):
	

def apply(codewords, )

def sample_kcenters_pdist(words, kcenters, cull_threshold=100):
    if len(words) <= 1: 
        return np.array(kcenters)
    
    dtw_along_axis = np.vectorize(dtw2, signature='(n),(m)->()')
    dists = dtw_along_axis(words, kcenters[-1])
    
    idx = np.argsort(dists)
    kcenters.append(words[idx[-1]])    
    dists = np.sort(dists)
    print("WORDS", words.shape[0], "CENTERS", len(kcenters))
    cull_at = np.argmax(dists>cull_threshold)
    cull_indices = idx[:cull_at]
    cull_indices = np.append(cull_indices, idx[-1])
    words = np.delete(words, cull_indices, 0)
    return np.array(sample_kcenters_pdist(words, kcenters, cull_threshold))