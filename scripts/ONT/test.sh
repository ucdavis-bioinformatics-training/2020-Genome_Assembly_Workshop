#!/bin/bash

finished=$1

if [ $finished == "YES" ]
then
  echo $finished
else
  echo "NO"
fi
