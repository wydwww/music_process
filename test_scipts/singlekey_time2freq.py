from scipy.io import wavfile
import lutorpy
import numpy as np
from os import listdir
from os.path import isfile, join
import re

mypath = '/home/arda/yiding/segments1'
allfile = [ f for f in listdir(mypath) if isfile(join(mypath,f)) ]
allfiles = []
for ff in allfile:
    a = re.match('[A-Z]?[0-9]?-.+',ff)
    if a:
        allfiles.append(a.group())

#for i in allfiles:
#    print i 
count = 1

for file_name in allfiles:
    fs, data = wavfile.read('/home/arda/yiding/segments1/'+file_name)
    for i in [0, 1]:
        a = data.T[i]
        p = np.fft.fft(a, fs)
        n = len(p)
        p = p[:n/2]
        p = abs(p)
        p = p/max(p)
        p = p[:4000]
        
        x = torch.fromNumpyArray(p)
        np.savetxt('/home/arda/yiding/singleData/' + file_name[:-4] + '_%d' % i + '.asc', x)
    print '%d/4000' % count
    count=count+1
