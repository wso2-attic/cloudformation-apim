#!/bin/bash

/usr/local/bin/sync_lock apim lock

while [ $? != 0 ]; do
  sleep 30
  /usr/local/bin/sync_lock apim lock
done
