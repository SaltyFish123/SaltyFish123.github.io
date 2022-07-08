---
layout: post
title: Linux Kernel Process
date: 2022-07-02
categories: Linux_Kernel
tags: Understanding_the_Linux_Kernel
---

* TOC
{:toc}

## Processes, Lightweight Processes, and Threads

From the kernel's point of view, the purpose of a process is to act as an entity to which system resources (CPU time, memory, etc.) are allocated.

When a process is created, it is almost identical to its parent. It receives a (logical) copy of the parent's address space and executes the same code as the parent, beginning at the next instruction following the process creation system call. Although the parent and child may share the pages containing the program code (text), they have separate copies of the data (stack and heap), so that changes by the child to a memory location are invisible to the parent (and vice versa).

Linux uses lightweight processes to offer better support for multithreaded applications. Basically, two lightweight processes may share some resources, like the address space, the open files, and so on. Whenever one of them modifies a shared resource, the other immediately sees the change. Of course, the two processes must synchronize themselves when accessing the shared resource. A straightforward way to implement multithreaded applications is to associate a lightweight process with each thread. In this way, the threads can access the same set of application data structures by simply sharing the same memory address space, the same set of open files, and so on; at the same time, each thread can be scheduled independently by the kernel so that one may sleep while another remains runnable.

## Process Descriptor

To manage processes, the kernel must have a clear picture of what each process is doing. It must know, for instance, the process's priority, whether it is running on a CPU or blocked on an event, what address space has been assigned to it, which files it is allowed to address, and so on. This is the role of the **process descriptor** a **task_struct** type structure whose fields contain all the information related to a single process.

### Process State

As its name implies, the state field of the process descriptor describes what is currently happening to the process. It consists of an array of flags, each of which describes a possible process state. In the current Linux version, these states are mutually exclusive, and hence exactly one flag of state always is set; the remaining flags are cleared. The following are the possible process states:

* **TASK_RUNNING**. The process is either executing on a CPU or waiting to be executed.
* **TASK_INTERRUPTIBLE**. The process is suspended (sleeping) until some condition becomes true. Raising a hardware interrupt, releasing a system resource the process is waiting for, or delivering a signal are examples of conditions that might wake up the process (put its state back to TASK_RUNNING).
* **TASK_UNINTERRUPTIBLE**. Like TASK_INTERRUPTIBLE, except that delivering a signal to the sleeping process leaves its state unchanged. This process state is seldom used. It is valuable, however, under certain specific conditions in which a process must wait until a given event occurs without being interrupted. For instance, this state may be used when a process opens a device file and the corresponding device driver starts probing for a corresponding hardware device. The device driver must not be interrupted until the probing is complete, or the hardware device could be left in an unpredictable state.
* **TASK_STOPPED**. Process execution has been stopped; the process enters this state after receiving a SIGSTOP, SIGTSTP, SIGTTIN, or SIGTTOU signal.
* **TASK_TRACED**. Process execution has been stopped by a debugger. When a process is being monitored by another (such as when a debugger executes a ptrace( ) system call to monitor a test program), each signal may put the process in the TASK_TRACED state.

Two additional states of the process can be stored both in the state field and in the exit_state field of the process descriptor; as the field name suggests, a process reaches one of these two states only when its execution is terminated:

* **EXIT_ZOMBIE**. Process execution is terminated, but the parent process has not yet issued a wait4( ) or waitpid( ) system call to return information about the dead process. Before the wait( )-like call is issued, the kernel cannot discard the data contained in the dead process descriptor because the parent might need it. There are other wait( ) -like library functions, such as wait3( ) and wait( ), but in Linux they are implemented by means of the wait4( ) and waitpid( ) system calls.
* **EXIT_DEAD**. The final state: the process is being removed by the system because the parent process has just issued a wait4( ) or waitpid( ) system call for it. Changing its state from EXIT_ZOMBIE to EXIT_DEAD avoids race conditions due to other threads of execution that execute wait( )-like calls on the same process.

The value of the state field is usually set with a simple assignment. For instance:

    p->state = TASK_RUNNING;

Unix-like operating systems allow users to identify processes by means of a number called the Process ID (or PID), which is stored in the pid field of the process descriptor. PIDs are numbered sequentially: the PID of a newly created process is normally the PID of the previously created process increased by one. Of course, there is an upper limit on the PID values; when the kernel reaches such limit, it must start recycling the lower, unused PIDs.

