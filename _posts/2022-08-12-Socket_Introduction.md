---
layout: post
title: Socket Introduction
date: 2022-08-12
categories: Computer_Network
tags: Socket
---

* TOC
{:toc}

The **Internet Assigned Numbers Authority (IANA)** maintains a list of port number assignments. Assignments were once published as RFCs; RFC 1700 [Reynolds and Postel 1994] is the last in this series. RFC 3232 [Reynolds 2002] gives the location of the online database that replaced RFC 1700: http://www.iana.org/. The port numbers are divided into three ranges:

1. The well-known ports: 0 through 1023. These port numbers are controlled and assigned by the IANA. When possible, the same port is assigned to a given service for TCP, UDP, and SCTP. For example, port 80 is assigned for a Web server, for both TCP and UDP, even though all implementations currently use only TCP. At the time that port 80 was assigned, SCTP did not yet exist. New port assignments are made for all three protocols, and RFC 2960 states that all existing TCP port numbers should be valid for the same service using SCTP.
2. The registered ports: 1024 through 49151. These are not controlled by the IANA, but the IANA registers and lists the uses of these ports as a convenience to the community. When possible, the same port is assigned to a given service for both TCP and UDP. For example, ports 6000 through 6063 are assigned for an X Window server for both protocols, even though all implementations currently use only TCP. The upper limit of 49151 for these ports was introduced to allow a range for ephemeral ports; RFC 1700 [Reynolds and Postel 1994] lists the upper range as 65535.
3. The dynamic or private ports, 49152 through 65535. The IANA says nothing about these ports. These are what we call ephemeral ports. (The magic number 49152 is three-fourths of 65536.)

The two values that identify each endpoint, an IP address and a port number, are often called a **socket**. The **socket pair** for a TCP connection is the four-tuple that defines the two endpoints of the connection: the local IP address, local port, foreign IP address, and foreign port. A socket pair uniquely identifies every TCP connection on a network.

## Socket Address Structures

Most socket functions require a pointer to a socket address structure as an argument. Each supported protocol suite defines its own socket address structure. The names of these structures begin with `sockaddr_` and end with a unique suffix for each protocol suite.

An IPv4 socket address structure, commonly called an "Internet socket address structure," is named sockaddr_in and is defined by including the <netinet/in.h> header.

The reason the sin_addr member is a structure, and not just an in_addr_t , is historical. Earlier releases (4.2BSD) defined the in_addr structure as a union of various structures, to allow access to each of the 4 bytes and to both of the 16-bit values contained within the 32-bit IPv4 address. This was used with class A, B, and C addresses to fetch the appropriate bytes of the address. But with the advent of subnetting and then the disappearance of the various address classes with classless addressing (Section A.4), the need for the union disappeared. Most systems today have done away with the union and just define in_addr as a structure with a single in_addr_t member.

## Value-Result Arguments

We mentioned that when a socket address structure is passed to any socket function, it is always passed by reference. That is, a pointer to the structure is passed. The length of the structure is also passed as an argument. But the way in which the length is passed depends on which direction the structure is being passed: from the process to the kernel, or vice versa.

## Host and Network Byte Order

Consider a 16-bit integer that is made up of 2 bytes. There are two ways to store the two bytes in memory: with the low-order byte at the starting address, known as **little-endian** byte order, or with the high-order byte at the starting address, known as **big-endian** byte order. We show these two formats in Figure 3.9.

![figure 3.9](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/socket/figure_3_9.png?raw=true)

We must deal with these byte ordering differences as network programmers because networking protocols must specify a network byte order. For example, in a TCP segment, there is a 16-bit port number and a 32-bit IPv4 address. The sending protocol stack and the receiving protocol stack must agree on the order in which the bytes of these multibyte fields will be transmitted. The Internet protocols use big-endian byte ordering for these multibyte integers.

In C language, we can use the `struct` and `union` data structure to confirm whether the system is little-endian or big-endian. As the following code shows:

```c
#include <iostream>
#include <cstdlib>

using namespace std;

union bytes {
    short value;
    char value_arr[sizeof(short)];
};

template<size_t N>
void printBits(const bytes& byte, const unsigned char(&mask)[N]) {
    cout << "The bits are printed from the low address to the high address." << endl;
    cout << "The bits allocation of " << byte.value << " is ";
    for (auto i : byte.value_arr) {
        for (int j = 0; j < N; j++) {
            cout << ((i & mask[j]) > 0) ? 1 : 0;
        }
    }
    cout << endl;
}

const unsigned char MASK[] = {1, 2, 4, 8, 16, 32, 64, 128};

int main(int argc, char* argv[]) {
    bytes myByte;
    if (argc > 1) {
        myByte.value = atoi(argv[1]);
    }
    else {
        myByte.value = 0x1;
    }
    printBits(myByte, MASK);
    return 0;
}
```

For example, if the output is shown below, the least significant bit 1 is located at the lowest address. Then we can draw a conclusion that this OS is little-endian.

```bash
The bits are printed from the low address to the high address.
The bits allocation of 1 is 1000000000000000
```

Note that the network byte order is big endian while most of the host byte order is little endian. So when we send or receive the data, we need to convert the data from host byte order to network byte order or vice versa. Big endian means that the most significant byte located at the lowest address of RAM while little endian means that the least significant byte is located at the lowest address of RAM.

