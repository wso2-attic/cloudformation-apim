# Synchronization Lock

This is a synchronization lock for synchronizing atomic deployment operations.

## How to run

1. Execute the below command build sync-lock:
   
   ````bash
   go build .
   ````

2. Execute the below command to acquire a lock:
   
   ````bash
   ./sync-lock [cluster-name] lock
   ````

   Example usage:
   
   ````bash
   ./sync-lock api-m lock
   Lock [api-m] acquired
   ````

3. Execute the below command to release a lock:
   
   ````bash
   ./sync-lock [cluster-name] unlock
   ````

   Example usage:
   
   ````bash
   ./sync-lock api-m unlock
   Lock [api-m] released
   ````