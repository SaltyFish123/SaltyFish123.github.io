---
layout: post
title: Advanced I/O Functions
date: 2022-08-19
categories: Computer_Network
tags: Socket
---

* TOC
{:toc}

## Socket Timeouts

There are three ways to place a timeout on an I/O operation involving a socket:

1. Call alarm, which generates the SIGALRM signal when the specified time has expired. This involves signal handling, which can differ from one implementation to the next, and it may interfere with other existing calls to alarm in the process.
2. Block waiting for I/O in select, which has a time limit built-in, instead of blocking in a call to read or write.
3. Use the newer SO_RCVTIMEO and SO_SNDTIMEO socket options. The problem with this approach is that not all implementations support these two socket options.

## recv and send Functions

These two functions are similar to the standard read and write functions, but one additional argument is required.

```c
#include <sys/socket.h>
ssize_t recv(int sockfd, void * buff, size_t nbytes, int flags ) ;
ssize_t send(int sockfd, const void * buff, size_t nbytes, int flags ) ;
//Both return: number of bytes read or written if OK, 1 on error
```

The first three arguments to recv and send are the same as the first three arguments to read and write. The flags argument is either 0 or is formed by logically OR'ing one or more of the constants shown below:

| flags | Description | recv | send |
| :--- | :--- | :---: | :---: |
| MSG_DONTROUTE | Bypass routing table lookup |  | ∙ |
| MSG_DONTWAIT | Only this operation is nonblocking | ∙ | ∙ |
| MSG_OOB | Send or receive out-of-band data | ∙ | ∙ |
| MSG_PEBK | Peek at incoming message | ∙ |  |
| MSG_WAITALL | Wait for all the data | ∙ |  |

There are additional flags used by other protocols, but not TCP/IP.

## readv and writev Functions

These two functions are similar to read and write, but readv and writev let us read into or write from one or more buffers with a single function call. These operations are called scatter read (since the input data is scattered into multiple application buffers) and gather write (since multiple buffers are gathered for a single output operation). The second argument to both functions is a pointer to an array of `iovec` structures, which is defined by including the <sys/uio.h> header.

```c
#include <sys/uio.h>
ssize_t readv(int filedes, const struct iovec * iov, int iovcnt ) ;
ssize_t writev(int filedes, const struct iovec * iov, int iovcnt ) ;
//Both return: number of bytes read or written, 1 on error

struct iovec {
   void  *iov_base;    /* Starting address */
   size_t iov_len;     /* Number of bytes to transfer */
};
```

The readv() system call works just like read(2) except that multiple buffers are filled.

The writev() system call works just like write(2) except that multiple buffers are written out.

Buffers are processed in array order. This means that readv() completely fills iov[0] before proceeding to iov[1], and so on. (If there is insufficient data, then not all buffers pointed to by iov may be filled.) Similarly, writev() writes out the entire contents of iov[0] before proceeding to iov[1], and so on.

The data transfers performed by readv() and writev() are atomic: the data written by writev() is written as a single block that is not intermingled with output from writes in other processes (but see pipe(7) for an exception); analogously, readv() is guaranteed to read a contiguous block of data from the file, regardless of read operations performed in other threads or processes that have file descriptors referring to the same open file description (see open(2)).

There is some limit to the number of elements in the array of iovec structures that an implementation allows. Linux, for example, allows up to 1,024, while HP-UX has a limit of 2,100. POSIX requires that the constant IOV_MAX be defined by including the <sys/uio.h> header and that its value be at least 16. The readv and writev functions can be used with any descriptor, not just sockets. Also, writev is an atomic operation. For a record-based protocol such as UDP, one call to writev generates a single UDP datagram.

## recvmsg and sendmsg Functions

These two functions are the most general of all the I/O functions. Indeed, we could replace all calls to read, readv, recv, and recvfrom with calls to recvmsg. Similarly all calls to the various output functions could be replaced with calls to sendmsg. Both functions package most arguments into a msghdr structure.

