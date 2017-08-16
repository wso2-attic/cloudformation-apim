#!/bin/bash

docker run -p 3306:3306 -e MYSQL_ROOT_PASSWORD=mysql -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_DATABASE=lock_db -d mysql:5.5