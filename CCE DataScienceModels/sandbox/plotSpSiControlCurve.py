# -*- coding: utf-8 -*-
"""
Created on Thu Mar 16 09:20:00 2023

@author: john.atherfold
"""
import matplotlib.pyplot as plt

plt.plot(lowRange['basicity'], lowRange['silica'])
plt.plot(highRange['basicity'], highRange['silica'])
plt.axhline(y=0, color='k', linestyle='-')
plt.ylabel('SpSi Change')
plt.xlabel('Basicity')