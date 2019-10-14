# -*- coding: utf-8 -*-
"""
Created on Sun Sep  8 14:23:59 2019

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
#%% settings dict
############################################################

#declare dict
Settings  = {}

#path to data
Settings['DataDir'] = cjw.LocalDataDir() + '/ERA5/'

#time range
Settings['StartDate'] = datetime.datetime(2010, 1, 1)
Settings['EndDate']   = datetime.datetime(2010, 1, 15)

#latitude band
Settings['LatRange'] = np.asarray([-65.,-55.])

#height level
Settings['PrsLev'] = 10 #hPa

#output file
Settings['OutFile'] = 'era5.mat'

############################################################
#%% create results array
############################################################

NDays = int((Settings['EndDate'] - Settings['StartDate'])/datetime.timedelta(1)) #ugh
Results = np.full(NDays, np.nan)


############################################################
#%% do processing
############################################################

for iDay in range(0,NDays):
    
    print('Loading day ' + str(iDay+1) + ' of ' + str(NDays))
    
    #identify date
    ThisDay = Settings['StartDate'] + datetime.timedelta(iDay)

    #from this, identify ERA5 storage file
    YY = ThisDay.timetuple().tm_year
    DN = ThisDay.timetuple().tm_yday
    FilePath = (Settings['DataDir'] + '/' + str(YY).zfill(4)  
                + '/era5_' + str(YY).zfill(4) + 'd' + str(DN).zfill(3) + '.nc')
    del DN,YY,ThisDay

    #check if it exists, and if it does load it
    if not os.path.isfile(FilePath):
        continue
  
    #file exists. load it and start playing
    ERA5nc = netcdf.netcdf_file(FilePath, 'r',maskandscale=True)
    
    #pull out desired vars to a standard dict, then tidy
    ERA5 = {}
    ERA5['LnSP'] = np.asarray(ERA5nc.variables['lnsp'][:])
    ERA5['U']    = np.asarray(ERA5nc.variables['u'][:])
    ERA5['Prs']  = cjw.ecmwf_prs_137() #standard pressure axis
    ERA5['Lat']  = np.asarray(ERA5nc.variables['latitude'][:] )  
    del ERA5nc


    #find latitudes in range
    InRange = np.where(np.logical_and(ERA5['Lat']>=Settings['LatRange'][0], \
                                      ERA5['Lat']<=Settings['LatRange'][1]))
   
    
    #find closest height
    zidx = cjw.closest(ERA5['Prs'],Settings['PrsLev'])    
   
    #hence, pull out this region
    U = ERA5['U'][:,zidx,InRange,:]

    #average over all dimensions
    U = np.mean(U)
    
    
    #and store
    Results[iDay] = U


############################################################
#%% save to plot later
############################################################

#convert times
Settings['StartDate'] = cjw.time_py2mat(Settings['StartDate'])
Settings['EndDate']   = cjw.time_py2mat(Settings['EndDate'])

savemat(Settings['OutFile'],{'Results':Results, 'Settings':Settings})
print('Saved')