```c
#include <sys/socket.h>
ssize_t recvmsg(int sockfd, struct msghdr * msg, int flags ) ;
ssize_t sendmsg(int sockfd, struct msghdr * msg, int flags ) ;
//Both return: number of bytes read or written if OK, 1 on error

struct msghdr {
   void         *msg_name;       /* Optional address */
   socklen_t     msg_namelen;    /* Size of address */
   struct iovec *msg_iov;        /* Scatter/gather array */
   size_t        msg_iovlen;     /* # elements in msg_iov */
   void         *msg_control;    /* Ancillary data, see below */
   size_t        msg_controllen; /* Ancillary data buffer len */
   int           msg_flags;      /* Flags (unused) */
};
```

## mmap and munmap

The synopsis of the mmap and munmap functions are as follows:

```c
#include <sys/mman.h>

void *mmap(void *addr, size_t length, int prot, int flags,
            int fd, off_t offset);
int munmap(void *addr, size_t length);
```

mmap() creates a new mapping in the virtual address space of the calling process. The starting address for the new mapping is specified in addr. The length argument specifies the length of the mapping (which must be greater than 0).

If addr is NULL, then the kernel chooses the (page-aligned) address at which to create the mapping; this is the most portable method of creating a new mapping. If addr is not NULL, then the kernel takes it as a hint about where to place the mapping; on Linux, the kernel will pick a nearby page boundary (but always above or equal to the value specified by /proc/sys/vm/mmap_min_addr) and attempt to create the mapping there. If another mapping already exists there, the kernel picks a new address that may or may not depend on the hint. The address of the new mapping is returned as the result of the call.

The contents of a file mapping, are initialized using length bytes starting at `offset` offset in the file (or other object) referred to by the file descriptor fd. `offset` must be a multiple of the page size as returned by sysconf(_SC_PAGE_SIZE).

After the mmap() call has returned, the file descriptor, `fd`, can be closed immediately without invalidating the mapping.

The prot argument describes the desired memory protection of the mapping (and must not conflict with the open mode of the  file). It is either PROT_NONE or the bitwise OR of one or more of the following flags:

* PROT_EXEC  Pages may be executed.
* PROT_READ  Pages may be read.
* PROT_WRITE Pages may be written.
* PROT_NONE  Pages may not be accessed.

The flags argument determines whether updates to the mapping are visible to other processes mapping the same region, and whether updates are carried through to the underlying file. This behavior is determined by including exactly one of the following values in flags: MAP_SHARED, MAP_SHARED_VALIDATE (since Linux 4.15) and MAP_PRIVAE.

Memory mapped by mmap() is preserved across fork(2), with the same attributes.

The munmap() system call deletes the mappings for the specified address range, and causes further references to addresses within the range to generate invalid memory references. The region is also automatically unmapped when the process is terminated. On the other hand, closing the file descriptor does not unmap the region.

The address addr must be a multiple of the page size (but length need not be). All pages containing a part of the indicated range are unmapped, and subsequent references to these pages will generate SIGSEGV. It is not an error if the indicated range does not contain any mapped pages.

## sendfile

sendfile - transfer data between file descriptors.

The synopsis of the sendfile function is as follows:

```c
#include <sys/sendfile.h>

ssize_t sendfile(int out_fd, int in_fd, off_t *offset, size_t count);
```

sendfile() copies data between one file descriptor and another. Because this copying is done within the kernel, sendfile() is more efficient than the combination of read(2) and write(2), which would require transferring data to and from user space.

in_fd should be a file descriptor opened for reading and out_fd should be a descriptor opened for writing.

If offset is not NULL, then it points to a variable holding the file offset from which sendfile() will start reading data from in_fd. When sendfile() returns, this variable will be set to the offset of the byte following the last byte that was read. If offset is not NULL, then sendfile() does not modify the file offset of in_fd; otherwise the file offset is adjusted to reflect the number of bytes read from in_fd.

If offset is NULL, then data will be read from in_fd starting at the file offset, and the file offset will be updated by the call.

count is the number of bytes to copy between the file descriptors.

The in_fd argument must correspond to a file which supports mmap(2)-like operations (i.e., it cannot be a socket).

If the transfer was successful, the number of bytes written to out_fd is returned. Note that a successful call to sendfile() may write fewer bytes than requested; the caller should be prepared to retry the call if there were unsent bytes.

On error, -1 is returned, and errno is set appropriately.

sendfile() will transfer at most 0x7ffff000 (2,147,479,552) bytes, returning the number of bytes actually transferred. (This is true on both 32-bit and 64-bit systems.)

## How Much Data Is Queued?

