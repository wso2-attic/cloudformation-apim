#!/bin/bash

echo "Waiting WSO2 AM to launch on 9443..."
while ! nc -z 0.0.0.0 9443; do
  sleep 1
done

echo "WSO2AM launched"
