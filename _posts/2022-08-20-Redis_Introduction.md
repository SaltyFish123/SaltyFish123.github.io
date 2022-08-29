---
layout: post
title: Introduction of Redis
date: 2022-08-20
categories: NoSQL
tags: Redis
---

* TOC
{:toc}

There are a lot of articles about Redis. You can get more information about Redis from its [offical website](https://redis.io/). I just read the redis source code base on the release 7.0 and here I will note the part that I am interested in.

## Building Redis from Source Code

My computer environment is list belowed:

1. OS: Linux mint 20.2
2. CPU: Intel x86_64 cpu

If your environment is similiar with mine, you should get no problem as I get. If you have any issues, you can go to this reids [github issue](https://github.com/redis/redis/issues) to get some help.

After you have download the [source code](https://github.com/redis/redis) of Redis from github, you can do the following steps to build Redis:

1. Enter the root directory of Redis project, then run the `make` command.
2. After executing the `make` command, run the `make test` command to test it running.

If everything is fine, Redis is successfully built.

## Running Redis

To run Redis with the default configuration, just type:

```bash
% cd src
% ./redis-server
```

If you want to provide your redis.conf, you have to run it using an additional parameter (the path of the configuration file):

```bash
% cd src
% ./redis-server /path/to/redis.conf
```

It is possible to alter the Redis configuration by passing parameters directly as options using the command line. Examples:

```bash
% ./redis-server --port 9999 --replicaof 127.0.0.1 6379
% ./redis-server /etc/redis/6379.conf --loglevel debug
```

All the options in redis.conf are also supported as options using the command line, with exactly the same name.

Then you can run Redis client with the command:

```bash
cd src
./redis-cli
```

## Using GDB to Debug the Source Code

This is the [official reference article of Redis debugging](https://redis.io/topics/debugging).

By default Redis is compiled with the -O2 switch, this means that compiler optimizations are enabled. It is better to attach GDB to Redis compiled without optimizations using the `make noopt` command to compile it (instead of just using the plain make command).

Then start the redis-server process. Using the command `redis-cli info | grep process_id` to get the processid of the redis-server. Then, for example, run the gdb with the path to the redis-server and the processid as `gdb attach 58414`. **If it doesn't work, follow the prompt of the gdb and try again as the root user.** It should work finally.
