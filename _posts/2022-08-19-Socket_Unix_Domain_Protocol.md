---
layout: post
title: Unix Domain Protocols
date: 2022-08-19
categories: Computer_Network
tags: Socket
---

* TOC
{:toc}

The Unix domain protocols are not an actual protocol suite, but a way of performing client/server communication on a single host using the same API that is used for clients and servers on different hosts. The Unix domain protocols are an alternative to the interprocess communication (IPC) methods.

Two types of sockets are provided in the Unix domain: stream sockets (similar to TCP) and datagram sockets (similar to UDP). Even though a raw socket is also provided, its semantics have never been documented, it is not used by any program that the authors are aware of, and it is not defined by POSIX.

Unix domain sockets are used for three reasons:

1. On Berkeley-derived implementations, Unix domain sockets are often twice as fast as a TCP socket when both peers are on the same host. One application takes advantage of this: the X Window System. When an X11 client starts and opens a connection to the X11 server, the client checks the value of the DISPLAY environment variable, which specifies the server's hostname, window, and screen. If the server is on the same host as the client, the client opens a Unix domain stream connection to the server; otherwise the client opens a TCP connection to the server.
2. Unix domain sockets are used when passing descriptors between processes on the same host.
3. Newer implementations of Unix domain sockets provide the client's credentials (user ID and group IDs) to the server, which can provide additional security checking.

The protocol addresses used to identify clients and servers in the Unix domain are pathnames within the normal filesystem. Recall that IPv4 uses a combination of 32-bit addresses and 16-bit port numbers for its protocol addresses, and IPv6 uses a combination of 128-bit addresses and 16-bit port numbers for its protocol addresses. These pathnames are not normal Unix files: We cannot read from or write to these files except from a program that has associated the pathname with a Unix domain socket.

## Unix Domain Socket Address Structure

The Unix domain socket address structure is defined as follows:

```c
#include <sys/un.h>

struct sockaddr_un
  {
    __SOCKADDR_COMMON (sun_);
    char sun_path[108];		/* Path name.  */
  };
```

The pathname stored in the sun_path array must be null-terminated. The macro SUN_LEN is provided and it takes a pointer to a sockaddr_un structure and returns the length of the structure, including the number of non-null bytes in the pathname. The unspecified address is indicated by a null string as the pathname, that is, a structure with sun_path[0] equal to 0. This is the Unix domain equivalent of the IPv4 INADDR_ANY constant and the IPv6 IN6ADDR_ANY_INIT constant.

The macro `__SOCKADDR_COMMON (sun_)` is equal to `sa_family_t sun_family` and this family is always `AF_LOCAL`.

## Socket Functions

There are several differences and restrictions in the socket functions when using Unix domain sockets. We list the POSIX requirements when applicable, and note that not all implementations are currently at this level.

1. The default file access permissions for a pathname created by bind should be 0777 (read, write, and execute by user, group, and other), modified by the current umask value.
2. The pathname associated with a Unix domain socket should be an absolute pathname, not a relative pathname. The reason to avoid the latter is that its resolution depends on the current working directory of the caller. That is, if the server binds a relative pathname, then the client must be in the same directory as the server (or must know this directory) for the client's call to either connect or sendto to succeed. POSIX says that binding a relative pathname to a Unix domain socket gives unpredictable results.
3. The pathname specified in a call to connect must be a pathname that is currently bound to an open Unix domain socket of the same type (stream or datagram). Errors occur if: (i) the pathname exists but is not a socket; (ii) the pathname exists and is a socket, but no open socket descriptor is associated with the pathname; or (iii) the pathname exists and is an open socket, but is of the wrong type (that is, a Unix domain stream socket cannot connect to a pathname associated with a Unix domain datagram socket, and vice versa).
4. The permission testing associated with the connect of a Unix domain socket is the same as if open had been called for write-only access to the pathname.
5. Unix domain stream sockets are similar to TCP sockets: They provide a byte stream interface to the process with no record boundaries.
6. If a call to connect for a Unix domain stream socket finds that the listening socket's queue is full, ECONNREFUSED is returned immediately. This differs from TCP: The TCP listener ignores an arriving SYN if the socket's queue is full, and the TCP connector retries by sending the SYN several times.
7. Unix domain datagram sockets are similar to UDP sockets: They provide an unreliable datagram service that preserves record boundaries.
8. Unlike UDP sockets, sending a datagram on an unbound Unix domain datagram socket does not bind a pathname to the socket. (Recall that sending a UDP datagram on an unbound UDP socket causes an ephemeral port to be bound to the socket.) This means the receiver of the datagram will be unable to send a reply unless the sender has bound a pathname to its socket. Similarly, unlike TCP and UDP, calling connect for a Unix domain datagram socket does not bind a pathname to the socket.

