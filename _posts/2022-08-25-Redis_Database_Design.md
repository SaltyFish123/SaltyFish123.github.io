---
layout: post
title: Redis Database Design
date: 2022-08-25
categories: NoSQL
tags: Redis
---

* TOC
{:toc}

## Redis Database Object

The declaration of Redis database representation `redisDb` is shown below:

```c
// src/server.h

/* Redis database representation. There are multiple databases identified
 * by integers from 0 (the default database) up to the max configured
 * database. The database number is the 'id' field in the structure. */
typedef struct redisDb {
    dict *dict;                 /* The keyspace for this DB */
    dict *expires;              /* Timeout of keys with a timeout set */
    dict *blocking_keys;        /* Keys with clients waiting for data (BLPOP)*/
    dict *ready_keys;           /* Blocked keys that received a PUSH */
    dict *watched_keys;         /* WATCHED keys for MULTI/EXEC CAS */
    int id;                     /* Database ID */
    long long avg_ttl;          /* Average TTL, just for stats */
    unsigned long expires_cursor; /* Cursor of the active expire cycle. */
    list *defrag_later;         /* List of key names to attempt to defrag one by one, gradually. */
} redisDb;
```

Redis can use the `SELECT` command to choose which database to be used. By default the index 0 database is used. So we can use `SELECT 1` to switch to another database. The number of database is decided by the `dbnum` of the `server` structure.  

The declarations of `client` and `redisServer` are both located at src/server.h. And both of them contain a member named `db` with data type `redisDb*`. `client.db` will point to one element of the `redisServer.db` array. And this element involved the `client.db` is the database that client is currently using.

For the `dict` member of the `redisDb` struct, it stores all the key-value pairs of current DB. For example, If we run the command `RPUSH mylist 1 2 3 5 4`, then the `dict` member of `redisDb` will add a key-value pair with key `mylist`(a `OBJ_STRING` data type object) and value(a `OBJ_LIST` data type object) consit of 1, 2, 3, 5 and 4 as we input. When we add a need data group to this DB, the dict will add one more key-value pair like `mylist`. Notice that the Redis objects of the same data type within different data structures like `dict` member within `redisDb` or `quicklist`, it may point to the same memory so that the data is not thread safe.

## Expires API

For the expire API, the definition located at src/db.c with the comment `Expires API` and at src/expire.c. In src/db.c, every time the operation of the database is taken, the command function will first call the method `expireIfNeeded` to check whether the key is expired. If it is expired, `deleteExpiredKeyAndPropagate` is called to delete the key-value pair from the `db->dict` and `db->expires`. This is the implementation of the lazy free of the expired key. In src/expire.c, the function `activeExpireCycle` is called to periodically to clean the expired key. It will call the fucntion `activeExpireCycleTryExpire` and then call `deleteExpiredKeyAndPropagate` to remove the expired key.

## Subscribe

The subscribe api is implemented in src/notify.c. The api provided to the rest of the Redis core is a simple function: `notifyKeyspaceEvent(char *event, robj *key, int dbid);`. This function is aften called when the redis command function is executed.

## RDB

The declaration is located at src/rdb.h and definition is located at src/rdb.c. The read/write of the rdb file is based on the `rio`, whose declatation/defination is located at `src/rio.h` / `src/rio.c`.

There are two commands can produce the RDB file, one is `SAVE` and the other is `BGSAVE`. `SAVE` will block the server process and save the rdb file while the `BGSAVE` will fork a subprocess to save the rdb file. The coressponding method is `rdbSaveBackground` and `rdbSave`.

The `rdbLoad` is used to load the rdb file from disk. It is called at the start up of the server. As the following code shows, if AOF is on, then redis server will prefer load the data from disk than rdb.

In `redisserver`, `dirty` records the times that the DB changes from the last save. `lastsave` records the timestamp that the last time of the rdbsave.

```c
// src/server.c

/* Function called at startup to load RDB or AOF file in memory. */
void loadDataFromDisk(void) {
    long long start = ustime();
    if (server.aof_state == AOF_ON) {
        if (loadAppendOnlyFile(server.aof_filename) == C_OK)
            serverLog(LL_NOTICE,"DB loaded from append only file: %.3f seconds",(float)(ustime()-start)/1000000);
    } else {
        rdbSaveInfo rsi = RDB_SAVE_INFO_INIT;
        errno = 0; /* Prevent a stale value from affecting error checking */
        if (rdbLoad(server.rdb_filename,&rsi,RDBFLAGS_NONE) == C_OK) {
            ......
        }
        ......
    }
    ......
}
```

