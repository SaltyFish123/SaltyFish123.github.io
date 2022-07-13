---
layout: post
title: ELF Format
date: 2022-07-08
categories: Program
tags: Program_Structure
---

* TOC
{:toc}

In computing, the **Executable and Linkable Format ( ELF, formerly named Extensible Linking Format )**, is a common standard file format for executable files, object code, shared libraries, and core dumps.

## Specifial Sections

There are various sections hold program and control information. I will list the sections below:

| Section Name | Description |
|:--------------|-------------|
|.bss|This section holds uninitialized data that contribute to the program’s memory image. By definition, the system initializes the data with zeros when the program begins to run. The section occupies no file space, as indicated by the section type, SHT_NOBITS.|
|.comment|This section holds version control information.|
|.data and .data1|These sections hold initialized data that contribute to the program’s memory image.|
|.debug|This section holds information for symbolic debugging. The contents are unspecified.|
|.dynamic|This section holds dynamic linking information. The section’s attributes will include the SHF_ALLOC bit. Whether the SHF_WRITE bit is set is processor specific.|
|.dynstr|This section holds strings needed for dynamic linking, most commonly the strings that represent the names associated with symbol table entries.|
|.dynsym|This section holds the dynamic linking symbol table, as "Symbol Table" describes.|
|.fini|This section holds executable instructions that contribute to the process termination code. That is, when a program exits normally, the system arranges to execute the code in this section.|
|.got|This section holds the global offset table. |
|.hash|This section holds a symbol hash table.|
|.init|This section holds executable instructions that contribute to the process initialization code. That is, when a program starts to run, the system arranges to execute the code in this section before calling the main program entry point (called main for C programs).|
|.interp|This section holds the path name of a program interpreter. If the file has a loadable segment that includes the section, the section’s attributes will include the SHF_ALLOC bit; otherwise, that bit will be off.
|.line|This section holds line number information for symbolic debugging, which describes the correspondence between the source program and the machine code. The contents are unspecified.|
|.note|This section holds information that other programs will check for conformance, compatibility, etc.|
|.plt|This section holds the procedure linkage table.|
|.rel*name* and .rela*name*|These sections hold relocation information, as "Relocation" below describes. If the file has a loadable segment that includes relocation, the sections’ attributes will include the SHF_ALLOC bit; otherwise, that bit will be off. Conventionally, name is supplied by the section to which the relocations apply. Thus a relocation section for .text normally would have the name .rel.text or .rela.text.|
|.rodata and .rodata1|These sections hold read-only data that typically contribute to a non-writable segment in the process image.|
|.shstrtab|This section holds section names.|
|.strtab|This section holds strings, most commonly the strings that represent the names associated with symbol table entries. If the file has a loadable segment that includes the symbol string table, the section’s attributes will include the SHF_ALLOC bit; otherwise, that bit will be off.|
|.symtab|This section holds a symbol table, as "Symbol Table" in this section describes. If the file has a loadable segment that includes the symbol table, the section’s attributes will include the SHF_ALLOC bit; otherwise, that bit will be off.|
|.text|This section holds the "text," or executable instructions, of a program.|

## Relocation

Relocation is the process of connecting symbolic references with symbolic definitions. For example, when a program calls a function, the associated call instruction must transfer control to the proper destination address at execution.

## Global Offset Table(GOT)

GOT stores the absolute addresses of the symbols. For shared objects, these absolute addresses are relocated at run time.

## Procedure Linkage Table(PLT)

For shared objects, PLT used to call external functions whose address isn't known in the time of linking, and is left to be resolved by the dynamic linker at run time.

## Program Interpreter

An executable file may have one PT_INTERP program header element. During exec(BA_OS), the system retrieves a path name from the PT_INTERP segment and creates the initial process image from the interpreter file's segments. That is, instead of using the original executable file's segment images, the system composes a memory image for the interpreter. It then is the interpreter's responsibility to receive control from the system and provide an environment for the application program.

The interpreter receives control in one of two ways. First, it may receive a file descriptor to read the executable file, positioned at the beginning. It can use this file descriptor to read and/or map the executable file's segments into memory. Second, depending on the executable file format, the system may load the executable file into memory instead of giving the interpreter an open file descriptor. With the possible exception of the file descriptor, the interpreter's initial process state matches what the executable file would have received. The interpreter itself may not require a second interpreter. An interpreter may be either a shared object or an executable file.

1. A shared object (the normal case) is loaded as position-independent, with addresses that may vary from one process to another; the system creates its segments in the dynamic segment area used by mmap(KE_OS) and related services. Consequently, a shared object interpreter typically will not conflict with the original executable file's original segment addresses.
2. An executable file is loaded at fixed addresses; the system creates its segments using the virtual addresses from the program header table. Consequently, an executable file interpreter's virtual addresses may collide with the first executable file; the interpreter is responsible for resolving conflicts.

## References

[PLT and GOT](https://www.technovelty.org/linux/plt-and-got-the-key-to-code-sharing-and-dynamic-libraries.html)

[ELF Format](http://flint.cs.yale.edu/cs422/doc/ELF_Format.pdf)
