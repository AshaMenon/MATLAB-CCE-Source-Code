# -*- coding: utf-8 -*-
"""
Created on Fri Sep  2 12:19:09 2022

@author: john.atherfold
"""

import matplotlib.pyplot as plt

f, (ax1, ax2) = plt.subplots(2, 1, sharex=True)
ax1.plot(tappingData[tag])
ax2.plot(difference2)
ax2.plot(difference3)
ax2.plot(difference4)
ax2.plot(difference5)