# -*- coding: utf-8 -*-
"""
Created on Mon Sep  9 11:12:49 2019

@author: cw785-admin
"""

############################################################
#%% imports
############################################################

import cjw
import datetime
from scipy.io import netcdf,savemat
import numpy as np
import os

############################################################
#%% setup Matlab, with access to my function library
############################################################

import matlab.engine
ML = matlab.engine.start_matlab()
paths = ML.genpath(r'C:\Users\cw785-admin\Dropbox\Code\matlabfunctions')
ML.addpath(paths,nargout=0)
del paths


############################################################
#%% settings dict
############################################################

#declare dict
Settings  = {}

#path to data
Settings['DataDir'] = cjw.LocalDataDir() + '/ERA5/'

#time range
Settings['StartDate'] = datetime.datetime(2002, 8,  1)
Settings['EndDate']   = datetime.datetime(2002, 8, 30)

#latitude and longitude scales
Settings['LatScale'] = np.asarray(range( -90, -30,1))
Settings['LonScale'] = np.asarray(range(-180, 180,1))


#height level
Settings['Altitudes'] =  np.asarray(range(20,60,5))

#output file
Settings['OutFile'] = 'maps.mat'

############################################################
#%% create results arrays
############################################################

NDays = int((Settings['EndDate'] - Settings['StartDate'])/datetime.timedelta(1)) #ugh
Results = np.full([NDays,np.size(Settings['LonScale']),np.size(Settings['LatScale']),np.size(Settings['Altitudes'])], np.nan)


############################################################
#%% loop over data
############################################################