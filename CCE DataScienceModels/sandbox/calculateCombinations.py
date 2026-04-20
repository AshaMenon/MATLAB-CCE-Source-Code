# -*- coding: utf-8 -*-
"""
Created on Wed Apr 13 08:11:30 2022

@author: verushen.coopoo
"""

from itertools import product
import xlsxwriter

# initialize lists
basicity = [1.55, 1.75, 2.05]
temp = [1150, 1250, 1350]
PSO2 = [0.073, 0.15, 0.3]

a = [basicity, temp, PSO2]

combos = list(product(*a))

#%%

with xlsxwriter.Workbook('Thermo data combinations.xlsx') as workbook:
    worksheet = workbook.add_worksheet()

    for row_num, data in enumerate(combos):
        worksheet.write_row(row_num, 0, data)