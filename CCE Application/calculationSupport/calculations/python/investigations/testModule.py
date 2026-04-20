# -*- coding: utf-8 -*-
"""
Simple module to test the capability of calling a Python module 
from MATLAB
"""
import datetime as dt
import numpy as np

def timesTwo():
    result = 10 * 2
    return result


def timesN(x,multiplier):
    result = x * multiplier
    return result

def pythonError():
    myList = list('x','y',1)
    return myList

def logicalOperations(x,y, operation):
    if operation:
        result = x < y
    else:
        result = y < x
        
    return result

def logicalOperationsArray(x,y,operation):
    resultList = [];
    for xVal, yVal in zip(x,y):
        if operation:
            result = x < y
        else:
            result = y > x
        resultList.append(result)
    return resultList

def testDatetime(timestamp):
    x = matlab_to_datetime(timestamp)
    hours = 5
    hours_added = dt.timedelta(hours = hours)
    future_datetime = x + hours_added
    return future_datetime

def testDatetimeArray(timestamp):
    datetimeArray = []
    hours = 5
    hours_added = dt.timedelta(hours = hours)
  
    for dates in timestamp:
        x = matlab_to_datetime(dates)
        future_datetime = x + hours_added
        datetimeArray.append(future_datetime)
    return datetimeArray

def timesTwoArray(doubleArray):
    resultArray = []
    for x in doubleArray:
        result = x * 2
        resultArray.append(result)
    return resultArray

def checkString(myString):
    if myString == 'Option1':
        output = 'This is Option 1'
    elif myString == 'Option2':
        output = float("NAN")
    else:
        output = None
    return output
            

def checkStringArray(stringArray):
    outputArray = []
    for myString in stringArray:
        if myString == 'Option1':
            output = 'This is Option 1'
        elif myString == 'Option2':
            output = float("NAN")
        else:
            output = None
        outputArray.append(output)
    return outputArray

def matlab_to_datetime(matlab_datenum):
    """Convert matlab time to python time."""
    if matlab_datenum is None or np.isnan(matlab_datenum):
        return np.nan
    python_datetime = dt.datetime.fromordinal(int(matlab_datenum)) \
        + dt.timedelta(days=matlab_datenum % 1) - dt.timedelta(days=366)
    return python_datetime

def testStructs(x):
    x['S1']['Mary'] = float(300) 
    return x

def trainModel(x,y,fileName):
   myModel = np.polyfit(x, y, 3)
   np.save(fileName,myModel)
   
def predictValue(fileName,x):
   myModel = np.load(fileName)
   y = np.polynomial.polynomial.polyval(x,myModel)
   return y
    