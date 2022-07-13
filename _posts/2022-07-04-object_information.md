---
layout: post
title: Reading the Information of the Executable Files
date: 2022-07-04
categories: Program
tags: Programming_Tools
---

* TOC
{:toc}

The following development tools are used to get the information of the executable files like the shared object or program. You can use the `man` command to get more details about the tools on linux.

1. nm, list symbols from object files.
2. ldd - print shared object dependencies
3. objdump - display information from object files
4. readelf - This tool can be used to display informations about elf files. For example, **readelf -r temp.exe** will display the contents of the file's **relocation**(relocations are entries in binaries that are left to be filled in later -- at link time by the toolchain linker or at runtime by the dynamic linker.) section, if it has one. This program performs a similar function to objdump but it goes into more detail and it exists independently of the BFD library, so if there is a bug in BFD then readelf will not be affected.

For `objdump`, the `-h` option will display print all the section header.

The `-d` option will display the assembler mnemonics for the machine instructions from the input file. This option only disassembles those sections which are expected to contain instructions. If you specific the symbol with `--disassemble=funcname` option can be used to disassemble the function with symbol name `funcname`. Notice that in C++ the overload is allowed since the function name is mangled so you can just simply use the function name but the coressponding symbol name. I will show the example in the next section.

The `-D` option will disassemble the contents of all sections but not only the sections contain instructions.

The `-j name` option can help to display information only for section name. For example, the command `objdump -dj .text temp.o` will only display the disassembly code of the section .text of the obejct file temp.o.

For executable files with debug information(gcc/g++ use the -g option), `-l` option of objdump will try to find the filename and linenumber for each symbol. It is convinient to read the disassemler code of the object file with the help of objdump.
