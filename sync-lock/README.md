# Synchronization Lock

This is a synchronization lock for synchronizing atomic deployment operations.

## How to run

1. Execute the below command build sync-lock:
   
   ````bash
   go build .
   ````

2. Execute the below command to acquire a lock:
   
   ````bash
   ./sync-lock [cluster-name] [lock|unlock]
   ````

   Example usage:
   
   ````bash
   ./sync-lock api-m lock
   
   ````

