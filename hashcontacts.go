/*
author: mostakim.mullick@t-systems.com
company: T-Systems MMS
*/

package main

import (
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"os"
)

func GetMD5Hash(text string) string {
	hasher := md5.New()
	hasher.Write([]byte(text))
	return hex.EncodeToString(hasher.Sum(nil))
}

func main() {
	fmt.Print("Enter number: ")
	var input string
	_, err := fmt.Scanln(&input)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		return
	}

	var hashstring = GetMD5Hash(input)
	fmt.Println("hash:", hashstring)

}
