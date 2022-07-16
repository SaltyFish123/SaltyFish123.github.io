---
layout: post
title: Program Creation
date: 2022-07-08
categories: Program
tags: Program_Structure
---

* TOC
{:toc}

## Preprocesssing, Compilation, Assembly and Linking

For C/C++ language, the compiler gcc/g++ are used to do preprocessing, compilation, assembly and linking to create a executable program. You can use the options listed below to create the corresponding file.

|option|usage|
|:---|---:|
|-E|Preprocess only; do not compile, assemble or link|
|-S|Compile only; do not assemble or link|
|-c|Compile and assemble, but do not link|
|-o \<file\>|Place the output into \<file\>|

1. Preprocessing will preocess the macro, include-files, conditional compilation instructions and comments.
2. Compilation will take the preprocessed code as input and output the coressponding the assembly code.
3. Assembly will take the assembly code as input and output the coressponding machine instructions. These binary code are stored inside the object file.
4. Linking will take the object files as input and output the coressponding executable program.

## Program Loading

When the program is executed, it is loaded into the RAM and become a process. The following diagram shows the steps:

![Process Creation](https://www.tenouk.com/ModuleW_files/ccompilerlinker001.png)

As the system creates or augments a process image, it logically copies a file's segment to a virtual memory segment. When—and if—the system physically reads the file depends on the program's execution behavior, system load, etc. A process does not require a physical page unless it references the logical page during execution, and processes commonly leave many pages unreferenced. Therefore delaying physical reads frequently obviates them, improving system performance. To obtain this efficiency in practice, executable and shared object files must have segment images whose file offsets and virtual addresses are congruent,modulo the page size.

As the following image shows, the sections of the executable file are loaded into the virtual memory to compose the segments of the process.

![object file format](https://www.tenouk.com/ModuleW_files/ccompilerlinker004.png)

The memory layout of process is shown below. And it is created from the sections of the object file. For example, the data segment contain the data of the .data section of the object files.

![progrss segments](https://www.tenouk.com/ModuleW_files/ccompilerlinker005.png)

One aspect of segment loading differs between executable files and shared objects. Executable file segments typically contain absolute code. To let the process execute correctly, the segments must reside at the virtual addresses used to build the executable file. Thus the system uses the p_vaddr values unchanged as virtual addresses.

On the other hand, shared object segments typically contain **position-independent code(PIC)**. This lets a segment's virtual address change from one process to another, without invalidating execution behavior. Though the system chooses virtual addresses for individual processes, it maintains the segments' relative positions. Because position-independent code uses relative addressing between segments, the difference between virtual addresses in memory must match the difference between virtual addresses in the file. The following table shows possible shared object virtual address assignments for several processes, illustrating constant relative positioning. The table also illustrates the base address computations.

|Source|Text|Data|Base Address|
|------|----|----|-----------:|
|File  |0x200|0x2a400|0x0|
|Process1|0x80000200|0x8002a400|0x80000000|

## Dynamic Linker

When building an executable file that uses dynamic linking, the link editor adds a program header element of type PT_INTERP to an executable file, telling the system to invoke the dynamic linker as the program interpreter.

Exec(BA_OS) and the dynamic linker cooperate to create the process image for the program, which entails the following actions:

1. Adding the executable file's memory segments to the process image;
2. Adding shared object memory segments to the process image;
3. Performing relocations for the executable file and its shared objects;
4. Closing the file descriptor that was used to read the executable file, if one was given to the dynamic linker;
5. Transferring control to the program, making it look as if the program had received control directly from exec(BA_OS).

## Shared Library

All executable files in traditional Unix systems were based on static libraries. This means that the executable file produced by the linker includes not only the code of the original program but also the code of the library functions that the program refers to. One big disadvantage of statically linked programs is that they eat lots of space on disk. Indeed, each statically linked executable file duplicates some portion of library code.

Modern Unix systems use shared libraries. The executable file does not contain the library object code, but only a reference to the library name. When the program is loaded in memory for execution, a suitable program called dynamic linker (also named ld.so ) takes care of analyzing the library names in the executable file, locating the library in the system's directory tree and making the requested code available to the executing process. A process can also load additional shared libraries at runtime by using the dlopen( ) library function.

Shared libraries are especially convenient on systems that provide file memory mapping, because they reduce the amount of main memory requested for executing a program. When the dynamic linker must link a shared library to a process, it does not copy the object code, but performs only a memory mapping of the relevant portion of the library file into the process's address space. This allows the page frames containing the machine code of the library to be shared among all processes that are using the same code. Clearly, sharing is not possible if the program has been linked statically. This can be achieved by position-independent code (PIC).

Shared libraries also have some disadvantages. The startup time of a dynamically linked program is usually longer than that of a statically linked one. Moreover, dynamically linked programs are not as portable as statically linked ones, because they may not execute properly in systems that include a different version of the same library.

Note that for `gcc/g++`, -llibrary Add archive file library to the list of files to link. The GNU linker `ld` will search its path-list for occurrences of liblibrary.a or liblibrary.so for every archive specified. Static libraries are archives of object files, and have file names like liblibrary.a. Some targets also support shared libraries, which typically have names like liblibrary.so. If both static and shared libraries are found, the linker gives preference to linking with the shared library unless the -static option is used. If we have a shared library named `libshared.so`, then we will use `-lshared` to search this specific file. Since GCC assumes that all libraries start with lib and end with .so or .a (.so is for shared object or shared libraries, and .a is for archive, or statically linked libraries).

-Lsearchdir Add path searchdir to the list of paths that ld will search for archive libraries and ld control scripts.

## Dynamic Linking Example

```c
//main.c
#include <stdio.h>
#include "relocs.h"

int main(void) 
{ 
    printf("The result of %d + %d is %d\n", 1, 2, myAdd(1, 2)); 
    return 0; 
}
```

```c
//relocs.h
#ifndef RELOCS
#define RELOCS

extern int myAdd(int, int);

#endif
```

```c
//relocs.c
int myAdd(int a, int b) {
    return a + b;
}
```

Using the following command to generate the object file and the executable program

```shell
gcc -fPIC -shared relocs.c -o librelocs.so
gcc -c main.c
gcc -L. main.o -lrelocs -o main.exe
export LD_LIBRARY_PATH=/home/username/lib:$LD_LIBRARY_PATH
```

Note that after you have finished the compilation, you need to add the shared library location path to the LD_LIBRARY_PATH environment variable. Otherwise the program will not be able to find the library and it will report an error as follows:

```shell
./main.exe: error while loading shared libraries: librelocs.so: cannot open shared object file: No such file or directory
```

You can also use the `-Wl,-rpath` option of gcc to tell the linker where it can find the shared library. The following commands will work.

```shell
gcc -fPIC -shared relocs.c -o librelocs.so
gcc -c main.c
gcc -L/home/username/lib -g -Wl,-rpath=/home/username/lib main.o -lrelocs -o main.exe
```

At first, we can use readelf to read the relocation information of main.o.

```shell
$readelf -r main.o

Relocation section '.rela.text' at offset 0x2a0 contains 3 entries:
  Offset          Info           Type           Sym. Value    Sym. Name + Addend
000000000013  000c00000004 R_X86_64_PLT32    0000000000000000 myAdd - 4
000000000026  000500000002 R_X86_64_PC32     0000000000000000 .rodata - 4
000000000030  000d00000004 R_X86_64_PLT32    0000000000000000 printf - 4
```

As we can see, there are three entries in the relocation section of .text and the `Sym. Value` of them are all zero. The relocation type R_X86_64_PLT32 means that the function is going to be computed at link time or run time to be filled in the PLT. The Addend specifies a constant addend used to compute the value to be stored into the relocatable field. Then we can objdump to see the disassembly code of the .text section.

```shell
$objdump -dj .text main.o

main.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:   f3 0f 1e fa             endbr64 
   4:   55                      push   %rbp
   5:   48 89 e5                mov    %rsp,%rbp
   8:   be 02 00 00 00          mov    $0x2,%esi
   d:   bf 01 00 00 00          mov    $0x1,%edi
  12:   e8 00 00 00 00          callq  17 <main+0x17>
  17:   89 c1                   mov    %eax,%ecx
  19:   ba 02 00 00 00          mov    $0x2,%edx
  1e:   be 01 00 00 00          mov    $0x1,%esi
  23:   48 8d 3d 00 00 00 00    lea    0x0(%rip),%rdi        # 2a <main+0x2a>
  2a:   b8 00 00 00 00          mov    $0x0,%eax
  2f:   e8 00 00 00 00          callq  34 <main+0x34>
  34:   b8 00 00 00 00          mov    $0x0,%eax
  39:   5d                      pop    %rbp
  3a:   c3                      retq
```

Take a look at the offset of the relation entry above. You can find that all the content of the relocation entries is 0. For example, the offset of the `myAdd` entry of the relocation section is 0x13 and the size of it is 32 bits. And in the .text section, the instruction stored frome offset 0x13 to 0x16 is `00`.

For the disassembly code of the main.exe, we can find that the coressponding relocation entries are replaced with the plt entry address. For example, now `myAdd` function in main function is replaced with `callq 1070 <myAdd@plt>`.

```shell
$objdump -D main.exe

Disassembly of section .plt.got:

0000000000001070 <myAdd@plt>:
    1070:	f3 0f 1e fa          	endbr64 
    1074:	f2 ff 25 55 2f 00 00 	bnd jmpq *0x2f55(%rip)        # 3fd0 <myAdd>
    107b:	0f 1f 44 00 00       	nopl   0x0(%rax,%rax,1)

Disassembly of section .text:

0000000000001169 <main>:
    1169:	f3 0f 1e fa          	endbr64 
    116d:	55                   	push   %rbp
    116e:	48 89 e5             	mov    %rsp,%rbp
    1171:	be 02 00 00 00       	mov    $0x2,%esi
    1176:	bf 01 00 00 00       	mov    $0x1,%edi
    117b:	e8 f0 fe ff ff       	callq  1070 <myAdd@plt>
    1180:	89 c1                	mov    %eax,%ecx
    1182:	ba 02 00 00 00       	mov    $0x2,%edx
    1187:	be 01 00 00 00       	mov    $0x1,%esi
    118c:	48 8d 3d 71 0e 00 00 	lea    0xe71(%rip),%rdi        # 2004 <_IO_stdin_used+0x4>
    1193:	b8 00 00 00 00       	mov    $0x0,%eax
    1198:	e8 c3 fe ff ff       	callq  1060 <printf@plt>
    119d:	b8 00 00 00 00       	mov    $0x0,%eax
    11a2:	5d                   	pop    %rbp
    11a3:	c3                   	retq   
    11a4:	66 2e 0f 1f 84 00 00 	nopw   %cs:0x0(%rax,%rax,1)
    11ab:	00 00 00 
    11ae:	66 90                	xchg   %ax,%ax

Disassembly of section .got:

0000000000003fb0 <_GLOBAL_OFFSET_TABLE_>:
    3fb0:	b0 3d                	mov    $0x3d,%al
	...
    3fc6:	00 00                	add    %al,(%rax)
    3fc8:	30 10                	xor    %dl,(%rax)
    3fca:	00 00                	add    %al,(%rax)
    3fcc:	00 00                	add    %al,(%rax)
    3fce:	00 00                	add    %al,(%rax)
    3fd0:	40 10 00             	adc    %al,(%rax)
	...
```

Now suppose you run the program as a process. Note that you need to recompile the library with the option `-g`. At first, you can use the command `info file` to see the address space of the sections of the objects of the program.

Before you run the program, the command will only display the information of the main.o object. After you have run the program, the command will display all the information of the objects that were linked together.

Suppose now we set a breakpoint at `main` and then run the program. The command `disass` will display the assembly code of the main function. As we can see, now in the process image the address of the myAdd@plt is relocated as 0x555555555070.

```shell
(gdb) disass
Dump of assembler code for function main:
=> 0x0000555555555169 <+0>:     endbr64 
   0x000055555555516d <+4>:     push   %rbp
   0x000055555555516e <+5>:     mov    %rsp,%rbp
   0x0000555555555171 <+8>:     mov    $0x2,%esi
   0x0000555555555176 <+13>:    mov    $0x1,%edi
   0x000055555555517b <+18>:    callq  0x555555555070 <myAdd@plt>
   0x0000555555555180 <+23>:    mov    %eax,%ecx
   0x0000555555555182 <+25>:    mov    $0x2,%edx
   0x0000555555555187 <+30>:    mov    $0x1,%esi
   0x000055555555518c <+35>:    lea    0xe71(%rip),%rdi        # 0x555555556004
--Type <RET> for more, q to quit, c to continue without paging--
   0x0000555555555193 <+42>:    mov    $0x0,%eax
   0x0000555555555198 <+47>:    callq  0x555555555060 <printf@plt>
   0x000055555555519d <+52>:    mov    $0x0,%eax
   0x00005555555551a2 <+57>:    pop    %rbp
   0x00005555555551a3 <+58>:    retq   
End of assembler dump.
```

Then we can disass the address of myAdd@plt to see the coressponding assembly code. According to the previous `info file` command, we can find that this code located at the section .plt.sec. `jmpq *0x2f55(%rip)` means the value stored at 0x2f55 + %rip is an address and CPU will jump to that address and execute the coressponding instruction. At the address 0x0000555555555074, we find that the process will jump to the address stored at 0x2f55(%rip) which means that the location address is stored at 0x2f55 + $rip = 0x2f55 + 0x000055555555507b = 0x555555557fd0. This is exactly the address of the myAdd@got.plt as the comment shows.

```shell
(gdb) disass 0x555555555070
Dump of assembler code for function myAdd@plt:
   0x0000555555555070 <+0>:     endbr64 
   0x0000555555555074 <+4>:     bnd jmpq *0x2f55(%rip)        # 0x555555557fd0 <myAdd@got.plt>
   0x000055555555507b <+11>:    nopl   0x0(%rax,%rax,1)
End of assembler dump.
```

According to the previous `info file` command, we can find the following code located at the section .got. Then we use `disass` command to see the assembly code of myAdd@got.plt. Note that GOT entry stores the absolute logical address of the process. This job is done by the linker. As the `x` command shows, the value stored at address 0x0000555555557fd0 is 0x00007ffff7fc50f9. If you use the `si` command to run the program one instruction by one instruction, you will see that the program will directly jump to the location of myAdd function in librelocs.so from the myAdd@plt.

```shell
(gdb) disass 0x555555557fd0
Dump of assembler code for function myAdd@got.plt:
   0x0000555555557fd0 <+0>:     stc    
   0x0000555555557fd1 <+1>:     push   %rax
   0x0000555555557fd2 <+2>:     cld    
   0x0000555555557fd3 <+3>:     idiv   %edi
   0x0000555555557fd5 <+5>:     jg     0x555555557fd7 <myAdd@got.plt+7>
   0x0000555555557fd7 <+7>:     add    %al,(%rax)
End of assembler dump.

(gdb) x/gx 0x555555557fd0
0x555555557fd0 <myAdd@got.plt>: 0x00007ffff7fc50f9
```

If you `disass myAdd`, you will find that the address 0x00007ffff7fc50f9 stored at 0x2f55(%rip) will point to the address of the text of myAdd function.

```shell
(gdb) disass myAdd
Dump of assembler code for function myAdd:
=> 0x00007ffff7fc50f9 <+0>:     endbr64 
   0x00007ffff7fc50fd <+4>:     push   %rbp
   0x00007ffff7fc50fe <+5>:     mov    %rsp,%rbp
   0x00007ffff7fc5101 <+8>:     mov    %edi,-0x4(%rbp)
   0x00007ffff7fc5104 <+11>:    mov    %esi,-0x8(%rbp)
   0x00007ffff7fc5107 <+14>:    mov    -0x4(%rbp),%edx
   0x00007ffff7fc510a <+17>:    mov    -0x8(%rbp),%eax
   0x00007ffff7fc510d <+20>:    add    %edx,%eax
   0x00007ffff7fc510f <+22>:    pop    %rbp
   0x00007ffff7fc5110 <+23>:    retq   
End of assembler dump.
```

## References

[Preprocessing, compiling, assembling and linking](https://www.tenouk.com/ModuleW.html)

[ELF Format](https://saltyfish123.github.io/ELF_Format/)
