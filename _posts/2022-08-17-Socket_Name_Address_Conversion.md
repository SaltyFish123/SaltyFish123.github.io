---
layout: post
title: Name and Address Conversions
date: 2022-08-17
categories: Computer_Network
tags: Socket
---

* TOC
{:toc}

## Domain Name System (DNS)

The file /etc/resolv.conf normally contains the IP addresses of the local name servers.

## gethostbyname Function

Host computers are normally known by human-readable names. All the examples that we have shown so far in this book have intentionally used IP addresses instead of names, so we know exactly what goes into the socket address structures for functions such as connect and sendto, and what is returned by functions such as accept and recvfrom. But, most applications should deal with names, not addresses. This is especially true as we move to IPv6, since IPv6 addresses (hex strings) are much longer than IPv4 dotted-decimal numbers.

The most basic function that looks up a hostname is gethostbyname. If successful, it returns a pointer to a hostent structure that contains all the IPv4 addresses for the host. However, it is limited in that it can only return IPv4 addresses. The POSIX specification cautions that gethostbyname may be withdrawn in a future version of the spec.

It is unlikely that gethostbyname implementations will actually disappear until the whole Internet is using IPv6, which will be far in the future. However, withdrawing the function from the POSIX specification is a way to assert that it should not be used in new code. We encourage the use of **getaddrinfo** in new programs.

```c
#include <netdb.h>
struct hostent *gethostbyname (const char * hostname);
//Returns: non-null pointer if OK, NULL on error with h_errno set

/* Description of data base entry for a single host.  */
struct hostent
{
  char *h_name;			/* Official name of host.  */
  char **h_aliases;		/* Alias list.  */
  int h_addrtype;		/* Host address type.  */
  int h_length;			/* Length of address.  */
  char **h_addr_list;		/* List of addresses from name server.  */
#ifdef __USE_MISC
# define	h_addr	h_addr_list[0] /* Address, for backward compatibility.*/
#endif
};

```

## gethostbyaddr Function

The function gethostbyaddr takes a binary IPv4 address and tries to find the hostname corresponding to that address. This is the reverse of gethostbyname.

```c
#include <netdb.h>
struct hostent *gethostbyaddr (const char * addr, socklen_t len, int family);
//Returns: non-null pointer if OK, NULL on error with h_errno set
```

This function returns a pointer to the same hostent structure that we described with gethostbyname. The field of interest in this structure is normally h_name, the canonical hostname.

## getservbyname and getservbyport Functions

Services, like hosts, are often known by names, too. If we refer to a service by its name in our code, instead of by its port number, and if the mapping from the name to port number is contained in a file (normally /etc/services), then if the port number changes, all we need to modify is one line in the /etc/services file instead of having to recompile the applications. The next function, getservbyname, looks up a service given its name.

```c
#include <netdb.h>
struct servent *getservbyname (const char * servname, const char * protoname);
//Returns: non-null pointer if OK, NULL on error

#include <netdb.h>
struct servent *getservbyport (int port, const char *protoname);
//Returns: non-null pointer if OK, NULL on error

/* Description of data base entry for a single service.  */
struct servent
{
  char *s_name;			/* Official service name.  */
  char **s_aliases;		/* Alias list.  */
  int s_port;			/* Port number.  */
  char *s_proto;		/* Protocol to use.  */
};
```

The service name servname must be specified. If a protocol is also specified (protoname is a non-null pointer), then the entry must also have a matching protocol. Some Internet services are provided using either TCP or UDP while others support only a single protocol (e.g., FTP requires TCP). If protoname is not specified and the service supports multiple protocols, it is implementation-dependent as to which port number is returned. Normally this does not matter, because services that support multiple protocols often use the same TCP and UDP port number, but this is not guaranteed.

The main field of interest in the servent structure is the port number. Since the port number is returned in network byte order, we must not call htons when storing this into a socket address structure.

## getaddrinfo Function

The gethostbyname and gethostbyaddr functions only support IPv4. The API for resolving IPv6 addresses went through several iterations; the final result is the getaddrinfo function. The getaddrinfo function handles both name-to-address and service-to-port translation, and returns sockaddr structures instead of a list of addresses. These sockaddr structures can then be used by the socket functions directly. In this way, the getaddrinfo function hides all the protocol dependencies in the library function, which is where they belong. The application deals only with the socket address structures that are filled in by getaddrinfo. This function is defined in the POSIX specification.