There are times when we want to see how much data is queued to be read on a socket, without reading the data. Three techniques are available:

1. If the goal is not to block in the kernel because we have something else to do when nothing is ready to be read, nonblocking I/O can be used.
2. If we want to examine the data but still leave it on the receive queue for some other part of our process to read, we can use the MSG_PEEK flag. If we want to do this, but we are not sure that something is ready to be read, we can use this flag with a nonblocking socket or combine this flag with the MSG_DONTWAIT flag. Be aware that the amount of data on the receive queue can change between two successive calls to recv for a stream socket. For example, assume we call recv for a TCP socket specifying a buffer length of 1,024 along with the MSG_PEEK flag, and the return value is 100. If we then call recv again, it is possible for more than 100 bytes to be returned (assuming we specify a buffer length greater than 100), because more data can be received by TCP between our two calls. In the case of a UDP socket with a datagram on the receive queue, if we call recvfrom specifying MSG_PEEK , followed by another call without specifying MSG_PEEK, the return values from both calls (the datagram size, its contents, and the sender's address) will be the same, even if more datagrams are added to the socket receive buffer between the two calls. (We are assuming, of course, that some other process is not sharing the same descriptor and reading from this socket at the same time.)
3. Some implementations support the FIONREAD command of ioctl. The third argument to ioctl is a pointer to an integer, and the value returned in that integer is the current number of bytes on the socket's receive queue. This value is the total number of bytes queued, which for a UDP socket includes all queued datagrams. Also be aware that the count returned for a UDP socket by Berkeley-derived implementations includes the space required for the socket address structure containing the sender's IP address and port for each datagram (16 bytes for IPv4; 24 bytes for IPv6).

## Sockets and Standard I/O

In all our examples so far, we have used what is sometimes called Unix I/O, the read and write functions and their variants ( recv, send, etc.). These functions work with descriptors and are normally implemented as system calls within the Unix kernel.

Another method of performing I/O is the standard I/O library. It is specified by the ANSI C standard and is intended to be portable to non-Unix systems that support ANSI C. The standard I/O library handles some of the details that we must worry about ourselves when using the Unix I/O functions, such as automatically buffering the input and output streams. Unfortunately, its handling of a stream's buffering can present a new set of problems we must worry about.

The term stream is used with the standard I/O library, as in "we open an input stream" or "we flush the output stream." Do not confuse this with the STREAMS subsystem.

The standard I/O library can be used with sockets, but there are a few items to consider:

* A standard I/O stream can be created from any descriptor by calling the fdopen function. Similarly, given a standard I/O stream, we can obtain the corresponding descriptor by calling `fileno`.
* TCP and UDP sockets are full-duplex. Standard I/O streams can also be full-duplex: we just open the stream with a type of r+ , which means read-write. But on such a stream, an output function cannot be followed by an input function without an intervening call to fflush, fseek, fsetpos, or rewind. Similarly, an input function cannot be followed by an output function without an intervening call to fseek, fsetpos, or rewind, unless the input function encounters an EOF. The problem with these latter three functions is that they all call lseek, which fails on a socket.
* The easiest way to handle this read-write problem is to open two standard I/O streams for a given socket: one for reading and one for writing.

There are three types of buffering performed by the standard I/O library:

1. Fully buffered means that I/O takes place only when the buffer is full, the process explicitly calls fflush, or the process terminates by calling exit. A common size for the standard I/O buffer is 8,192 bytes.
2. Line buffered means that I/O takes place when a newline is encountered, when the process calls fflush, or when the process terminates by calling exit.
3. Unbuffered means that I/O takes place each time a standard I/O output function is called.

Most Unix implementations of the standard I/O library use the following rules:

* Standard error is always unbuffered.
* Standard input and standard output are fully buffered, unless they refer to a terminal device, in which case, they are line buffered.
* All other streams are fully buffered unless they refer to a terminal device, in which case, they are line buffered.

Since a socket is not a terminal device, if we use the standard I/O library function with socket, the standard input and standard output is fullly buffered. So we have to call fflush between every standard input and standard output. In most cases, the best solution is to avoid using the standard I/O library altogether for sockets and operate on buffers instead of lines. Using standard I/O on sockets may make sense when the convenience of standard I/O streams outweighs the concerns about bugs due to buffering, but these are rare cases.
