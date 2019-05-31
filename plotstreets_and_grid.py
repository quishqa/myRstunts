#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu May 30 21:16:18 2019

@author: mario
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
from matplotlib.collections import LineCollection
from pyproj import Proj
from netCDF4 import Dataset

os.chdir('/home/mario/python_stunts/munich_wrf/')

file_street = '/home/mario/R_tests/SinG_input/PIN.traf.2018091104'

pin = pd.read_csv(file_street, sep=' ')
pin = pin[['i', 'xa', 'xb', 'ya', 'yb']]

# This comes from :
# https://ocefpaf.github.io/python4oceanographers/blog/2013/12/16/utm/

# Changing street coordinates system

myProj = Proj("+proj=utm +zone=23K, +south +ellps=WGS84 +datum=WGS84 +units=m +no_defs")
lon1, lat1 = myProj(pin['xa'].values,
                  pin['ya'].values,
                  inverse=True)
lon2, lat2 = myProj(pin['xb'].values,
                    pin['yb'].values,
                    inverse=True)
pin_df = pd.DataFrame({'i':pin['i'].values,
                       'xa':lon1, 'ya':lat1,
                       'xb':lon2, 'yb':lat2})

bdy_map = 100/110000
limits = [pin_df[['ya', 'yb']].values.min() - bdy_map,
           pin_df[['ya', 'yb']].values.max() + bdy_map,
           pin_df[['xa', 'xb']].values.min() - bdy_map,
           pin_df[['xa', 'xb']].values.max() + bdy_map]

# Opening wrfinput

inp = Dataset('wrfinput_d02', 'r')
xlat = inp.variables['XLAT'][:]
xlong = inp.variables['XLONG'][:]
t2 = inp.variables['T2'][:]

inp.close()

lats = [xlat.min(), xlat.max()]
lons = [xlong.min(), xlong.max()]

lat = xlat[0, :, 0]
lon = xlong[0, 0, :]
lo, la = np.meshgrid(lon, lat)

# Pinheiros cetesb

pin_est = [-23.5614, -46.7020]

# Beginning the plot

plt.subplot(111)
m = Basemap(projection='merc',
            urcrnrlat=limits[1], urcrnrlon=limits[3], 
            llcrnrlat=limits[0], llcrnrlon=limits[2])
m.drawcoastlines()
m.drawstates()
m.drawmeridians(lon, labels=[0,0,0,1],fontsize=10,
                linewidth=1, dashes=(None, None), size=12)
m.drawparallels(lat, labels=[1,0,0,0],fontsize=10,
                linewidth=1, dashes=(None, None), size=12)
#xi, yi = m(lo, la)
#m.pcolormesh(xi, yi,  t2[0, :,:], edgecolor='Black', linewidth= 0.25,
#             cmap='Blues', alpha = 0.2)
xa, ya = m(pin_df.xa.values, pin_df.ya.values)
xb, yb = m(pin_df.xb.values, pin_df.yb.values)
pts = np.c_[xa, ya, xb, yb].reshape(len(xa), 2, 2)
plt.gca().add_collection(LineCollection(pts, color = 'crimson', label = 'streets'))
xx, yy = m(pin_est[1], pin_est[0])
m.plot(xx, yy, marker="o", ls="", label="Pinheiros", color='yellow',
       markeredgecolor='Black', markersize=10)
plt.show()


# Get closest street to station 

streets = list(zip(lon1, lat1))
pinheiros=(pin_est[1], pin_est[0])

# TODO: Find closest street to the station 
# Get closest street to station 

streets = list(zip(lon1, lat1))
pinheiros=(pin_est[1], pin_est[0])

def dist_btwn_stations(p1, p2):
    '''This function calculates the distance between two stations given 
    their latitudes and longitudes'''
    dist = np.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)
    dist = dist * 111.2
    return(dist)


shortest_distance = 0
shortest_distance_coordinates = 0


for street in streets:
    distance = dist_btwn_stations(pinheiros, street)
    if distance < shortest_distance or shortest_distance is 0:
        shortest_distance = distance
        shortest_distance_coordinates = street

plt.subplot(111)
m = Basemap(projection='merc',
            urcrnrlat=limits[1], urcrnrlon=limits[3], 
            llcrnrlat=limits[0], llcrnrlon=limits[2])
m.drawcoastlines()
m.drawstates()
m.drawmeridians(lon, labels=[0,0,0,1],fontsize=10,
                linewidth=1, dashes=(None, None), size=12)
m.drawparallels(lat, labels=[1,0,0,0],fontsize=10,
                linewidth=1, dashes=(None, None), size=12)
#xi, yi = m(lo, la)
#m.pcolormesh(xi, yi,  t2[0, :,:], edgecolor='Black', linewidth= 0.25,
#             cmap='Blues', alpha = 0.2)
xa, ya = m(pin_df.xa.values[85:95], pin_df.ya.values[85:95])
xb, yb = m(pin_df.xb.values[85:95], pin_df.yb.values[85:95])
pts = np.c_[xa, ya, xb, yb].reshape(len(xa), 2, 2)
plt.gca().add_collection(LineCollection(pts, color = 'crimson', label = 'streets'))
xx, yy = m(pin_est[1], pin_est[0])
m.plot(xx, yy, marker="o", ls="", label="Pinheiros", color='yellow',
       markeredgecolor='Black', markersize=10)
plt.show()

test = pd.DataFrame({'i': pin_df['i'].values,
                     'coords': streets})
test['dist'] = [dist_btwn_stations(pinheiros, i) for i in test['coords'].values]

test[test['dist'] == test['dist'].min()]
