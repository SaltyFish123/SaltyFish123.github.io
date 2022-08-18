---
layout: post
title: Elementary UDP Sockets
date: 2022-08-16
categories: Computer_Network
tags: Socket
---

* TOC
{:toc}

There are some fundamental differences between applications written using TCP versus those that use UDP. These are because of the differences in the two transport layers: UDP is a connectionless, unreliable, datagram protocol, quite unlike the connection-oriented, reliable byte stream provided by TCP. Nevertheless, there are instances when it makes sense to use UDP instead of TCP, and we will go over this design choice in Section 22.4. Some popular applications are built using UDP: DNS, NFS, and SNMP, for example.

Figure 8.1 shows the function calls for a typical UDP client/server. The client does not establish a connection with the server. Instead, the client just sends a datagram to the server using the sendto function (described in the next section), which requires the address of the destination (the server) as a parameter. Similarly, the server does not accept a connection from a client. Instead, the server just calls the recvfrom function, which waits until data arrives from some client. recvfrom returns the protocol address of the client, along with the datagram, so the server can send a response to the correct client.

![figure 8.1](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/socket/figure_8_1.png?raw=true)

## recvfrom and sendto Functions

These two functions are similar to the standard read and write functions, but three additional arguments are required.

```c
#include <sys/socket.h>
ssize_t recvfrom(int sockfd, void * buff, size_t nbytes, int flags, struct sockaddr * from, socklen_t * addrlen );
ssize_t sendto(int sockfd, const void * buff, size_t nbytes, int flags, const struct sockaddr * to, socklen_t addrlen );
//Both return: number of bytes read or written if OK, 1 on error
```

The first three arguments, sockfd, buff, and nbytes, are identical to the first three arguments for read and write: descriptor, pointer to buffer to read into or write from, and number of bytes to read or write. We will describe the flags argument later when we discuss the recv, send, recvmsg , and sendmsg functions, since we do not need them with our simple UDP client/server example in this post. For now, we will always set the flags to 0.

The `to` argument for sendto is a socket address structure containing the protocol address (e.g., IP address and port number) of where the data is to be sent. The size of this socket address structure is specified by addrlen. The recvfrom function fills in the socket address structure pointed to by `from` with the protocol address of who sent the datagram. The number of bytes stored in this socket address structure is also returned to the caller in the integer pointed to by addrlen. Note that the final argument to sendto is an integer value, while the final argument to recvfrom is a pointer to an integer value (a value-result argument).

Both functions return the length of the data that was read or written as the value of the function. In the typical use of recvfrom , with a datagram protocol, the return value is the amount of user data in the datagram received.

## connect Function with UDP

Note that an asynchronous error is not returned on a UDP socket unless the socket has been connected. Indeed, we are able to call connect for a UDP socket. But this does not result in anything like a TCP connection: There is no three-way handshake. Instead, the kernel just checks for any immediate errors (e.g., an obviously unreachable destination), records the IP address and port number of the peer (from the socket address structure passed to connect), and returns immediately to the calling process.

With this capability, we must now distinguish between

* An unconnected UDP socket, the default when we create a UDP socket
* A connected UDP socket, the result of calling connect on a UDP socket

With a connected UDP socket, three things change, compared to the default unconnected UDP socket:

1. We can no longer specify the destination IP address and port for an output operation. That is, we do not use sendto, but write or send instead. Anything written to a connected UDP socket is automatically sent to the protocol address (e.g., IP address and port) specified by connect. Similar to TCP, we can call sendto for a connected UDP socket, but we cannot specify a destination address. **The fifth argument to sendto (the pointer to the socket address structure) must be a null pointer, and the sixth argument (the size of the socket address structure) should be 0**. The POSIX specification states that when the fifth argument is a null pointer, the sixth argument is ignored.
2. We do not need to use recvfrom to learn the sender of a datagram, but read, recv, or recvmsg instead. The only datagrams returned by the kernel for an input operation on a connected UDP socket are those arriving from the protocol address specified in `connect`. Datagrams destined to the connected UDP socket's local protocol address (e.g., IP address and port) but arriving from a protocol address other than the one to which the socket was connected are not passed to the connected socket. This limits a connected UDP socket to exchanging datagrams with one and only one peer. Technically, a connected UDP socket exchanges datagrams with only one IP address, because it is possible to connect to a multicast or broadcast address.
3. Asynchronous errors are returned to the process for connected UDP sockets. The corollary, as we previously described, is that unconnected UDP sockets do not receive asynchronous errors.

A process with a connected UDP socket can call connect again for that socket for one of two reasons:

* To specify a new IP address and port
* To unconnect the socket

