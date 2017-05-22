# Synchronization Lock

This is a synchronization lock for synchronizing atomic deployment operations.

## How to run

1. Execute the below command to install the dependencies:
   
   ````bash
   npm install
   ````

2. Execute below command to acquire a lock and set a key value pair:
   
   ````bash
   npm start [key] [value]
   ````

   Example usage:
   
   ````bash
   npm start foo 1
   Acquiring lock...
   Lock acquired
   Record updated [foo] = 1
   Lock released
   ````

