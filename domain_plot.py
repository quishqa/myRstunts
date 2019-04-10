#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Mon Apr  8 16:08:40 2019

@author: mario
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from netCDF4 import Dataset
from mpl_toolkits.basemap import Basemap

os.chdir('/home/mario/SinG/input_munich/domains/25km_5km_domains')


wrfi = Dataset('wrfinput_d02', 'r')
xlat = wrfi.variables['XLAT'][:]
xlon = wrfi.variables['XLONG'][:]
topo = wrfi.variables['HGT'][:]

wrfi.close()

lon, lat = np.meshgrid(xlon[0, 0, :], xlat[0, : , 0])


est_lat = [-23.5663, -23.5614, -23.5918]
est_lon = [-46.7374, -46.7020, -46.6607]
est_nam = ['USP', 'Pinehiros', 'Ibirapuera']

# Making the map

plt.subplot(111)
m = Basemap(resolution='h', projection='merc', 
            urcrnrlat=xlat.max(), urcrnrlon=xlon.max(),
            llcrnrlat=xlat.min(), llcrnrlon=xlon.min())
m.drawcoastlines()
m.drawcountries()
m.drawparallels(np.arange(-80.,95.,0.25),labels=[1,0,0,0],fontsize=10,
                linewidth=0.01)
m.drawmeridians(np.arange(-180.,180.,0.5),labels=[0,0,0,1],fontsize=10,
                linewidth=0.01)
xi, yi = m(lon , lat)
cs = m.contourf(xi, yi, topo[0, :, :])
cb = m.colorbar(cs)
xe, ye = m(est_lon, est_lat)
m.scatter(xe, ye,marker='o', color='tab:orange')

for label, xpt, ypt in zip(range(1,4), xe, ye):
    plt.text(xpt+1000, ypt+1000, label)
cb.ax.set_xlabel('[meters]')
plt.show()
cb.ax.set_xlabel('[meters]')
plt.show()
