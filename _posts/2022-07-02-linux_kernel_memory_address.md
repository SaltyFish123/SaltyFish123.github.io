---
layout: post
title: Linux Kernel Memory Addressing
date: 2022-07-02
categories: Linux_Kernel
tags: Understanding_the_Linux_Kernel 
---

## Memory Addresses

There are three kinds of addresses as shown below:

* **Logical address**. Included in the machine language instructions to specify the address of an operand or of an instruction. This type of address embodies the well-known 80 x 86 segmented architecture that forces MS-DOS and Windows programmers to divide their programs into segments. Each logical address consists of a segment and an offset (or displacement) that denotes the distance from the start of the segment to the actual address.
* **Linear address (also known as virtual address)**. A single 32-bit unsigned integer that can be used to address up to 4 GB that is, up to (2^32)4,294,967,296 memory cells. Linear addresses are usually represented in hexadecimal notation; their values range from 0x00000000 to 0xffffffff.
* **Physical address**. Used to address memory cells in memory chips. They correspond to the electrical signals sent along the address pins of the microprocessor to the memory bus. Physical addresses are represented as 32-bit or 36-bit unsigned integers.

The **Memory Management Unit (MMU)** transforms a logical address into a linear address by means of a hardware circuit called a **segmentation unit**; subsequently, a second hardware circuit called a **paging unit** transforms the linear address into a physical address.

Virtual memory acts as a logical layer between the application memory requests and the hardware **Memory Management Unit (MMU)**. Virtual memory has many purposes and advantages:

* Several processes can be executed concurrently.
* It is possible to run applications whose memory needs are larger than the available physical memory.
* Processes can execute a program whose code is only partially loaded in memory.
* Each process is allowed to access a subset of the available physical memory.
* Processes can share a single memory image of a library or program.
* Programs can be relocatable that is, they can be placed anywhere in physical memory.
* Programmers can write machine-independent code, because they do not need to be concerned about physical memory organization.

Today's CPUs include hardware circuits that automatically translate the virtual addresses into physical ones. To that end, the available RAM is partitioned into page frames typically 4 or 8 KB in length and a set of Page Tables is introduced to specify how virtual addresses correspond to physical addresses. These circuits make memory allocation simpler, because a request for a block of contiguous virtual addresses can be satisfied by allocating a group of page frames having noncontiguous physical addresses.

## Segmentation in Linux

**Linux uses segmentation in a very limited way**. In fact, segmentation and paging are somewhat redundant, because both can be used to separate the physical address spaces of processes: segmentation can assign a different linear address space to each process, while paging can map the same linear address space into different physical address spaces. Linux prefers paging to segmentation for the following reasons:

* Memory management is simpler when all processes use the same segment register values that is, when they share the same set of linear addresses.
* One of the design objectives of Linux is portability to a wide range of architectures; RISC architectures in particular have limited support for segmentation.

All Linux processes running in User Mode use the same pair of segments to address instructions and data. These segments are called user code segment and user data segment, respectively. Similarly, all Linux processes running in Kernel Mode use the same pair of segments to address instructions and data: they are called kernel code segment and kernel data segment, respectively.

## Paging in Hardware

The paging unit translates linear addresses into physical ones. One key task in the unit is to check the requested access type against the access rights of the linear address. If the memory access is not valid, it generates a Page Fault exception.

For the sake of efficiency, linear addresses are grouped in fixed-length intervals called **pages**; contiguous linear addresses within a page are mapped into contiguous physical addresses. In this way, the kernel can specify the physical address and the access rights of a page instead of those of all the linear addresses included in it. Following the usual convention, we shall use the term "page" to refer both to a set of linear addresses and to the data contained in this group of addresses.

The paging unit thinks of all RAM as partitioned into fixed-length page frames (sometimes referred to as physical pages ). Each page frame contains a page that is, the length of a page frame coincides with that of a page. **A page frame is a constituent of main memory, and hence it is a storage area.** It is important to distinguish a page from a page frame; the former is just a block of data, which may be stored in any page frame or on disk.

The data structures that map linear to physical addresses are called **page tables**

The 32 bits of a linear address are divided into three fields:

* **Directory**. The most significant 10 bits
* **Table**. The intermediate 10 bits
* **Offset**. The least significant 12 bits

The Directory field within the linear address determines the entry in the Page Directory that points to the proper Page Table. The address's Table field, in turn, determines the entry in the Page Table that contains the physical address of the page frame containing the page. The Offset field determines the relative position within the page frame. Because the Offset field is 12 bits long, each page consists of (2^12)4096 bytes of data. Both the Directory and the Table fields are 10 bits long, so Page Directories and Page Tables can include up to (2^10)1,024 entries. It follows that a Page Directory can address up to 1024 x 1024 x 4096=2^32 memory cells, as you'd expect in 32-bit addresses.

### Extended Paging

Extended paging is used to translate large contiguous linear address ranges into corresponding physical ones, which allows page frames to be 4 MB instead of 4 KB in size. In these cases, the kernel can do without intermediate Page Tables and thus save memory and preserve **TLB (Translation Lookaside Buffers)** entries. In this case, the paging unit divides the 32 bits of a linear address into two fields:

* **Dictionary**. The most significant 10 bits.
* **Offset**. The remaining 22 bits.

## Paging in Linux

Linux adopts a common paging model that fits both 32-bit and 64-bit architectures. Two paging levels are sufficient for 32-bit architectures, while 64-bit architectures require a higher number of paging levels. Up to version 2.6.10, the Linux paging model consisted of three paging levels. Starting with version 2.6.11, a four-level paging model has been adopted. The **Page Global Directory** includes the addresses of several **Page Upper Directories**, which in turn include the addresses of several **Page Middle Directories**, which in turn include the addresses of several **Page Tables**. Each Page Table entry points to a page frame by **Offset**. Thus the linear address can be split into up to five parts. The size of each part depends on the computer architecture.

For 32-bit architectures with no Physical Address Extension, two paging levels are sufficient. Linux essentially eliminates the Page Upper Directory and the Page Middle Directory fields by saying that they contain zero bits. However, the positions of the Page Upper Directory and the Page Middle Directory in the sequence of pointers are kept so that the same code can work on 32-bit and 64-bit architectures. The kernel keeps a position for the Page Upper Directory and the Page Middle Directory by setting the number of entries in them to 1 and mapping these two entries into the proper entry of the Page Global Directory.
