# Secure Contact Discovery Demo

Once an application has been downloaded, it typically asks for permission to read the entire address book on the client's device and sends that information to a server so that each contact may be searched up. Following that, the contacts that really have the program loaded are returned, and the app is aware that you may message them.

Clients may utilize Contact Discovery to find out which of their contacts have downloaded the application, but it keeps their contact information private from the service provider or other parties that might compromise the service.
It is accomplished by hashing each contact from the client's phonebook using a hashing method such as `md5` or `SHA`, storing the results in a table, and then extracting each one to compare with the server's hash list of people who have registered. It can be made more secure by employing a "password," although brute force attacks are still possible.

The possible solution to make it much more secure is to run a contact discovery service in a secure SGX enclave.

# Protocol
## Description
The protocol is simple to comprehend:

1. First, The client compiles a list of identifiers for all the people it wants to look up like usernames, emails, phone numbers and hashes each identifier with a pre-agreed-upon appropriate hashing function (SHA is probably a good choice).
2. Generally all the other registered user's identifier is already stored in hash in server, but we will upload here manually to learn better
3. To look for the people using the same application in their contact, they try to search for the identifier's hash using prefix by providing first N characters (selectable by the client, but usually 4+ bits) and sends to server
4. The server replies with a hash (around 20 characters) that it knows about and that begin with the characters the client sent.
5. The client then compares each less-truncated hash with the original, and, if all the characters match, it can be reasonably sure that the server knows the identifier of the user the client sent.

NOTE: The protocol for `Confidential Contact Discovery` is exact same, but it take place inside the secure enclave. So let's check it.

## Why is it secure
The purpose of the aforementioned protocol is to prevent the client from sending the server the complete identity since there are so few potential identifiers that a hash really doesn't offer any privacy; it's merely a handy technique to divide the keyspace. After all the hashing, this is roughly equivalent to wanting to know if the server is aware of the email address "mostakim@t-systems-mms.com" and sending "mos" in order to have the server respond with "mostakim@t-systems-mms.com," at which point you can be reasonably certain the server is aware of it.

Though the server cannot tell if you intended "mostakim.mullick@t-systems.com" or "mostakim.mullick@mailbox.tu-dresden.de" because you just sent "mos." Your privacy is protected as a result, and the contact finding process continues as usual.

## Issues to consider
The lengths that the client and server send must take certain factors into account. The client obtains less data but also has less privacy the longer the hash it transmits. The client presumably does not want to set a hash prefix that is so broad that it receives 100 hashes per contact, but the server will likely want to impose a minimum length to prevent DoS attacks by users asking for every hash starting with a single character.

Although it is less crucial because the server doesn't care as much about obscuring which users are using the service, the server could wish to weaken its reply truncation length as well. That will depend on the service's user base and the server's comfort level with providing lengthy hashes.

# About Server
Go was used to write the server solution that is being offered, mostly for speed and deployment simplicity. It's really straightforward; it utilizes an HTTP API to connect to the outside world and SQLite to store and query the list of hashes. This is how it functions:

## Prerequisites

To have the necessary software installed, a `bash` shell script to verify this, and install what is missing. Run:

```bash
chmod +x check_prerequisites.sh
./check_prerequisites.sh
```
to automatically perform the following actions:

1. Install or update [golang go1.18.4](https://linuxhint.com/install-go-ubuntu-2/) on Ubuntu
2. Install [EGo v1.0.0](https://github.com/edgelesssys/ego#install-the-deb-package) an open-source SDK that enables to develop your own confidential apps in the Go programming language.


## Building and execution SimpleContactDiscovey
Create `go.mod` file on Go version 1.14 or later:
```bash
go mod init git.t-systems-mms.com/projects/CONFCOM/repos/securecontactdiscovery

go get github.com/docopt/docopt-go
go get github.com/gorilla/mux
go get github.com/mattn/go-sqlite3@v1.14.14 

```
To install and run the server, just do the following:

Building binary file:
```bash
cd SimpleContactDiscovey/
go build .
```
Run SimpleContactDiscovey demo :
```bash
./SimpleContactDiscovey [options] <api_password>

Options:
  -d --database=<filename>  The filename of the database file [default: contacts.sqlite3]
  -m --prefix-length=<num>  The minimum prefix length to accept [default: 4]
  -s --hash-length=<num>    The length of the hash to return [default: 20]
  -p --port=<port>          The port to listen to [default: 8080]
  -h --help                 Show this screen
  --version                 Show version`

```
NOTE : set `api_password` inside `main.go` file. [default: abcd1234]

## Make it CONFIDENTIAL using EGo :
build binary file using: 
```bash
cd ConfidentialContactDiscovery/
ego-go build .
```
Create the keys and enclave: 
```bash
ego sign ./ConfidentialContactDiscovery
```
Run ConfidentialContactDiscovery demo: 
```bash
ego run ./ConfidentialContactDiscovery <api_password>
```

NOTE : If get similar error (`ERROR: failed to open Intel SGX device
This machine doesn't support SGX`). Run in simulation mode:
```bash
OE_SIMULATION=1 ego run ./ConfidentialContactDiscovery <api_password>
```

This will start the server on port 8080. The server has two endpoints, an authenticated one for adding and deleting hashes, and an unauthenticated one to look them up. Here they are: 

### Adding a hash to table: 
```bash
http POST "http://:<api_password>@localhost:<port>/hashes/<hash>/"
```

### Deleting a hash from table:
```bash
http DELETE "http://:<api_password>@localhost:<port>/hashes/<hash>/"
```

### Looking up hashes: 
```bash
http POST "http://localhost:8080/contacts/" prefixes:='["<hash>"]'
```
NOTE : install `http` before running commands with  `sudo apt install httpie`
`default port: 8080,`
`default api_password: abcd1234`

### Get the hash of any usernames, emails, phone numbers, whatever the user identifiers for the service using `hashcontacts.go` file:
```bash
go run ./hashcontacts.go
```

