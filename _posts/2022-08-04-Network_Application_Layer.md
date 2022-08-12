---
layout: post
title: OSI Model Application Layer
date: 2022-08-04
categories: Computer_Network
tags: Internet
---

* TOC
{:toc}

## Network Application Architecture

There are two predominant architectural paradigms used in the modern network applications: **the server-client architecture and the peer-to-peer architecture(P2P)**

## Tansport Protocol Service Dimension

We can broadly classify the possible services along four dimensions: **reliable data transfer, throughput, timing, and security**.

## HyperText Transfer Protocol (HTTP)

A Web page (also called a document) consists of objects. An object is simply a file -- such as an HTML file, a JPEG image, a Java applet, or a video clip -- that is addressable by a single URL. Most Web pages consist of a base HTML file and several referenced objects. For example, if a Web page contains HTML text and five JPEG images, then the Web page has six objects: the base HTML file plus the five images. The base HTML file references the other objects in the page with the objects' URLs.

## Round Trip Time (RTT)

The amount of time that elapses from when a client requests the base HTML file until the entire file is received by the client. To this end, we define the **round-trip time(RTT)**, which is the time it takes for a small packet to travel from client to server and then back to the client. The RTT includes **packet-propagation delays, packet-queuing delays** in intermediate routers and switches, and **packet-processing delays**.

## HTTP Message Format

There are two types of HTTP messages, one is the request message and the other is the response message.

For the request message, as the following image shows:

![HTTP request message format](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/HTTP_request_message.png?raw=true)

For the response message, as the following image shows:

![HTTP response message format](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/http_response_message.png?raw=true)

## Cookies

cookie technology has four components: (1) a cookie header line in the HTTP response message; (2) a cookie header line in the HTTP request message; (3) a cookie file kept on the user's end system and managed by the user's browser; and (4) a back-end database at the Web site.

![cookies](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/cookies.png?raw=true)

## Web Caching

A Web cache also called a **proxy server**, is a network entity that satisfies HTTP requests on the behalf of an origin Web server. The Web cache has its own disk storage and keeps copies of recently requested objects in this storage. Typically a Web cache is purchased and installed by an ISP.

Web caching has been deployment in the Internet for two reasons. First, a Web cache can substantially reduce the response time for a client request, particularly if the bottleneck bandwidth between the client and the origin server is much less than the bottleneck bandwidth between the client and the cache. If there is a high-speed connection between the client and the cache, as there often is, and if the cache has the requested object, then the cache will be able to deliver the object rapidly to the client. Second, as we will soon illustrate with an example, Web caches can substantially reduce traffic on an institution's access link to the Internet. By reducing traffic, the institution (for example, a company or a university) does not have to upgrade bandwidth as quickly, thereby reducing costs. Furthermore, Web caches can substantially reduce Web traffic in the Internet as a whole, thereby improving performance for all applications.

![proxy server](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/proxy_server.png?raw=true)

## FTP (File Transfer Protocol)

HTTP and FTP are both file transfer protocols and have many common characteristics; for example, they both run on top of TCP. However, the two application-layer protocols have some important differences. The most striking difference is that FTP uses two parallel TCP connections to transfer a file, **a control connection and a data connection**. The control connection is used for sending control information between the two hosts -- information such as user identification, password, commands to change remote directory, and commands to "put" and "get" files. The data connection is used to actually send a file. Because FTP uses a separate control connection, FTP is said to send its control information **out-of-band**. HTTP, as you recall, sends request and response header lines into the same TCP connection that carries the transferred file itself. For this reason, HTTP is said to send its control information **in-band**.

With FTP, the control connection remains open throughout the duration of the user session, but a new data connection is created for each file transferred within a session (that is, the data connections are non-persistent).

![FTP](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/FTP.png?raw=true)

## SMTP (Simple Mail Transfer Protocol)

We see from this diagram that it has three major components: user agents, mail servers, and the Simple Mail Transfer Protocol (SMTP). And SMTP uses the TCP connection.

It is important to observe that SMTP does not normally use **intermediate mail servers** for sending mail. They directly connect with each other.

![SMTP diagram](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/SMTP.png?raw=true)

When the mail server want to sent the email to the recipient user agent, it can use **POP3, IMAP or HTTP** to achieve it. **POP3** begins when the user agent (the client) opens a TCP connection to the mail server (the server) on port 110. With the TCP connection established, POP3 progresses through three phases: authorization, transaction, and update.

![email protocol](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/email_protocol.png?raw=true)

## DNS (Domain Name System)

All DNS query and reply messages are sent within the UDP datagrams to port 53.

There are three classes of DNS servers:

* **Root DNS servers**. In the Internet there are 13 root DNS servers (labeled A through M), most of which are located in North America. Although we have referred to each of the 13 root DNS servers as if it were a single server, each “server” is actually a network of replicated servers, for both security and reliability purposes. All together, there are 247 root servers as of fall 2011.
* **Top-level domain (TLD) servers**. These servers are responsible for top-level domains such as com, org, net, edu, and gov, and all of the country top-level domains such as uk, fr, ca, and jp. The company Verisign Global Registry Services maintains the TLD servers for the com top-level domain, and the company Educause maintains the TLD servers for the edu top-level domain.
* **Authoritative DNS servers**. Every organization with publicly accessible hosts (such as Web servers and mail servers) on the Internet must provide publicly accessible DNS records that map the names of those hosts to IP addresses. An organization's authoritative DNS server houses these DNS records. An organization can choose to implement its own authoritative DNS server to hold these records; alternatively, the organization can pay to have these records stored in an authoritative DNS server of some service provider. Most universities and large companies implement and maintain their own primary and secondary (backup) authoritative DNS server.

Suppose a DNS client wants to determine the IP address for the hostname **www.amazon.com**. To a first approximation, the following events will take place. The client first contacts one of the root servers, which returns IP addresses for TLD servers for the top-level domain com. The client then contacts one of these TLD servers, which returns the IP address of an authoritative server for amazon.com. Finally, the client contacts one of the authoritative servers for amazon.com, which returns the IP address for the hostname www.amazon.com.

There is another important type of DNS server called the **local DNS server**. A local DNS server does not strictly belong to the hierarchy of servers but is nevertheless central to the DNS architecture. Each ISP -- such as a university, an academic department, an employee's company, or a residential ISP -- has a local DNS server.

![DNS interaction](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/DNS_interaction.png?raw=true)

The DNS servers that together implement the DNS distributed database store **resource records (RRs)**, including RRs that provide hostname-to-IP address mappings.

DNS has two types of messages, query message and reply message. They have the same message format as the following iamge shows:

![DNS message format](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/assets/images/computer_network/DNS_message_format.png?raw=true)

## DHT (Distributed Hash Table)

In the P2P system, each peer will only hold a small subset of the totality of the (key, value) pairs. We'll allow any peer to query the distributed database with a particular key. The distributed database will then locate the peers that have the corresponding (key, value) pairs and return the key-value pairs to the querying peer. Any peer will also be allowed to insert new key-value pairs into the database. Such a distributed database is referred to as a **distributed hash table (DHT)**.