## Process Switch

To control the execution of processes, the kernel must be able to suspend the execution of the process running on the CPU and resume the execution of some other process previously suspended. This activity goes variously by the names process switch, task switch, or context switch.

### Hardware Context

While each process can have its own address space, all processes have to share the CPU registers. So before resuming the execution of a process, the kernel must ensure that each such register is loaded with the value it had when the process was suspended. The set of data that must be loaded into the registers before the process resumes its execution on the CPU is called the **hardware context**. The hardware context is a subset of the process execution context, which includes all information needed for the process execution. In Linux, a part of the hardware context of a process is stored in the process descriptor, while the remaining part is saved in the Kernel Mode stack.

## Creating Processes

Traditional Unix systems treat all processes in the same way: resources owned by the parent process are duplicated in the child process. This approach makes process creation very slow and inefficient, because it requires copying the entire address space of the parent process. The child process rarely needs to read or modify all the resources inherited from the parent; in many cases, it issues an immediate execve( ) and wipes out the address space that was so carefully copied.

Modern Unix kernels solve this problem by introducing three different mechanisms:

* **The Copy On Write technique** allows both the parent and the child to read the same physical pages. Whenever either one tries to write on a physical page, the kernel copies its contents into a new physical page that is assigned to the writing process.
* **Lightweight processes** allow both the parent and the child to share many per-process kernel data structures, such as the paging tables (and therefore the entire User Mode address space), the open file tables, and the signal dispositions.
* The **vfork( )** system call creates a process that shares the memory address space of its parent. To prevent the parent from overwriting data needed by the child, the parent's execution is blocked until the child exits or executes a new program.

### The clone(), fork() and vfork() System Calls

Lightweight processes are created in Linux by using a function named clone(). clone( ) is actually a wrapper function defined in the C library, which sets up the stack of the new lightweight process and invokes a clone() system call hidden to the programmer.

The traditional fork() system call is implemented by Linux as a clone() system call whose flags parameter specifies both a SIGCHLD signal and all the clone flags cleared, and whose child_stack parameter is the current parent stack pointer. Therefore, the parent and child temporarily share the same User Mode stack. But thanks to the Copy On Write mechanism, they usually get separate copies of the User Mode stack as soon as one tries to change the stack.

The vfork( ) system call is implemented by Linux as a clone( ) system call whose flags parameter specifies both a SIGCHLD signal and the flags CLONE_VM and CLONE_VFORK, and whose child_stack parameter is equal to the current parent stack pointer.

## Destroying Processes

The usual way for a process to terminate is to invoke the exit( ) library function, which releases the resources allocated by the C library, executes each function registered by the programmer, and ends up invoking a system call that evicts the process from the system. The exit( ) library function may be inserted by the programmer explicitly. Additionally, the C compiler always inserts an exit( ) function call right after the last statement of the main( ) function.

The **exit**, **_Exit** and **_exit** functions terminate the calling process. The exit function calls destructors for thread-local objects, then calls—in last-in-first-out (LIFO) order—the functions that are registered by **atexit** and **_onexit**, and then flushes all file buffers before it terminates the process. The **_Exit** and **_exit** functions terminate the process without destroying thread-local objects or processing atexit or **_onexit** functions, and without flushing stream buffers.

### Process Removal

The Unix operating system allows a process to query the kernel to obtain the PID of its parent process or the execution state of any of its children. A process may, for instance, create a child process to perform a specific task and then invoke some wait( )-like library function to check whether the child has terminated. If the child has terminated, its termination code will tell the parent process if the task has been carried out successfully.

To comply with these design choices, Unix kernels are not allowed to discard data included in a process descriptor field right after the process terminates. They are allowed to do so only after the parent process has issued a wait( )-like system call that refers to the terminated process. This is why the **EXIT_ZOMBIE** state has been introduced: although the process is technically dead, its descriptor must be saved until the parent process is notified.

What happens if parent processes terminate before their children? In such a case, the system could be flooded with zombie processes whose process descriptors would stay forever in RAM. This problem is solved by forcing all **orphan processes** to become children of the init process. In this way, the init process will destroy the zombies while checking for the termination of one of its legitimate children through a wait( )-like system call.
