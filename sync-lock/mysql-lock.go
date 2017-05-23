package main

import (
	"database/sql"
	"errors"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

const createStmt = "CREATE TABLE IF NOT EXISTS `lock` (`key` VARCHAR(200) NOT NULL, `value` int(1) NOT NULL, PRIMARY KEY (`key`))"
const insertStmt = "INSERT INTO `lock`(`key`, `value`) VALUES (?, ?);"
const updateStmt = "UPDATE `lock` SET value = ? WHERE `key` = ?"
const selectStmt = "SELECT `value` FROM `lock` WHERE `key` = ? FOR UPDATE"
const lockStmt = "LOCK TABLES `lock` WRITE"
const unlockStmt = "UNLOCK TABLES;"

func getDbConnection() (*sql.DB, error) {
	var hostname = os.Getenv("DB_HOSTNAME")
	var username = os.Getenv("DB_USERNAME")
	var password = os.Getenv("DB_PASSWORD")
	var databaseName = os.Getenv("DB_NAME")

	if hostname == "" {
		err := errors.New("DB_HOSTNAME environment variable is not found")
		return nil, err
	}
	if username == "" {
		err := errors.New("DB_USERNAME environment variable is not found")
		return nil, err
	}
	if password == "" {
		err := errors.New("DB_PASSWORD environment variable is not found")
		return nil, err
	}
	if databaseName == "" {
		err := errors.New("DB_NAME environment variable is not found")
		return nil, err
	}

	db, err := sql.Open("mysql", username+":"+password+"@tcp("+hostname+":3306)/"+databaseName+"?charset=utf8")
	return db, err
}

// Init create table if not exist
func Init() error {
	db, err := getDbConnection()
	checkErr(err)

	stmt, err := db.Prepare(createStmt)
	if err != nil {
		return err
	}

	_, err = stmt.Exec()
	return err
}

// GetValue Read value using key from the database
func GetValue(key string) (string, error) {
	db, err := getDbConnection()
	checkErr(err)

	var value string
	db.QueryRow(selectStmt, key).Scan(&value)

	return value, err
}

// SetValue Persist key value pair
func SetValue(key string, value string) error {
	db, err := getDbConnection()
	checkErr(err)

	currentValue, err := GetValue(key)
	if err != nil {
		return err
	}

	if currentValue == "" {
		stmt, err := db.Prepare(insertStmt)
		if err != nil {
			return err
		}

		_, err = stmt.Exec(key, value)
	} else {
		stmt, err := db.Prepare(updateStmt)
		if err != nil {
			return err
		}

		_, err = stmt.Exec(value, key)
	}
	return err
}
