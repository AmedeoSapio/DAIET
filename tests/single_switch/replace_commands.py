#!/usr/bin/python

import fileinput
import os

f1 = open('commands.txt','rw')
f2 = open('IDs.txt', 'r')
f2lines = f2.readlines();

index = 0
for line in f1:
	newLine = line.replace('XX',f2lines[index][:-1])
	if newLine != line:
		index = (index+1) % 12
	print(newLine[:-1])
