# -*- coding: utf-8 -*-
"""
Created on Fri Sep  6 11:05:48 2019

@author: cw785-admin
"""

#%% imports

from scipy.io import loadmat  
import numpy as np
import cjw
import matplotlib.pyplot as plt
plt.style.use('seaborn-whitegrid')

#%% load data
Data = loadmat('zm_ts.mat')
Data = Data['Results']
del loadmat

#define axes
Years     = range(2002,2019)
Altitudes = range(21,60,3)
Days      = range(1,366,1)

#select variable 1 (wave amplitude)
Data = Data[0,:,:,:]


#%% loop over and smooth years

for iYear in range(0,np.size(Years)):
  for iLevel in range (0,np.size(Altitudes)):
      Line = Data[iLevel,iYear,:]
      Data[iLevel,iYear,:] = cjw.boxcar(Line, 3)
      
del iYear,iLevel,Line
    
    
#%% plot each year

fig = plt.figure()
ax = plt.axes()

PlotLevel = 3


for iYear in range(0,np.size(Years)):
    
    Year = iYear+2002
    
    if Year == 2002:
        Colour = 'r'
    elif Year == 2010:
        Colour = 'g'
    else:
        Colour = 'b';
    
    Line = Data[PlotLevel,iYear,:]
    plt.plot(Days,Line,Colour)
    