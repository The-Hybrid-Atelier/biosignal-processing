import json, datetime, time, os
from glob import glob
import pylab as pl
import numpy as np
from scipy import stats

DATA_ROOT = "irb"

STUDY_FEATURES = {
    "motion": ["acc-x", "acc-y", "acc-z"], 
    "phasic": ["phasic"],
    "hr": ["hr"], 
    "bio": ["bvp", "temp"],
    "kinnunen": ["getting-started", "dealing-with-difficulties", 
                 "encountering-difficulties", "failing", "submitting", "succeeding"],
    "jupyter": ["execute", "mouseevent", "notebooksaved", "select", "textchunk"], 
    "q": ["q1", "q2", "q3", "q4"], 
    "notes": ["notesmetadata"], 
    "emotion": ["phasic", "hr"], 
    "acc": ["a-x", "a-y", "a-z"],
    "gyro": ["g-x", "g-y", "g-z"],
    "mag": ["m-x", "m-y", "m-z"],
    "iron":["m-x", "m-y", "m-z", "g-x", "g-y", "g-z", "a-x", "a-y", "a-z"]
}

#############
# I/O TOOLS #
#############

# Loads JSON files from dataset folder
def get_file(folder, prefix):
    user = os.path.basename(folder)
    files = glob(folder + "/"+prefix+"*.json")
    if len(files) == 0:
#         print("File not found", prefix, 'in', folder)
        return None, None
    else: 
        with open(files[0], 'r') as f: 
            contents = json.load(f)
            return contents, files[0]

# JSON saver utility
def save_jsonfile(name, data):
    with open(name, 'w') as outfile:
        json.dump(data, outfile)
    print("File saved!", name)

# saves MTS samples in a separate JSON file
def save_samples(L, window_size, bounds, word_shape, description, users, features, 
                subsequences, file_name):
    meta = {
        "L": L,
        "window_size": window_size,
        "bounds": bounds,
        "word_shape": word_shape,
        "description": description,
        "users": users, 
        "features": features, 
        "subsequences": subsequences.tolist()
    }

    if file_name[-5:] != '.json':
        file_name += '.json'

    out_file = os.path.join(DATA_ROOT, 'datasets', file_name)

    save_jsonfile(out_file, meta)

#############
# MTS TOOLS #
#############

def adjust_data(folder, data, t, Fs):
    metadata,f = get_file(folder, "sessionmetadata")
    if metadata == None:
        print('ERROR', folder, t)
        return
  
    # ADJUST Y AND T RANGE    
    start = metadata["session_start"] - t
    end = metadata["session_end"] - t    
    t0 = start * Fs 
    t0 = start * Fs  if start > 0 else 0
    tf = end * Fs - 1 if end < len(data) else len(data)
    t0 = int(t0)
    tf = int(tf)
    data = data[t0:tf]
    return data

def normalize(arr, min_v, max_v):
    if min_v == max_v:
        return arr
    return list((np.array(arr) - min_v) / (max_v - min_v))

def compile_features(features):
    feat = []
    for f in features:
        feat.extend(STUDY_FEATURES[f])
    return feat

def maxMinFeatures(umts):
    #MIN_MAX per features
    maxmin = {}
    for u in umts:
        mts = umts[u]
        for i, f in enumerate(mts):
            if not i in maxmin:
                maxmin[i] = []
            maxmin[i].append((min(f), max(f)))
    for x in maxmin: 
        maxmin[x] = [ii for ii in zip(*maxmin[x])]
    return maxmin

def computeFBounds(maxmin, features):
    fbounds = {}
    for i in maxmin: 
        f = features[i]
        f_min = min(maxmin[i][0])
        f_max = max(maxmin[i][1])
        fbounds[f] = (f_min, f_max)
    return fbounds

def extractMTS(users, features):
    tsum = 0
    umts = {}
    for user in users: 
        # print(user)
        mts = []
        folder = os.path.join(DATA_ROOT, str(user))
            
        for feature in features: 
            contents, f = get_file(folder, feature)
            if not f:
                continue
                
            #Frequency encoded feature
            if "sampling_rate" in contents:
                data = contents["data"]           
                t = contents["timestamp"]
                F = contents["sampling_rate"]
                # print(feature, '\tt_start: ', t, '\tsr: ', F)
                data = adjust_data(folder, data, t, F)
                mts.append(data)
                tsum = tsum + len(data)
            #Time encoded feature
            else:
                
                data = contents["data"]
                if "y" in data:
                    data = data["y"]
                mts.append(data)
                tsum = tsum + len(data)
        if len(mts) > 0:
            umts[user] = mts
        else:
            print("Insufficient data for %s. Not included in final MTS."%user)
    return umts, tsum


# Construct final representation    
def resampleFeatureMTS(umts, features, rejectIncomplete = False):   
    if rejectIncomplete:
        print("Rejecting incomplete features")
        umts_validated = {}
        for u in umts: 
            mts = umts[u]
            if(len(mts) != len(features)):
                print("Insufficient feature data for %s. Not included in final MTS."%u)
                continue
            else:
                umts_validated[u] = mts
        umts = umts_validated  
        
    for u in umts:
        mts = umts[u]
        
        max_t = len(max(mts, key=lambda f: len(f)))
        fmts = np.zeros((len(mts), max_t))
        
        print('User:', u, '\tFeats: ', len(mts), '\tDatapoints: ', max_t)
        # Not enough feature data
        
        for i, f in enumerate(mts):
            if(len(f) < max_t):
                oldf = len(f)
                told = np.linspace(0, 1, len(f))
                tnew = np.linspace(0, 1, max_t)
                f = np.interp(tnew, told, f)                
            fmts[i, :] = f
        umts[u] = fmts
    return umts


def constructMTS(users, features, scale=False):     
    umts, tsum = extractMTS(users, features)
    maxmin = maxMinFeatures(umts)
    
    if scale:
        fbounds = computeFBounds(maxmin, features)
        print("Adjusting feature bounds")
        for u in umts:
            mts = umts[u]
            for i, f in enumerate(mts):
                min_v, max_v = fbounds[features[i]]
                mts[i] = normalize(f, min_v, max_v)
                
    umts = resampleFeatureMTS(umts, features)
    return umts, tsum, list(umts.keys()), maxmin