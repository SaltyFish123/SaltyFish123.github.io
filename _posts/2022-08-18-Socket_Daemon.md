---
layout: post
title: Daemon Processes and the inetd Superserver
date: 2022-08-18
categories: Computer_Network
tags: Socket
---

* TOC
{:toc}

A daemon is a process that runs in the background and is not associated with a controlling terminal. Unix systems typically have many processes that are daemons (on the order of 20 to 50), running in the background, performing different administrative tasks. The lack of a controlling terminal is typically a side effect of being started by a system initialization script (e.g., at boot-time). But if a daemon is started by a user typing to a shell prompt, it is important for the daemon to disassociate itself from the controlling terminal to avoid any unwanted interraction with job control, terminal session management, or simply to avoid unexpected output to the terminal from the daemon as it runs in the background.

Since a daemon does not have a controlling terminal, it needs some way to output messages when something happens, either normal informational messages or emergency messages that need to be handled by an administrator. The syslog function is the standard way to output these messages, and it sends the messages to the syslogd daemon.

## 'syslogd' daemon

Unix systems normally start a daemon named syslogd from one of the system initializations scripts, and it runs as long as the system is up. Berkeley-derived implementations of syslogd perform the following actions on startup:

1. The configuration file, normally /etc/syslog.conf, is read, specifying what to do with each type of log message that the daemon can receive. These messages can be appended to a file (a special case of which is the file /dev/console , which writes the message to the console), written to a specific user (if that user is logged in), or forwarded to the syslogd daemon on another host.
2. A Unix domain socket is created and bound to the pathname /var/run/log (/dev/log on some systems).
3. A UDP socket is created and bound to port 514 (the syslog service).
4. The pathname /dev/klog is opened. Any error messages from within the kernel appear as input on this device.

The syslogd daemon runs in an infinite loop that calls select , waiting for any one of its three descriptors (from Steps 2, 3, and 4) to be readable; it reads the log message and does what the configuration file says to do with that message. If the daemon receives the SIGHUP signal, it rereads its configuration file.

## syslog Function

Since a daemon does not have a controlling terminal, it cannot just fprintf to stderr. The common technique for logging messages from a daemon is to call the syslog function.

```c
#include <syslog.h>
void syslog(int priority, const char * message, ... );
void openlog(const char *ident, int options, int facility );
void closelog(void);
```

The priority argument is a combination of a level and a facility. Additional detail on the priority may be found in RFC 3164. The message is like a format string to printf , with the addition of a %m specification, which is replaced with the error message corresponding to the current value of errno . A newline can appear at the end of the message, but is not mandatory.

openlog can be called before the first call to syslog and closelog can be called when the application is finished sending log messages. `ident` is a string that will be prepended to each log message by syslog. Often this is the program name.

Normally the Unix domain socket is not created when openlog is called. Instead, it is opened during the first call to syslog . The LOG_NDELAY option causes the socket to be created when openlog is called.