```c
#include <netdb.h>
int getaddrinfo (const char * hostname, const char * service,
                const struct addrinfo * hints, struct addrinfo ** result) ;
//Returns: 0 if OK, nonzero on error

/* Structure to contain information about address of a service provider.  */
struct addrinfo
{
  int ai_flags;			/* Input flags.  */
  int ai_family;		/* Protocol family for socket.  */
  int ai_socktype;		/* Socket type.  */
  int ai_protocol;		/* Protocol for socket.  */
  socklen_t ai_addrlen;		/* Length of socket address.  */
  struct sockaddr *ai_addr;	/* Socket address for socket.  */
  char *ai_canonname;		/* Canonical name for service location.  */
  struct addrinfo *ai_next;	/* Pointer to next in list.  */
};
```

The hostname is either a hostname or an address string (dotted-decimal for IPv4 or a hex string for IPv6). The service is either a service name or a decimal port number string. In linux, you can read the file /etc/hosts to get the mapping from hostname to address and read the file /etc/services to get the mapping from service name to port number.

hints is either a null pointer or a pointer to an addrinfo structure that the caller fills in with hints about the types of information the caller wants returned. For example, if the specified service is provided for both TCP and UDP (e.g., the domain service, which refers to a DNS server), the caller can set the ai_socktype member of the hints structure to SOCK_DGRAM. The only information returned will be for datagram sockets.

If the hints argument is a null pointer, the function assumes a value of 0 for ai_flags, ai_socktype, and ai_protocol, and a value of AF_UNSPEC for ai_family.

If the function returns success (0), the variable pointed to by the result argument is filled in with a pointer to a linked list of addrinfo structures, linked through the ai_next pointer. There are two ways that multiple structures can be returned:

1. If there are multiple addresses associated with the hostname, one structure is returned for each address that is usable with the requested address family (the ai_family hint, if specified).
2. If the service is provided for multiple socket types, one structure can be returned for each socket type, depending on the ai_socktype hint. (Note that most getaddrinfo implementations consider a port number string to be implemented only by the socket type requested in ai_socktype; if ai_socktype is not specified, an error is returned instead.

For example, if no hints are provided and if the domain service is looked up for a host with two IP addresses, four addrinfo structures are returned.

* One for the first IP address and a socket type of SOCK_STREAM
* One for the first IP address and a socket type of SOCK_DGRAM
* One for the second IP address and a socket type of SOCK_STREAM
* One for the second IP address and a socket type of SOCK_DGRAM

Despite the fact that getaddrinfo is "better" than the gethostbyname and getservbyname functions (it makes it easier to write protocol-independent code; one function handles both the hostname and the service; and all the returned information is dynamically allocated, not statically allocated), it is still not as easy to use as it could be. The problem is that we must allocate a hints structure, initialize it to 0, fill in the desired fields, call getaddrinfo, and then traverse a linked list trying each one. In the next sections, we will provide some simpler interfaces for the typical TCP and UDP clients and servers that we will write in the remainder of this text.

## freeaddrinfo Function

All the storage returned by getaddrinfo, the addrinfo structures, the ai_addr structures, and the ai_canonname string are obtained dynamically (e.g., from malloc ). This storage is returned by calling freeaddrinfo.

```c
#include <netdb.h>
void freeaddrinfo (struct addrinfo *ai);
```

## getnameinfo Function

This function is the complement of getaddrinfo: It takes a socket address and returns a character string describing the host and another character string describing the service. This function provides this information in a protocol-independent fashion; that is, the caller does not care what type of protocol address is contained in the socket address structure, as that detail is handled by the function.

```c
#include <netdb.h>
int getnameinfo (const struct sockaddr *sockaddr, socklen_t addrlen, char *host,
                socklen_t hostlen, char *serv, socklen_t servlen, int flags);
//Returns: 0 if OK, nonzero on error (see Figure 11.7)
```

sockaddr points to the socket address structure containing the protocol address to be converted into a human-readable string, and addrlen is the length of this structure. This structure and its length are normally returned by accept, recvfrom, getsockname, or getpeername.

The caller allocates space for the two human-readable strings: host and hostlen specify the host string, and serv and servlen specify the service string. If the caller does not want the host string returned, a hostlen of 0 is specified. Similarly, a servlen of 0 specifies not to return information on the service.

The difference between sock_ntop and getnameinfo is that the former does not involve the DNS and just returns a printable version of the IP address and port number. The latter normally tries to obtain a name for both the host and service.
