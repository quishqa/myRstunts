#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Jun 15 11:03:33 2019

@author: mario
"""

import os
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from mpl_toolkits.basemap import Basemap
from matplotlib.path import Path
import matplotlib.patches as patches
from matplotlib.patches import Polygon
from netCDF4 import Dataset

os.chdir('/home/mario/python_stunts/munich_wrf/')

inp1 = Dataset('./wrfinput_d01_5km', 'r')
inp2 = Dataset('./wrfinput_d02_1km', 'r')

xlat1 = inp1.variables['XLAT'][:]
xlon1 = inp1.variables['XLONG'][:]
xlat2 = inp2.variables['XLAT'][:]
xlon2 = inp2.variables['XLONG'][:]
inp1.close()
inp2.close()


cetesb_st = pd.DataFrame({'name': ['PIN', 'PDP', 'CC', 'JUND'],
                          'lat': [-23.5611, -23.5445, -23.5531, -23.1916],
                          'lon': [-46.7016, -46.6294, -46.6723, -46.8967]})


fig = plt.figure(figsize = (15, 8))

ax1 = plt.subplot2grid((2, 2), (0, 0))
ax2 = plt.subplot2grid((2, 2), (1, 0))
ax3 = plt.subplot2grid((2, 2), (0, 1), rowspan = 2)

m1 = Basemap(projection='ortho', lon_0 = -48, lat_0=-23, ax=ax1)
m1.drawmapboundary(fill_color='#afeeee')
m1.fillcontinents(color='beige',lake_color='#afeeee')
m1.drawcoastlines()
m1.drawcountries()

m2 = Basemap(llcrnrlon=xlon1.min(), llcrnrlat=xlat1.min(),
            urcrnrlon=xlon1.max(), urcrnrlat=xlat1.max(),
            projection='merc', resolution='i', ax = ax2)
m2.drawcoastlines()
m2.drawstates()
m2.drawcountries()
m2.drawmapboundary(fill_color='#afeeee')
m2.fillcontinents(color='beige', lake_color='#afeeee', zorder=1)
m2.drawparallels(np.arange(-90., 90., 0.75), linewidth=0.01, 
                labels=[1, 0, 0 ,0], fontsize=10, labelstyle='+/-')
m2.drawmeridians(np.arange(-180., 180., 1.5), linewidth=0.01, 
                labels=[0, 0, 0, 1], fontsize=10, labelstyle='+/-')
x, y = m2(cetesb_st['lon'].values, cetesb_st['lat'].values)
m2.scatter(x[3], y[3], marker='o', color='tab:red', s=40, zorder=2)
m2.readshapefile('rmsp/MunRM07','MunRM07')

m3 = Basemap(llcrnrlon=xlon2.min(), llcrnrlat=xlat2.min(),
            urcrnrlon=xlon2.max(), urcrnrlat=xlat2.max(),
            projection='merc', resolution='h', ax=ax3)
m3.drawcoastlines()
m3.drawstates()
m3.drawcountries()
m3.drawmapboundary(fill_color='#afeeee')
m3.fillcontinents(color='beige', lake_color='#afeeee', zorder=1)
m3.drawparallels(np.arange(-90., 90., 0.15), linewidth=0.01, 
                labels=[1, 0, 0 ,0], fontsize=10, labelstyle='+/-')
m3.drawmeridians(np.arange(-180., 180., 0.25), linewidth=0.01, 
                labels=[0, 0, 0, 1], fontsize=10, labelstyle='+/-')
x, y = m3(cetesb_st['lon'].values, cetesb_st['lat'].values)
m3.readshapefile('rmsp/MunRM07','MunRM07')
for info, shape in zip(m3.MunRM07_info, m3.MunRM07):
    if info['SIGLA'] == 'SAO':
        xs, ys = zip(*shape)
        m3.plot(xs, ys, marker=None, color='black',
               linewidth=1.5)
        
est = [1, 2, 3]
for label, xpt, ypt in zip(est, x, y):
    plt.text(xpt, ypt + 2000, label)
m3.scatter(x[:3], y[:3], marker='^', color='tab:red', s=40, zorder=2)

#Drawing the zoom rectangles:

lbx1, lby1 = m1(*m2(m2.xmin, m2.ymin, inverse= True))
ltx1, lty1 = m1(*m2(m2.xmin, m2.ymax, inverse= True))
rtx1, rty1 = m1(*m2(m2.xmax, m2.ymax, inverse= True))
rbx1, rby1 = m1(*m2(m2.xmax, m2.ymin, inverse= True))

verts1 = [
    (lbx1, lby1), # left, bottom
    (ltx1, lty1), # left, top
    (rtx1, rty1), # right, top
    (rbx1, rby1), # right, bottom
    (lbx1, lby1), # ignored
    ]

codes2 = [Path.MOVETO,
         Path.LINETO,
         Path.LINETO,
         Path.LINETO,
         Path.CLOSEPOLY,
         ]

path = Path(verts1, codes2)
patch = patches.PathPatch(path, facecolor='r', alpha = 0.4, lw=1)
ax1.add_patch(patch)

lbx2, lby2 = m2(*m3(m3.xmin, m3.ymin, inverse= True))
ltx2, lty2 = m2(*m3(m3.xmin, m3.ymax, inverse= True))
rtx2, rty2 = m2(*m3(m3.xmax, m3.ymax, inverse= True))
rbx2, rby2 = m2(*m3(m3.xmax, m3.ymin, inverse= True))

verts2 = [
    (lbx2, lby2), # left, bottom
    (ltx2, lty2), # left, top
    (rtx2, rty2), # right, top
    (rbx2, rby2), # right, bottom
    (lbx2, lby2), # ignored
    ]

codes2 = [Path.MOVETO,
         Path.LINETO,
         Path.LINETO,
         Path.LINETO,
         Path.CLOSEPOLY,
         ]

path = Path(verts2, codes2)
patch = patches.PathPatch(path, facecolor='r', alpha = 0.4, lw=1)
ax2.add_patch(patch)
plt.savefig('all_domains.png')
plt.show()
