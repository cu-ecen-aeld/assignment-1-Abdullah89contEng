#!/bin/bash

if [ -z $1 ]||[ -z $2 ]||[ ! -d $1 ] 
then
    exit 1
fi
X=$(ls $1 | wc -w)
Y=$(grep $2 $1/*|wc -l)
echo The number of files are $X and the number of matching lines are $Y
