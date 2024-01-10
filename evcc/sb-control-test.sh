#!/bin/bash

# test script to check the parameter processing of evcc script message service
echo `date`  >> /home/mnagel/sonnenBatterie/test_ausgabe.log 2>&1
echo "Script: $0" >> /home/mnagel/sonnenBatterie/test_ausgabe.log 2>&1
echo "Alle Parameter: $@" >> /home/mnagel/sonnenBatterie/test_ausgabe.log 2>&1
echo "Anzahl: $#" >> /home/mnagel/sonnenBatterie/test_ausgabe.log 2>&1
echo "Alle *: $*" >> /home/mnagel/sonnenBatterie/test_ausgabe.log 2>&1
echo "1: $1" >> /home/mnagel/sonnenBatterie/test_ausgabe.log 2>&1
echo "2: $2" >> /home/mnagel/sonnenBatterie/test_ausgabe.log 2>&1
echo "====================================================" >> /home/mnagel/sonnenBatterie/test_ausgabe.log 