The first case, specifying a new peer for a connected UDP socket, differs from the use of connect with a TCP socket: connect can be called only one time for a TCP socket. To unconnect a UDP socket, we call connect but set the family member of the socket address structure (sin_family for IPv4 or sin6_family for IPv6) to AF_UNSPEC. This might return an error of EAFNOSUPPORT, but that is acceptable. It is the process of calling connect on an already connected UDP socket that causes the socket to become unconnected.

### Performance

When an application calls sendto on an unconnected UDP socket, Berkeley-derived kernels temporarily connect the socket, send the datagram, and then unconnect the socket. Calling sendto for two datagrams on an unconnected UDP socket then involves the following six steps by the kernel:

* Connect the socket
* Output the first datagram
* Unconnect the socket
* Connect the socket
* Output the second datagram
* Unconnect the socket

Another consideration is the number of searches of the routing table. The first temporary connect searches the routing table for the destination IP address and saves (caches) that information. The second temporary connect notices that the destination address equals the destination of the cached routing table information (we are assuming two sendtos to the same destination) and we do not need to search the routing table again.

When the application knows it will be sending multiple datagrams to the same peer, it is more efficient to connect the socket explicitly. Calling connect and then calling write two times involves the following steps by the kernel:

* Connect the socket
* Output first datagram
* Output second datagram

## UDP Client/Server Example

I will write an simple UDP client/server example. The client will send text to the server via UDP while the server will print the text it receives and the IP address and port number of the coressponding sender. Note that the socket of type is SOCK_DGRAM if you want to transfer the datagram via UDP.

Here is the client code. You should pass the IP address of the server to the program. For example, run the program as `./client 127.0.0.1`.

```c
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <bits/socket.h>
#include <bits/sockaddr.h>
#include <netinet/in.h>
#include <errno.h>

void Write(int sockfd) {
    char buf[1024] = {0};
    ssize_t n;

    while (fgets(buf, sizeof(buf), stdin) != NULL) {
        n = write(sockfd, buf, strlen(buf) - 1);
        printf("n is %ld and size of buf is %ld\n", n, strlen(buf));
    }
}

void Sendto(int sockfd, const struct sockaddr* servaddr) {
    char buf[1024] = {0};
    ssize_t n;

    while (fgets(buf, sizeof(buf), stdin) != NULL) {
        n = sendto(sockfd, buf, strlen(buf) - 1, 0, servaddr, sizeof(*servaddr));
        printf("n is %ld and size of buf is %ld\n", n, strlen(buf));
    }
}

void UDPclient(const char* ip) {
    int sockfd;
    struct sockaddr_in servaddr;

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(8080);
    inet_pton(AF_INET, ip, &servaddr.sin_addr);

    // You can comment the following two line code, connect and Write.
    // And uncomment the Sendto function to send data to the server.
    connect(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr));
    Write(sockfd);

    //Sendto(sockfd, (struct sockaddr*)&servaddr);

    close(sockfd);
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        printf("The IP is required\n");
        exit(0);
    }
    //TCPclient(argv[1]);
    UDPclient(argv[1]);
    return 0;
}
```

As the code above shows, we can use `sendto` or `connect` combined with `write` to send data to the server. If we want to send data to the server multiple times, we have better to connect the server proctol address to the UDP socket, which can optimize the performance of our application.

The following code is the server code.

```c
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <bits/socket.h>
#include <bits/sockaddr.h>
#include <netinet/in.h>
#include <sys/select.h>
#include <poll.h>
#include <sys/epoll.h>
#include <sys/time.h>
#include <sys/types.h>
#include <errno.h>
#include <fcntl.h>

void UDPserver() {
    int sockfd;
    ssize_t n;
    char buf[1024] = {0}, ip[INET_ADDRSTRLEN] = {0};
    struct sockaddr_in servaddr, cliaddr;
    socklen_t clilen = sizeof(cliaddr);

    sockfd = socket(AF_INET, SOCK_DGRAM, 0);

    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    servaddr.sin_port = htons(8080);
    servaddr.sin_addr.s_addr = htonl(INADDR_ANY);

    bind(sockfd, (struct sockaddr*)&servaddr, sizeof(servaddr));
    for (;;) {
        if ((n = recvfrom(sockfd, buf, 1024, 0, (struct sockaddr*)&cliaddr, &clilen)) >= 0) {
            printf("\nThe client ip is %s and port number is %d. The size of buffer is %ld and the content of buffer is \n%s\n",
                    inet_ntop(AF_INET, &cliaddr.sin_addr, ip, INET_ADDRSTRLEN),
                    ntohs(cliaddr.sin_port),
                    n,
                    buf);
        }
    }
}

int main(int argc, char* argv[]) {
    UDPserver();
    return 0;
}
```

As the code above shows, the server receives the data from the UDP socket and the client IP address and port number are also returned by the pointer of the arguments.  
