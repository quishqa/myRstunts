#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jun 13 06:48:58 2019

@author: quishqa
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from netCDF4 import Dataset
from mpl_toolkits.basemap import Basemap

os.chdir('/home/quishqa/python_stunts/munich_plots')

inp1 = Dataset('./wrfinput_d01_5km', 'r')
inp2 = Dataset('./wrfinput_d02_1km', 'r')

xlat1 = inp1.variables['XLAT'][:]
xlon1 = inp1.variables['XLONG'][:]
xlat2 = inp2.variables['XLAT'][:]
xlon2 = inp2.variables['XLONG'][:]
hgt1 = inp1.variables['HGT'][:]
hgt2 = inp2.variables['HGT'][:]

inp1.close()
inp2.close()

cetesb_st = pd.DataFrame({'name': ['PIN', 'PDP', 'CC', 'JUND'],
                          'lat': [-23.5611, -23.5445, -23.5531, -23.1916],
                          'lon': [-46.7016, -46.6294, -46.6723, -46.8967]})


plt.subplot(111)
m = Basemap(llcrnrlon=xlon1.min(), llcrnrlat=xlat1.min(),
            urcrnrlon=xlon1.max(), urcrnrlat=xlat1.max(),
            projection='merc', resolution='h')
m.drawcoastlines()
m.drawstates()
m.drawcountries()
m.drawparallels(np.arange(-90., 90., 0.5), linewidth=0.01, 
                labels=[1, 0, 0 ,0], fontsize=10)
m.drawmeridians(np.arange(-180., 180., 1.25), linewidth=0.01, 
                labels=[0, 0, 0, 1], fontsize=10)
x, y = m(cetesb_st['lon'].values, cetesb_st['lat'].values)
m.scatter(x, y, marker='o', color='tab:orange', s=40)
m.readshapefile('rmsp/MunRM07','MunRM07')
plt.show()