The function `rdbSaveRio` is the implementation that `rdbSave` will use to save the database into the RDB format file.

We can use the `od -c dump.rdb` linux command to see what the rdb file stores. By default, we use the `redis-check-rdb` tool to check the rdb file, which is the builtin tool of redis.

The following reference shows more details about the redis rdb and redis persistence.

[Redis Persistence Demystified](http://oldblog.antirez.com/post/redis-persistence-demystified.html/)

[Redis RDB File Format](https://github.com/sripathikrishnan/redis-rdb-tools/wiki/Redis-RDB-Dump-File-Format)

### RIO

rio.c is a simple stream-oriented I/O abstraction that provides an interface to write code that can consume/produce data using different concrete input and output devices. For instance the same rdb.c code using the rio abstraction can be used to read and write the RDB format using in-memory buffers or files.

A rio object provides the following methods:

* read: read from stream.
* write: write to stream.
* tell: get the current offset.

It is also possible to set a `checksum` method that is used by rio.c in order to compute a checksum of the data written or read, or to query the rio object for the current checksum.

There are 4 types of the `rio` as the union `io` member shows. They are `buffer`, `file`, `conn` and `fd`. All of them has a coressponding `static const rio` variable which is used to initialize the rio variable. As the following code shows:

```c
// src/rio.c

static const rio rioBufferIO = {
    rioBufferRead,
    rioBufferWrite,
    rioBufferTell,
    rioBufferFlush,
    NULL,           /* update_checksum */
    0,              /* current checksum */
    0,              /* flags */
    0,              /* bytes read or written */
    0,              /* read/write chunk size */
    { { NULL, 0 } } /* union for io-specific vars */
};

void rioInitWithBuffer(rio *r, sds s) {
    *r = rioBufferIO;
    r->io.buffer.ptr = s;
    r->io.buffer.pos = 0;
}
```

### Connection

The connection is implemented in src/connection.h and src/connection.c. The connection module provides a lean abstraction of network connections to avoid direct socket and async event management across the Redis code base to avoid direct socket and async event management across the Redis code base. It does NOT provide advanced connection features commonly found in similar libraries such as complete in/out buffer management, throttling, etc. These functions remain in networking.c. The primary goal is to allow transparent handling of TCP and TLS based connections. To do so, connections have the following properties:

1. A connection may live before its corresponding socket exists. This allows various context and configuration setting to be handled before establishing the actual connection.
2. The caller may register/unregister logical read/write handlers to be called when the connection has data to read from/can accept writes. These logical handlers may or may not correspond to actual AE events, depending on the implementation (for TCP they are; for TLS they aren't).

## AOF

`AOF (Append Only File)`, is another redis persistence method besides `RDB`. AOF stores the write commands that the redis server exectued to recored the db state.

```c
// src/server.h

struct redisServer {
    ......
    sds aof_buf;      /* AOF buffer, written before entering the event loop */
    ......
};
```

As the above code shows, there is a variable `aof_buf` of the `redisServer`. It is used to store the commands that the redis server executed. The later command is catenated to the `aof_buf`.

When the server is going to stop an eventloop, it will call the method `flushAppendOnlyFile`. This method will write the AOF buffer on the disk and it finally will call the `write` system call to implement this utility. Notice that when a user call the `write` system cal to write some data from memory to file, os will store the data in a buffer and exactly write the data of the buffer to the file until the buffer is filled or timeout for effectiveness. So there is a risk that when the server is shutdown and the data in the buffer will be lost. In order to make sure of the security of the data, the os provides the system calls `fsync` and `fdatasync` to write the data of the buffer on the disk immediately.

`loadAppendOnlyFile` in src/aof.c is used to load the data from aof at the startup of redis server. It will create a fake client since in redis commands are always exectued in the context of a client so that in order to load the AOF we need to create a AOF fake client.

Since the size of the AOF will grow larger than larger, redis provide a method `rewriteAppendOnlyFileBackground` to rewrite the AOF. This is how rewriting of the append only file in background works:

1. The user calls `BGREWRITEAOF`
2. Redis calls this function, that forks():
  2a) the child rewrite the append only file in a temp file.
  2b) the parent accumulates differences in server.aof_rewrite_buf.
3. When the child finished '2a' exists.
4. The parent will trap the exit code, if it's OK, will append the data accumulated into server.aof_rewrite_buf into the temp file, and finally will rename(2) the temp file in the actual file name. The the new file is reopened as the new append only file. Profit!

## Event

In Redis, it use the **reactor pattern** to handle the tasks. There are two kinds of events, one is **file event** and the other is **time event**. The based implementation is located at src/ae.h and src/ae.c. The declarations of them is as the following code shows:

```c
// src/ae.h

/* File event structure */
typedef struct aeFileEvent {
    int mask; /* one of AE_(READABLE|WRITABLE|BARRIER) */
    aeFileProc *rfileProc;
    aeFileProc *wfileProc;
    void *clientData;
} aeFileEvent;

/* Time event structure */
typedef struct aeTimeEvent {
    long long id; /* time event identifier. */
    monotime when;
    aeTimeProc *timeProc;
    aeEventFinalizerProc *finalizerProc;
    void *clientData;
    struct aeTimeEvent *prev;
    struct aeTimeEvent *next;
    int refcount; /* refcount to prevent timer events from being
  		   * freed in recursive time event calls. */
} aeTimeEvent;
```

Note that Redis will choose the best multiplexing supported by the running OS. As the following code shows:

```c
// src/ae.c

/* Include the best multiplexing layer supported by this system.
 * The following should be ordered by performances, descending. */
#ifdef HAVE_EVPORT
#include "ae_evport.c"
#else
    #ifdef HAVE_EPOLL
    #include "ae_epoll.c"
    #else
        #ifdef HAVE_KQUEUE
        #include "ae_kqueue.c"
        #else
        #include "ae_select.c"
        #endif
    #endif
#endif
```

My working environment is based on Linux kernel, so my Redis server will select the `epoll` multiplexing by default. As I read the source code of `ae_epoll.c`, it seems that Redis doesn't use the epoll edge-triggered mode at all.

## Redis Client

In Redis, the declaration of redis client is inside src/server.h whose name is `client`. And the struct `redisServer` use a `list` to store the list of the clients. It is shown as the following code.

```c
// src/server.h

struct redisServer {
    ......
    list *clients;              /* List of active clients */
    list *clients_to_close;     /* Clients to close asynchronously */
    list *clients_pending_write; /* There is to write or install handler. */
    list *clients_pending_read;  /* Client has pending read socket buffers. */
    list *slaves, *monitors;    /* List of slaves and MONITORs */
    client *current_client;     /* Current client executing the command. */
    ......
};

typedef struct client {
    ......
} client;
```

## Redis Server

The Redis server we discussed by now is assumed to be a standalone server. However, there are three more modes of Redis server. I will introduce them simly as follow.

### Replication

The implementation is located at src/replication.c.

The following are some very important facts about Redis replication:

* Redis uses asynchronous replication, with asynchronous replica-to-master acknowledges of the amount of data processed.
* A master can have multiple replicas.
* Replicas are able to accept connections from other replicas. Aside from connecting a number of replicas to the same master, replicas can also be connected to other replicas in a cascading-like structure. Since Redis 4.0, all the sub-replicas will receive exactly the same replication stream from the master.
* Redis replication is non-blocking on the master side. This means that the master will continue to handle queries when one or more replicas perform the initial synchronization or a partial resynchronization.
* Replication is also largely non-blocking on the replica side. While the replica is performing the initial synchronization, it can handle queries using the old version of the dataset, assuming you configured Redis to do so in redis.conf. Otherwise, you can configure Redis replicas to return an error to clients if the replication stream is down. However, after the initial sync, the old dataset must be deleted and the new one must be loaded. The replica will block incoming connections during this brief window (that can be as long as many seconds for very large datasets). Since Redis 4.0 it is possible to configure Redis so that the deletion of the old data set happens in a different thread, however loading the new initial dataset will still happen in the main thread and block the replica.
* Replication can be used both for scalability, in order to have multiple replicas for read-only queries (for example, slow O(N) operations can be offloaded to replicas), or simply for improving data safety and high availability.
* It is possible to use replication to avoid the cost of having the master writing the full dataset to disk: a typical technique involves configuring your master redis.conf to avoid persisting to disk at all, then connect a replica configured to save from time to time, or with AOF enabled. However this setup must be handled with care, since a restarting master will start with an empty dataset: if the replica tries to synchronize with it, the replica will be emptied as well.

[Official Replication Introduction](https://redis.io/topics/replication)

There are two kinds of **PSYNC** commands, one is **full resynchronization** and the other is **partial resynchronization**. The **full resynchronization** works like the **SYNC** command.

Note the **SYNC** command uses the **BGSAVE** command to save a `rdb` file for the whole data set of master instance and then the master instance wil send the rdb file to the replica instances. The replica instances then will load the rdb file into memory for use. During this **BGSAVE** and loading file time, the servers will be blocked and the network bandwith will be filled with the rdb file. So the **SYNC** command is very expensive. The implementation is **void syncCommand(client *c)** inside src/replication.c.

For **partial resynchronization**, there are three important components to implement this function. They are the **replication offset** of master instance and replica instances, **replication backlog** of master instance and **run ID** of the server.

### Sentinel

The implementation is located at src/sentinel.c. It is used to monitor multiple master instances and their replica instances. It is mandatory to use a configuration file when running Sentinel, as this file will be used by the system in order to save the current state that will be reloaded in case of restarts. Sentinel will simply refuse to start if no configuration file is given or if the configuration file path is not writable.

Sentinels by default run listening for connections to TCP port 26379, so for Sentinels to work, port 26379 of your servers must be open to receive connections from the IP addresses of the other Sentinel instances. Otherwise Sentinels can't talk and can't agree about what to do, so failover will never be performed.

This is the full list of Sentinel capabilities at a macroscopic level:

* **Monitoring**. Sentinel constantly checks if your master and replica instances are working as expected.
* **Notification**. Sentinel can notify the system administrator, or other computer programs, via an API, that something is wrong with one of the monitored Redis instances.
* **Automatic failover**. If a master is not working as expected, Sentinel can start a failover process where a replica is promoted to master, the other additional replicas are reconfigured to use the new master, and the applications using the Redis server are informed about the new address to use when connecting.
* **Configuration provider**. Sentinel acts as a source of authority for clients service discovery: clients connect to Sentinels in order to ask for the address of the current Redis master responsible for a given service. If a failover occurs, Sentinels will report the new address.

[Official Sentinel Introduction](https://redis.io/topics/sentinel)

### Cluster

The implementaion is located at src/cluster.c.

[Official Cluster Introduction](https://redis.io/topics/cluster-tutorial)

## Publish and Subscribe

The implementation is located at src/pubsub.c. The **void subscribeCommand(client *c)** function is used to implement the **SUBSCRIBE** command. The **void unsubscribeCommand(client *c)** function is used to implement the **UNSUBSCRIBE** command.

## Jemalloc

**Jemalloc** is redis's memory allocator, used as replacement for libc malloc on **Linux** by default. It has good performances and excellent fragmentation behavior. And this is its [github website](https://github.com/jemalloc/jemalloc)

As the following code shows:

```c
// In src/zmalloc.h

// This macro is used to decide
// whether the libc memory allocator
// is replaced with jemalloc

#define HAVE_MALLOC_SIZE 1

// The malloc_usable_size is implemented
// by the jemalloc rather than libc malloc
// So the result of zmalloc_size(p) will
// be the exact size of the allocated buffer
// without the extra 8 bytes we save before
// each pointer

#define zmalloc_size(p) malloc_usable_size(p)

// In src/zmalloc.c
// HAVE_MALLOC_SIZE is used to show whether
// redis use jemalloc or not.

#ifdef HAVE_MALLOC_SIZE
#define PREFIX_SIZE (0)
#define ASSERT_NO_SIZE_OVERFLOW(sz)
#else
#if defined(__sun) || defined(__sparc) || defined(__sparc__)
#define PREFIX_SIZE (sizeof(long long))
#else
#define PREFIX_SIZE (sizeof(size_t))
#endif
#define ASSERT_NO_SIZE_OVERFLOW(sz) assert((sz) + PREFIX_SIZE > (sz))
#endif
```

In the above example, if the macro `HAVE_MALLOC_SIZE` has been defined, then the **zmalloc_size** will be equivalent to **malloc_usable_size**, which is implemented by jemalloc in **deps/jemalloc/src/jemalloc.c** rather than libc.