## Passing Descriptors

When we think of passing an open descriptor from one process to another, we normally think of either

* A child sharing all the open descriptors with the parent after a call to fork
* All descriptors normally remaining open when exec is called

In the first example, the process opens a descriptor, calls fork, and then the parent closes the descriptor, letting the child handle the descriptor. This passes an open descriptor from the parent to the child. But, we would also like the ability for the child to open a descriptor and pass it back to the parent.

Current Unix systems provide a way to pass any open descriptor from one process to any other process. That is, there is no need for the processes to be related, such as a parent and its child. The technique requires us to first establish a Unix domain socket between the two processes and then use sendmsg to send a special message across the Unix domain socket. This message is handled specially by the kernel, passing the open descriptor from the sender to the receiver.

The 4.4BSD technique allows multiple descriptors to be passed with a single sendmsg, whereas the SVR4 technique passes only a single descriptor at a time. All our examples pass one descriptor at a time. The steps involved in passing a descriptor between two processes are then as follows:

1. Create a Unix domain socket, either a stream socket or a datagram socket. If the goal is to fork a child and have the child open the descriptor and pass the descriptor back to the parent, the parent can call socketpair to create a stream pipe that can be used to exchange the descriptor. If the processes are unrelated, the server must create a Unix domain stream socket and bind a pathname to it, allowing the client to connect to that socket. The client can then send a request to the server to open some descriptor and the server can pass back the descriptor across the Unix domain socket. Alternately, a Unix domain datagram socket can also be used between the client and server, but there is little advantage in doing this, and the possibility exists for a datagram to be discarded. We will use a stream socket between the client and server in an example presented later in this section.
2. One process opens a descriptor by calling any of the Unix functions that returns a descriptor: open, pipe, mkfifo, socket, or accept, for example. Any type of descriptor can be passed from one process to another, which is why we call the technique "descriptor passing" and not "file descriptor passing."
3. The sending process builds a msghdr structure containing the descriptor to be passed. POSIX specifies that the descriptor be sent as ancillary data (the msg_control member of the msghdr structure), but older implementations use the msg_accrights member. The sending process calls sendmsg to send the descriptor across the Unix domain socket from Step 1. At this point, we say that the descriptor is "in flight." Even if the sending process closes the descriptor after calling sendmsg , but before the receiving process calls recvmsg (in the next step), the descriptor remains open for the receiving process. Sending a descriptor increments the descriptor's reference count by one.
4. The receiving process calls recvmsg to receive the descriptor on the Unix domain socket from Step 1. It is normal for the descriptor number in the receiving process to differ from the descriptor number in the sending process. Passing a descriptor is not passing a descriptor number, but involves creating a new descriptor in the receiving process that refers to the same file table entry within the kernel as the descriptor that was sent by the sending process.

The client and server must have some application protocol so that the receiver of the descriptor knows when to expect it. If the receiver calls recvmsg without allocating room to receive the descriptor, and a descriptor was passed and is ready to be read, the descriptor that was being passed is closed. Also, the MSG_PEEK flag should be avoided with recvmsg if a descriptor is expected, as the result is unpredictable.
