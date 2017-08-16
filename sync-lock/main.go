package main

import (
	"fmt"
	"os"

	_ "github.com/go-sql-driver/mysql"
)

func main() {

	if len(os.Args) != 3 {
		printUsageAndExit()
	}

	clusterName := os.Args[1]
	action := os.Args[2]

	if !(action == "lock" || action == "unlock") {
		printUsageAndExit()
	}

	Init()
	value, err := GetValue(clusterName)
	checkErr(err)

	if value == "1" && action == "lock" {
		fmt.Println("Lock [" + clusterName + "] already acquired")
		os.Exit(1)
	}
	if value == "0" && action == "unlock" {
		fmt.Println("Lock [" + clusterName + "] already released")
		os.Exit(1)
	}
	if value == "" && action == "unlock" {
		fmt.Println("No lock found for cluster " + clusterName)
		os.Exit(1)
	}

	value = "0"
	if action == "lock" {
		value = "1"
	}
	err = SetValue(clusterName, value)
	checkErr(err)
	if err == nil {
		if action == "lock" {
			fmt.Println("Lock [" + clusterName + "] acquired")
		} else {
			fmt.Println("Lock [" + clusterName + "] released")
		}
		os.Exit(0)
	}
}

func printUsageAndExit() {
	fmt.Println("Usage: lock [cluster-name] [lock|unlock]")
	os.Exit(1)
}

func checkErr(err error) {
	if err != nil {
		panic(err)
	}
}
