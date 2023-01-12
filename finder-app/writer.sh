#!/bin/bash
if [ $# != 2 ]
then
    exit 1
fi

if ! touch $1 
then
    >&2 echo "can't create the file"
    exit 1
fi
echo $2 > $1
