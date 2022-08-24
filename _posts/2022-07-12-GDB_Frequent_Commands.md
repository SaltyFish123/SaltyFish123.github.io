---
layout: post
title: GDB Frequent Commands
date: 2022-07-12
categories: Program
tags: Programming_Tools
---

* TOC
{:toc}

I take some notes here for the gdb manual. For more details you can go to the [reference website](https://sourceware.org/gdb/current/onlinedocs/gdb/). This gdb manual is very useful and detailed.

## info files

When you run the gdb with a program, you can use the command `info files` to see the information of the program. You can get the file type of the program and the address space of the sections of the program. For example, as the following code shows you can find that the section .plt.got is located at address from 0x0000555555555060 to 0x0000555555555080. This information can help you disassemble the assembly code of the coressponding section. As the following code shows, the address 0x0000555555555060 and 0x0000555555555070 is the address of the section .plt.got. We can disassemble the address and it will display the coressponding assembly code of function printf@plt and function myAdd@plt.

```shell
(gdb) info file
Symbols from "/home/joey/main.exe".
Local exec file:
        `/home/joey/main.exe', file type elf64-x86-64.
        Entry point: 0x555555555080
        0x0000555555554318 - 0x0000555555554334 is .interp
        0x0000555555554338 - 0x0000555555554358 is .note.gnu.property
        0x0000555555554358 - 0x000055555555437c is .note.gnu.build-id
        0x000055555555437c - 0x000055555555439c is .note.ABI-tag
        0x00005555555543a0 - 0x00005555555543c4 is .gnu.hash
        0x00005555555543c8 - 0x0000555555554488 is .dynsym
        0x0000555555554488 - 0x0000555555554521 is .dynstr
        ...
        0x0000555555555060 - 0x0000555555555080 is .plt.sec
        ...

(gdb) disass 0x0000555555555060
Dump of assembler code for function printf@plt:
   0x0000555555555060 <+0>:     endbr64 
   0x0000555555555064 <+4>:     bnd jmpq *0x2f5d(%rip)        # 0x555555557fc8 <printf@got.plt>
   0x000055555555506b <+11>:    nopl   0x0(%rax,%rax,1)
End of assembler dump.

(gdb) disass 0x0000555555555070
Dump of assembler code for function myAdd@plt:
   0x0000555555555070 <+0>:     endbr64 
   0x0000555555555074 <+4>:     bnd jmpq *0x2f55(%rip)        # 0x555555557fd0 <myAdd@got.plt>
   0x000055555555507b <+11>:    nopl   0x0(%rax,%rax,1)
End of assembler dump.
```

You can get the address of the **entry point** and use the **breakpoint** to get the information of the address. As the following code shows:

```gdb
$ gdb test

(gdb) info files
Local exec file:
    Entry point: 0x44dd00

(gdb) b *0x44dd00
Breakpoint 1 at 0x44dd00: file /usr/local/go/src/runtime/rt0_linux_amd64.s, line 8.
```

When you are debuging the process, you can also use the command info to get symbols by the function name. For example, **info func malloc** to get the symbols that named malloc.

## Check assembler code

When you debug c++ with gdb, you can use the command `disass` to check the assembler code of current source code. For example, you can use `disass test` to see the assembler code of the function `test()`. Then you can also set a break point at a specific instruction addresss like `b *0x0000555555555def`. You can also use `info registers` to read the values of the registers or use `p $rbp` to read the value of a specific register named `rbp`. You can get more information from the references.

## Debug the glibc srouce code

In gdb, we can use the command **set verbose on** to get more information about where gdb read the symbols from. As the following example shows:

```shell
(gdb) set verbose on
(gdb) b main
Breakpoint 1 at 0x1972: file temp.c, line 98.
(gdb) b 74
Breakpoint 2 at 0x184f: file temp.c, line 74.
(gdb) r
Starting program: /home/joey/temp.exe 
Using PIE (Position Independent Executable) displacement 0x555555554000 for "/home/joey/temp.exe".
Reading symbols from /lib64/ld-linux-x86-64.so.2...
Reading symbols from /usr/lib/debug//lib/x86_64-linux-gnu/ld-2.31.so...
Reading symbols from system-supplied DSO at 0x7ffff7fce000...
(No debugging symbols found in system-supplied DSO at 0x7ffff7fce000)
Reading in symbols for rtld.c...done.
Reading symbols from /lib/x86_64-linux-gnu/libc.so.6...
Reading symbols from /usr/lib/debug//lib/x86_64-linux-gnu/libc-2.31.so...

Breakpoint 1, main () at temp.c:98
98      int main(){
```

As an example, suppose we use the libc fucntion `mommove` and `memcpy`. When we compile our code, the compiler won't resolve implementation of the function **memmove**. It only verifies the syntactical checking. The tool chain leaves a stub in our application which will be filled by dynamic linker. Since **memmove** is standard function the compiler implicitly invoking its shared library.

Note that if you try to break in the caller and wish to step into the memmove call, you will fail. Since the implementation of **memmove** is loaded into memory within the shared library by the program. You can use the **ldd** to see the shared library dependencies of the program. For example, the **memmove** is within the libc.so.6 loaded by temp.exe as shown below.

```shell
ldd temp.exe 
        linux-vdso.so.1 (0x00007fffc58b2000)
        libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007fdaf2dc9000)
        /lib64/ld-linux-x86-64.so.2 (0x00007fdaf2fdc000)
```

As the following code shows, suppose we compile this source code to generate a program `temp.exe`.

```c
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

void testMemmoveMemcpy(int tag) {
    char numbers[] = "123456789";
    char *function;
    function = tag == 0 ? "memcpy" : "memmove";
    if (tag) {
        memmove(numbers, numbers + 1, 3);
    }
    else {
        memcpy(numbers, numbers + 4, 3);
    }   
    printf("After executing %s, numbers is %s\n", function, numbers); 
}

int main(int argc, char* argv[]) {
    testMemmoveMemcpy(atoi(argv[1]));
    return 0;
}
```

Then we run the gdb to check the source code of the glibc function `memcopy` and `memmove`.

```shell
$gdb ./temp.exe
============================
// Then step into the gdb process

(gdb) set args 0
(gdb) b testMemmoveMemcpy
Breakpoint 1 at 0x2023: file temp.c, line 380.
(gdb) disass testMemmoveMemcpy
Dump of assembler code for function testMemmoveMemcpy:
=> 0x0000555555556023 <+0>:     endbr64 
   0x0000555555556027 <+4>:     push   %rbp
   0x0000555555556028 <+5>:     mov    %rsp,%rbp
   0x000055555555602b <+8>:     sub    $0x30,%rsp
   0x000055555555602f <+12>:    mov    %edi,-0x24(%rbp)
   0x0000555555556032 <+15>:    mov    %fs:0x28,%rax
   0x000055555555603b <+24>:    mov    %rax,-0x8(%rbp)
   0x000055555555603f <+28>:    xor    %eax,%eax
   0x0000555555556041 <+30>:    movabs $0x3837363534333231,%rax
   0x000055555555604b <+40>:    mov    %rax,-0x12(%rbp)
   0x000055555555604f <+44>:    movw   $0x39,-0xa(%rbp)
   0x0000555555556055 <+50>:    cmpl   $0x0,-0x24(%rbp)
   0x0000555555556059 <+54>:    jne    0x555555556064 <testMemmoveMemcpy+65>
   0x000055555555605b <+56>:    lea    0x11e4(%rip),%rax        # 0x555555557246
   0x0000555555556062 <+63>:    jmp    0x55555555606b <testMemmoveMemcpy+72>
   0x0000555555556064 <+65>:    lea    0x11e2(%rip),%rax        # 0x55555555724d
   0x000055555555606b <+72>:    mov    %rax,-0x20(%rbp)
--Type <RET> for more, q to quit, c to continue without paging--
   0x000055555555606f <+76>:    cmpl   $0x0,-0x24(%rbp)
   0x0000555555556073 <+80>:    je     0x555555556093 <testMemmoveMemcpy+112>
   0x0000555555556075 <+82>:    lea    -0x12(%rbp),%rax
   0x0000555555556079 <+86>:    add    $0x1,%rax
   0x000055555555607d <+90>:    lea    -0x12(%rbp),%rcx
   0x0000555555556081 <+94>:    mov    $0x3,%edx
   0x0000555555556086 <+99>:    mov    %rax,%rsi
   0x0000555555556089 <+102>:   mov    %rcx,%rdi
   0x000055555555608c <+105>:   callq  0x555555555410 <memmove@plt>
   0x0000555555556091 <+110>:   jmp    0x5555555560af <testMemmoveMemcpy+140>
   0x0000555555556093 <+112>:   lea    -0x12(%rbp),%rax
   0x0000555555556097 <+116>:   add    $0x4,%rax
   0x000055555555609b <+120>:   lea    -0x12(%rbp),%rcx
   0x000055555555609f <+124>:   mov    $0x3,%edx
   0x00005555555560a4 <+129>:   mov    %rax,%rsi
   0x00005555555560a7 <+132>:   mov    %rcx,%rdi
   0x00005555555560aa <+135>:   callq  0x5555555553c0 <memcpy@plt>
   0x00005555555560af <+140>:   lea    -0x12(%rbp),%rdx
--Type <RET> for more, q to quit, c to continue without paging--
   0x00005555555560b3 <+144>:   mov    -0x20(%rbp),%rax
   0x00005555555560b7 <+148>:   mov    %rax,%rsi
   0x00005555555560ba <+151>:   lea    0x1197(%rip),%rdi        # 0x555555557258
   0x00005555555560c1 <+158>:   mov    $0x0,%eax
   0x00005555555560c6 <+163>:   callq  0x555555555310 <printf@plt>
   0x00005555555560cb <+168>:   nop
   0x00005555555560cc <+169>:   mov    -0x8(%rbp),%rax
   0x00005555555560d0 <+173>:   xor    %fs:0x28,%rax
   0x00005555555560d9 <+182>:   je     0x5555555560e0 <testMemmoveMemcpy+189>
   0x00005555555560db <+184>:   callq  0x5555555552f0 <__stack_chk_fail@plt>
   0x00005555555560e0 <+189>:   leaveq 
   0x00005555555560e1 <+190>:   retq   
End of assembler dump.
(gdb) b *0x555555555410
Breakpoint 2 at 0x555555555410
(gdb) b *0x5555555553c0
Breakpoint 3 at 0x5555555553c0
(gdb) disass 0x555555555410
Dump of assembler code for function memmove@plt:
   0x0000555555555410 <+0>:     endbr64 
   0x0000555555555414 <+4>:     bnd jmpq *0x3b75(%rip)        # 0x555555558f90 <memmove@got.plt>
   0x000055555555541b <+11>:    nopl   0x0(%rax,%rax,1)
End of assembler dump.
(gdb) x/gx 0x555555558f90
0x555555558f90 <memmove@got.plt>:       0x00007ffff7f476e0
(gdb) disass 0x00007ffff7f476e0
Dump of assembler code for function __memmove_avx_unaligned_erms:
   0x00007ffff7f476e0 <+0>:     endbr64 
   0x00007ffff7f476e4 <+4>:     mov    %rdi,%rax
   0x00007ffff7f476e7 <+7>:     cmp    $0x20,%rdx
   0x00007ffff7f476eb <+11>:    jb     0x7ffff7f47736 <__memmove_avx_unaligned_erms+86>
   0x00007ffff7f476ed <+13>:    cmp    $0x40,%rdx
   0x00007ffff7f476f1 <+17>:    ja     0x7ffff7f47796 <__memmove_avx_unaligned_erms+182>
   0x00007ffff7f476f7 <+23>:    vmovdqu (%rsi),%ymm0
   0x00007ffff7f476fb <+27>:    vmovdqu -0x20(%rsi,%rdx,1),%ymm1
   0x00007ffff7f47701 <+33>:    vmovdqu %ymm0,(%rdi)
   0x00007ffff7f47705 <+37>:    vmovdqu %ymm1,-0x20(%rdi,%rdx,1)
   0x00007ffff7f4770b <+43>:    vzeroupper 
   0x00007ffff7f4770e <+46>:    retq   
   0x00007ffff7f4770f <+47>:    cmp    0x65da2(%rip),%rdx        # 0x7ffff7fad4b8 <__x86_shared_non_temporal_threshold>
   0x00007ffff7f47716 <+54>:    jae    0x7ffff7f47841 <__memmove_avx_unaligned_erms+353>
   0x00007ffff7f4771c <+60>:    cmp    %rsi,%rdi
   0x00007ffff7f4771f <+63>:    jb     0x7ffff7f47730 <__memmove_avx_unaligned_erms+80>
   0x00007ffff7f47721 <+65>:    je     0x7ffff7f47735 <__memmove_avx_unaligned_erms+85>
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(gdb) disass 0x5555555553c0
Dump of assembler code for function memcpy@plt:
   0x00005555555553c0 <+0>:     endbr64 
   0x00005555555553c4 <+4>:     bnd jmpq *0x3b9d(%rip)        # 0x555555558f68 <memcpy@got.plt>
   0x00005555555553cb <+11>:    nopl   0x0(%rax,%rax,1)
End of assembler dump.
(gdb) x/gx 0x555555558f68
0x555555558f68 <memcpy@got.plt>:        0x00007ffff7f476e0
(gdb) r
(gdb) c
Continuing.

Breakpoint 3, 0x00005555555553c0 in memcpy@plt ()
(gdb) s
Single stepping until exit from function memcpy@plt,
which has no line number information.
__memmove_avx_unaligned_erms () at ../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S:225
225     ../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S: No such file or directory
(gdb) dir /home/joey/glibc/sysdeps/x86_64/multiarch
Source directories searched: /home/joey/glibc/sysdeps/x86_64/multiarch:$cdir:$cwd
(gdb) n
226
(gdb) disass
Dump of assembler code for function __memmove_avx_unaligned_erms:
   0x00007ffff7f476e0 <+0>:     endbr64 
=> 0x00007ffff7f476e4 <+4>:     mov    %rdi,%rax
   0x00007ffff7f476e7 <+7>:     cmp    $0x20,%rdx
   0x00007ffff7f476eb <+11>:    jb     0x7ffff7f47736 <__memmove_avx_unaligned_erms+86>
   0x00007ffff7f476ed <+13>:    cmp    $0x40,%rdx
   0x00007ffff7f476f1 <+17>:    ja     0x7ffff7f47796 <__memmove_avx_unaligned_erms+182>
   0x00007ffff7f476f7 <+23>:    vmovdqu (%rsi),%ymm0
   0x00007ffff7f476fb <+27>:    vmovdqu -0x20(%rsi,%rdx,1),%ymm1
   0x00007ffff7f47701 <+33>:    vmovdqu %ymm0,(%rdi)
   0x00007ffff7f47705 <+37>:    vmovdqu %ymm1,-0x20(%rdi,%rdx,1)
   0x00007ffff7f4770b <+43>:    vzeroupper 
   0x00007ffff7f4770e <+46>:    retq   
   0x00007ffff7f4770f <+47>:    cmp    0x65da2(%rip),%rdx        # 0x7ffff7fad4b8 <__x86_shared_non_temporal_threshold>
   0x00007ffff7f47716 <+54>:    jae    0x7ffff7f47841 <__memmove_avx_unaligned_erms+353>
   0x00007ffff7f4771c <+60>:    cmp    %rsi,%rdi
   0x00007ffff7f4771f <+63>:    jb     0x7ffff7f47730 <__memmove_avx_unaligned_erms+80>
   0x00007ffff7f47721 <+65>:    je     0x7ffff7f47735 <__memmove_avx_unaligned_erms+85>
--Type <RET> for more, q to quit, c to continue without paging--q
Quit
(gdb) list
221     # if VEC_SIZE == 16
222     ENTRY (__mempcpy_chk_erms)
223             cmp     %RDX_LP, %RCX_LP
224             jb      HIDDEN_JUMPTARGET (__chk_fail)
225     END (__mempcpy_chk_erms)
226
227     /* Only used to measure performance of REP MOVSB.  */
228     ENTRY (__mempcpy_erms)
229             mov     %RDI_LP, %RAX_LP
230             /* Skip zero length.  */
 ```

Both **memmove** and **memcpy** function is filled into the **PLT** stub at runtime but not called as an external function directly. So we need to read the assembly code about the value that filled into the stub. For example, as the above gdb operations log shows. When we disassemble the function `testMemmoveMemcpy`, we can find out that the CPU will call the function with the address that filled in while runtime. In our example, the address of `memmove@plt` is 0x555555555410 and the address of `memcpy@plt` is 0x5555555553c0. Then we set two breakpoints at these two addresses separately.

As my previous post [Program Creation](https://saltyfish123.github.io/Program_Creation/) mentions, we can jump to the exact executing assembler instruction with the `PLT` address. As the code above shows, after setting two breakpoints, we can first disassemble the 0x555555555410 address. Then we can get the address of `memmove@got.plt` is 0x555555558f90. This address stores the address of the instructions of `memmove`. Then We use the `x` command to get the value stored at 0x555555558f90, which is 0x00007ffff7f476e0. 0x00007ffff7f476e0 is the exact address of the executing instruction of `memmove`. Then we run `disass 0x00007ffff7f476e0` and we can read the assembler code of the function `__memmove_avx_unaligned_erms`.

The above steps repeat for the `memcpy@plt`. It is interesting that we can find out both `memcpy` and `memmove` are implemented by the instructions at address 0x00007ffff7f476e0.

Then we can run our program to read the source code of `__memmove_avx_unaligned_erms`.

However, if we want to `step` into the glibc function  `__memmove_avx_unaligned_erms`, we will find that things don't work as we expecting. We should first download the glibc-source by apt. Then add the glibc source directory path to the gdb source directories with command **directory**. You can use command **show directories** to see which source directories will be searched. If you don't add the glibc source directory path to the gdb source directories, you get prompted that there is no such file or directory. As the above gdb operations record shows, gdb can't not file the source file ../sysdeps/x86_64/multiarch/memmove-vec-unaligned-erms.S from the symbol of memmove. Then we add the path of the glibc source file we downloaded and we can see now gdb can list the source code now.

Note that you should make sure the source code is as the same version as the shared library you link to. Otherwise you will not read the exact srouce code for the debugged process.

## x command

This command is used to display the content of the memory address. For example, if you have an array named `arr` which are `int arr[] = {3, 1, 2}`. Then you can use the x command to display the content of the array as the following code shows:

```c
int main(int argc, char* argv[]) {
    int arr[] = {3, 1, 2};
    return 0;
}
```

```shell
(gdb) p arr
$2 = {3, 1, 2}

(gdb) x/3d arr
0x7fffffffdd1c:	3	1	2

(gdb) x/d arr
0x7fffffffdd1c:	3

(gdb) x/d arr+1
0x7fffffffdd20:	1

(gdb) x/d arr+2
0x7fffffffdd24:	2

(gdb) p &arr
$4 = (int (*)[3]) 0x7fffffffdd1c
```

For more details about the x command, you can take a look at the **reference** at the end of this post.

## Debugging Forks

On some systems, GDB provides support for debugging programs that create additional processes using the fork or vfork functions. On GNU/Linux platforms, this feature is supported with kernel version 2.5.46 and later.

The fork debugging commands are supported in native mode and when connected to gdbserver in either target remote mode or target extended-remote mode.

By default, when a program forks, GDB will continue to debug the parent process and the child process will run unimpeded.

If you want to follow the child process instead of the parent process, use the command **set follow-fork-mode**.

`set follow-fork-mode mode`

Set the debugger response to a program call of fork or vfork. A call to fork or vfork creates a new process. The mode argument can be:

* **parent**. The original process is debugged after a fork. The child process runs unimpeded. This is the default.
* **child**. The new process is debugged after a fork. The parent process runs unimpeded.

`show follow-fork-mode`. Display the current debugger response to a fork or vfork call.

On Linux, if you want to debug both the parent and child processes, use the command set detach-on-fork.

`set detach-on-fork mode`

Whether detach one of the processes after a fork, or retain debugger control over them both.

* **on**. The child process (or parent process, depending on the value of follow-fork-mode) will be detached and allowed to run independently. This is the default.
* **off**. Both processes will be held under the control of GDB. One process (child or parent, depending on the value of follow-fork-mode) is debugged as usual, while the other is held suspended.

`show detach-on-fork`

Show whether detach-on-fork mode is on/off.

If you choose to set ‘detach-on-fork' mode off, then GDB will retain control of all forked processes (including nested forks). You can list the forked processes under the control of GDB by using the info inferiors command, and switch from one fork to another by using the **inferior** command.

To quit debugging one of the forked processes, you can either detach from it by using the detach inferiors command (allowing it to run independently), or kill it using the kill inferiors command.

## Passing arguments to debugged program

If you want to debug a program with command line arguments, you can use the command `set args` or the `--args` option of gdb. As the following code shows:

```shell
gdb --args ./a.out Jeoy 18

//This command will pass two additional arguments to the program. "Joey" and "18"
```

If you have started the gdb with command `gdb ./a.out`, you can use the `set args` arguaments to set the arguemnts before the program is started. As the following code demonstrates:

```shell
(gdb) b main
Breakpoint 1 at 0x167d: file client.c, line 64.
(gdb) set args 127.0.0.1
(gdb) r
Starting program: /home/joey/Study_Notes/Linux_Socket_Programming/src/client 127.0.0.1

Breakpoint 1, main (argc=0, argv=0x7fffffffdb80) at client.c:64
64      int main(int argc, char* argv[]) {
(gdb) n
65          if (argc < 2) {
(gdb) p argc
$1 = 2
(gdb) p argv[1]
$2 = 0x7fffffffdfb8 "127.0.0.1"
```

## References

[gdb disassemble](https://visualgdb.com/gdbreference/commands/disassemble)

[Debugging Forks](https://sourceware.org/gdb/onlinedocs/gdb/Forks.html)

[Debugging Multiple Inferiors Connections and Programs](https://sourceware.org/gdb/onlinedocs/gdb/Inferiors-Connections-and-Programs.html#Inferiors-Connections-and-Programs)

[gdb debug into malloc](https://stackoverflow.com/questions/29955609/include-source-code-of-malloc-c-in-gdb)

[shared library](https://www.geeksforgeeks.org/working-with-shared-libraries-set-2/)

[x command](https://visualgdb.com/gdbreference/commands/x)
