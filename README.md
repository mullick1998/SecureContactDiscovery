# Secure Contact Discovery Demo

Usually after downloading any application, the process involves seeking permission to read the whole address book on the client's device, sending it off to a server for each contact to be looked up. The contacts that turn out to actually have the application installed are then returned, and the application knows that you can send those people a message.

Contact Discovery allows clients to discover which of their contacts are registered users of the applicaton, but does not reveal their contacts to the service operator or any party that may compromise the service.

It is done by hasing the individual contacts from phonebook of the client using any hashing algorithm like `md5` or `SHA` and store them in the table and then extract each of them and comparing with the hash number of registered users in the server. It can be made more secure by using `password`, but still can be brute force.

The possible solution to make it much more secure is to run a contact discovery service in a secure SGX enclave.

# Protocol

## Description
Protocol is easy to understand:

1. First, The client compiles a list of identifiers for all the people it wants to look up like usernames, emails, phone numbers and hashes each identifier with a pre-agreed-upon appropriate hashing function (SHA is probably a good choice).
2. Generally all the other registered user's identifier is already stored in hash in server, but we will upload here manually to learn better
3. To look for the people using the same application in their contact, they try to search for the identifier's hash using prefix by providing first N characters (selectable by the client, but usually 4+ bits) and sends to server
4. The server replies with a hash (around 20 characters) that it knows about and that begin with the characters the client sent.
5. The client then compares each less-truncated hash with the original, and, if all the characters match, it can be reasonably sure that the server knows the identifier of the user the client sent.

NOTE: The protocol for `Confidential Contact Discovery` is exact same, but it take place inside the secure enclave. So let's check it.

## Why this is private
The point of the protocol above is that the client doesn't send the server the entire identifier (the space of all possible identifiers is so small that a hash provides pretty much no privacy, it's just a convenient way to segment the keyspace). After all the hashing, this is pretty much the equivalent of wanting to see if the server knows the email address "mostakim@t-systems-mms.com", and sending "mos" to have the server reply with "mostakim@t-systems-mms.com", at which point you're pretty sure the server knows about it.

However, since you only sent "mos", the server can't know whether you meant mostakim.mullick@t-systems.com" or "mostakim.mullick@mailbox.tu-dresden.de". Thus, your privacy is preserved, while the contact discovery process proceeds as usual.

## Considerations
There are a few considerations in the lengths that the client and server send. The longer the hash that the client sends, the less privacy it has, but also the less data it receives. The server will probably want to enforce a minimum length to avoid DoS attacks by people asking for every hash starting with a single character, but the client also probably does not want to specify a hash prefix so general that it receives 100 hashes per contact.

Conversely, the server may want to weak its reply truncation length as well (although it's less important, since the server doesn't care about hiding which users are on the service as much). That will depend on how many users are on the service and how comfortable the server is with sending long hashes.

# About Server
The provided server implementation is written in Go, mainly for speed and ease of deployment. It's pretty simple, it uses SQLite to store and query the list of hashes and an HTTP API for communicating with the outside world. Here's how that works:

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

