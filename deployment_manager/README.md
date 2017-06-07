# Synchronization Lock

This is a synchronization lock for synchronizing atomic deployment operations.

## How to run

1. Execute the below command build sync-lock:

   ````bash
   go build .
   ````

2. Create a new MySQL database and note down the configuration, sync-lock will create a table in this database with the name 'lock' in the first run.

3. Provide the database configuration using following environment variables:

   ````bash
   export DB_NAME=lock_db
   export DB_HOSTNAME=127.0.0.1
   export DB_PORT=3306
   export DB_USERNAME=mysql
   export DB_PASSWORD=mysql
   ````

4. Execute the below command to acquire a lock:

   ````bash
   ./sync-lock [cluster-name] lock
   ````

   Example usage:

   ````bash
   ./sync-lock api-m lock
   Lock [api-m] acquired
   ````

5. Execute the below command to release a lock:

   ````bash
   ./sync-lock [cluster-name] unlock
   ````

   Example usage:

   ````bash
   ./sync-lock api-m unlock
   Lock [api-m] released
   ````

## License
Licensed under Apache 2.0
