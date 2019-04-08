#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Apr  8 16:08:40 2019

@author: mario
"""

import os
import numpy as np
import matplotlib.pyplot as plt
from netCDF4 import Dataset
from mpl_toolkits.basemap import Basemap

os.chdir('/home/mario/SinG/input_munich/domains/25km_5km_domains')


wrfinput = Dataset('wrfinput_d02', 'r')

xlat = wrfinput.variables['XLAT'][:]
xlon = wrfinput.variables['XLONG'][:]
hgt = wrfinput.variables['HGT'][:]

wrfinput.close()

lon, lat = np.meshgrid(xlon[0, 0, :], xlat[0, :, 0])



plt.subplot(111)
m = Basemap(resolution='h', projection='merc',
            urcrnrlat=xlat.max(), llcrnrlat=xlat.min(),
            urcrnrlon=xlon.max(), llcrnrlon=xlon.min())
m.drawcoastlines()
m.drawcountries()
m.drawparallels(np.arange(-80.,95.,.25),labels=[1,0,0,0],fontsize=10,
                linewidth=0.01)
m.drawmeridians(np.arange(-180.,180.,.5),labels=[0,0,0,1],fontsize=10,
                linewidth=0.01)
xi, yi = m(lon, lat)
m.contourf(xi, yi, hgt[0,:,:])
m.readshapefile('./rmsp/MunRM07', 'rmsp')


plt.show()
