#!/usr/bin/env python3

import sys
from sys import stdin, stderr
import os
import numpy as np
import csv

dataDir='diskgroup-breakout'

def detectOutliers(dataset):

  # dataset is a dict of lists
  outliers={}
  threshold=3
 
  for colNum in dataset:
    arrayData = dataset[colNum]

    mean_1 = np.mean(arrayData)
    std_1 =np.std(arrayData)

    #if std_1 < 0.1:
      #std_1 = 0.1

    # stddev of zero can occur in columns of zeros  - ie. no activity
    # the resulting error is "RuntimeWarning: invalid value encountered in double_scalars"
    # while it does not cause any harm, it is annoying

    if std_1 == 0:
      std_1 = 1

    for y in arrayData:

      z_score=0
      try:
        z_score= (y - mean_1)/std_1 
      except:
        z_score=0
        print('double_scalars:', file=sys.stderr)
        print('y: {}'.format(y), file=sys.stderr)
        print('mean_1: {}'.format(mean_1), file=sys.stderr)
        print('std_1: {}'.format(std_1), file=sys.stderr)

      if np.abs(z_score) > threshold:
        if not colNum in outliers.keys():
          outliers[colNum] = []
        outliers[colNum].append(y)

  return outliers

def getLines():
  lines=[]
  for line in stdin:
    lines.append(line.strip())

  return lines

def validateWorkingColumns(hdr,workingColumns):

  for colName in workingColumns:
    if colName not in hdr:
      print('{} is in invalid column name'.format(colName),file=sys.stderr)
      sys.exit(1)

def getHdr(lines):
  hdrLine=lines.pop(0)
  #return hdrLine.strip().upper().split(',')
  return hdrLine.strip().split(',')

def getColRefs(hdrLine):
  i = 0
  colRefs={}
  for col in hdrLine:
    colRefs[col] = i
    i += 1

  return colRefs

def getColSets(lines):
  pass

def cleanData(lines):

  cleanLines=[]
  
  for line in lines:
    a = line.split(',')

    #print('cleanData: {}'.format(a))

    if ('LINUX-RESTART' in a) \
        or ('# hostname' in a) \
        or ('timestamp' in a) \
        or ('hostname' in a):

      #print('a: {}'.format(a))
      #print('skipping line: {}'.format(line))

      continue

    cleanLines.append(line)

  return cleanLines
  

# get a dict of arrays for the data
# used as source to detect outliers per column
def getDataSet(columnRef,workingColumns,lines):
  colVals={}
  #print('column#: {}'.format(columnRef))
  for line in lines:
    a = line.split(',')

    for colName in workingColumns:
      #print('colName: {}'.format(colName))
      colNum = columnRef[colName]
      #print('colNum: {}'.format(colNum))
      #print('{} val {}'.format(colName,a[colNum]))
      if not colNum in colVals.keys():
        colVals[colNum] = []
      colVals[colNum].append(float(a[colNum]))

  return colVals

def removeOutliers(outliers, lines, removedLines):
  # outliers is a dict of lists
  # the key is the column number in the line
  # remove any line where any of the references values is an outlier
  for line in lines:
    a = line.split(',')
    
    for colNum in outliers:
      #print("colNum: {}   a[colNum]: {}".format(colNum, a[colNum]))

      if float(a[colNum]) in outliers[colNum]:
        removedLines.append(line)
        lines.remove(line)
        break

  return lines

def outlierRpt(outliers,workingColumns, colRefs):
  csvWriter = csv.writer(sys.stderr,delimiter=',')

  for i in range(0,len(outliers)):
    colName = workingColumns[i]
    print('colName: {}'.format(colName), file=sys.stderr)
    csvWriter.writerow(outliers[colRefs[colName]])

def removedRpt(removedLines):
  for line in removedLines:
    print('removed: {}'.format(line), file=sys.stderr)


def main():

  #print('args: {}'.format(sys.argv))
  if len(sys.argv) < 2:
    print('at least 1 parameters needed')
    print('outlier-remove.py col1 col2 ... < STDIN')
    sys.exit(1)

  filename = sys.argv[1]

  lines = getLines()
  hdr = getHdr(lines) # array
  lines = cleanData(lines)

  if sys.argv[1] == 'hdrs':
    hdrList='\n'.join(hdr)
    print(hdrList)
    sys.exit(0)

  colRefs = getColRefs(hdr)
  #print('colRefs: {}'.format(colRefs))

  workingColumns = []
  for column in sys.argv[1:]:
    workingColumns.append(column)

  validateWorkingColumns(hdr,workingColumns)

  #print('working columns: {}'.format(' - '.join(workingColumns)))
  #print("file: {} \n   hdr: {}".format(filename,hdr))
  #print('first line: {}'.format(lines[0]))


  # get the position in the data array for each column to check
  colNums = [ colRefs[i] for i in workingColumns ]
  #print('colNums: {}'.format(colNums))

  #sys.exit(0)

  # this is a dict of lists, where each list is all values for the column
  #colValues = getDataSet(colRefs[workingColumns[0]],lines)
  colValues = getDataSet(colRefs,workingColumns,lines)

  #print('colValues {}'.format(colValues))

  outliers = detectOutliers(colValues)

  removedLines=[]
  normalized = removeOutliers(outliers, lines, removedLines)

  #print('\nnormalized:')

  hdrList=','.join(hdr)
  print(hdrList)
  for line in normalized:
    print(line)

  #print('outliers:{}'.format(outliers))

  # reports to stderr
  #outlierRpt(outliers,workingColumns, colRefs)
  #removedRpt(removedLines)


  # create the new file in the 'clean-data' dir
  #createNewFile(

if __name__ == '__main__':
  main()