The following socket api is used to achieve this conversion.

```c
#include <arpa/inet.h>

// hton means host to network
// ntoh means network to host

uint32_t htonl(uint32_t hostlong);

uint16_t htons(uint16_t hostshort);

uint32_t ntohl(uint32_t netlong);

uint16_t ntohs(uint16_t netshort);
```

## Byte Manipulation Functions

There are two groups of functions that operate on multibyte fields, without interpreting the data, and without assuming that the data is a null-terminated C string. We need these types of functions when dealing with socket address structures because we need to manipulate fields such as IP addresses, which can contain bytes of 0, but are not C character strings. The functions beginning with str (for string), defined by including the <string.h> header, deal with null-terminated C character strings.

The first group of functions, whose names begin with b (for byte), are from 4.2BSD and are still provided by almost any system that supports the socket functions. The second group of functions, whose names begin with mem (for memory), are from the ANSI C standard and are provided with any system that supports an ANSI C library.

The first group of functions is shown below:

```c
#include <strings.h>

//Returns: 0 if equal, nonzero if unequal

void bzero(void * dest, size_t nbytes );
void bcopy(const void * src, void * dest, size_t nbytes );
int bcmp(const void * ptr1, const void * ptr2, size_t nbytes );
```

The second group of functions is shown below:

```c
#include <string.h>

//Returns: 0 if equal, <0 or >0 if unequal (see text)

void *memset(void * dest, int c, size_t len );
void *memcpy(void * dest, const void * src, size_t nbytes );
int memcmp(const void * ptr1, const void * ptr2, size_t nbytes );
```

## inet_aton , inet_addr , and inet_ntoa Functions

inet_aton, inet_ntoa, and inet_addr convert an IPv4 address from a dotted-decimal string (e.g., "206.168.112.96" ) to its 32-bit network byte ordered binary value. You will probably encounter these functions in lots of existing code.

```c
#include <arpa/inet.h>

//Returns: 1 if string was valid, 0 on error
int inet_aton(const char * strptr, struct in_addr * addrptr );

//Returns: 32-bit binary network byte ordered IPv4 address; INADDR_NONE if error
in_addr_t inet_addr(const char * strptr );

//Returns: pointer to dotted-decimal string
char *inet_ntoa(struct in_addr inaddr );
```

The first of these, inet_aton , converts the C character string pointed to by strptr into its 32-bit binary network byte ordered value, which is stored through the pointer addrptr. If successful, 1 is returned; otherwise, 0 is returned. An undocumented feature of inet_aton is that if addrptr is a null pointer, the function still performs its validation of the input string but does not store any result.

inet_addr does the same conversion, returning the 32-bit binary network byte ordered value as the return value. The problem with this function is that all $2^32$ possible binary values are valid IP addresses (0.0.0.0 through 255.255.255.255), but the function returns the constant INADDR_NONE (typically 32 one-bits) on an error. This means the dotted-decimal string 255.255.255.255 (the IPv4 limited broadcast address) cannot be handled by this function since its binary value appears to indicate failure of the function. A potential problem with inet_addr is that some man pages state that it returns 1 on an error, instead of INADDR_NONE. This can lead to problems, depending on the C compiler, when comparing the return value of the function (an unsigned value) to a negative constant. Today, inet_addr is deprecated and any new code should use inet_aton instead. Better still is to use the newer functions described in the next section, which handle both IPv4 and IPv6.

The inet_ntoa function converts a 32-bit binary network byte ordered IPv4 address into its corresponding dotted-decimal string. The string pointed to by the return value of the function resides in static memory. This means the function is not reentrant, which we will discuss in Section 11.18. Finally, notice that this function takes a structure as its argument, not a pointer to a structure.

## inet_pton and inet_ntop Functions

These two functions are new with IPv6 and work with both IPv4 and IPv6 addresses. We use these two functions throughout the text. The letters "p" and "n" stand for presentation and numeric. The presentation format for an address is often an ASCII string and the numeric format is the binary value that goes into a socket address structure.

```c
#include <arpa/inet.h>
int inet_pton(int family, const char * strptr, void * addrptr );
                //Returns: 1 if OK, 0 if input not a valid presentation format, -1 on error
const char *inet_ntop(int family, const void * addrptr, char * strptr, size_t len );
                //Returns: pointer to result if OK, NULL on error
```

The family argument for both functions is either AF_INET or AF_INET6. If family is not supported, both functions return an error with errno set to EAFNOSUPPORT.

For inet_pton, the first function tries to convert the string pointed to by strptr, storing the binary result through the pointer addrptr. If successful, the return value is 1. If the input string is not a valid presentation format for the specified family, 0 is returned.

inet_ntop does the reverse conversion, from numeric (addrptr) to presentation (strptr). The len argument is the size of the destination, to prevent the function from overflowing the caller's buffer. To help specify this size, the following two definitions are defined by including the <netinet/in.h> header:

```c
#define INET_ADDRSTRLEN   16  /* for IPv4 dotted-decimal */
#define INET6_ADDRSTRLEN  46  /* for IPv6 hex string */
```

If len is too small to hold the resulting presentation format, including the terminating null, a null pointer is returned and errno is set to ENOSPC.

The strptr argument to inet_ntop cannot be a null pointer. The caller must allocate memory for the destination and specify its size. On success, this pointer is the return value of the function.
