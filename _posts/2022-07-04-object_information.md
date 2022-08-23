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

Here I will note some useful option of objdump.

## objdump

For `objdump`, the `-h` option will display print all the section header.

The `-d` option will display the assembler mnemonics for the machine instructions from the input file. This option only disassembles those sections which are expected to contain instructions. If you specific the symbol with `--disassemble=funcname` option can be used to disassemble the function with symbol name `funcname`. Notice that in C++ the overload is allowed since the function name is mangled so you can't just simply use the function name as with C but the coressponding symbol name. For example, suppose the following code:

```c++
#include <iostream>

void testBinarySplit() {
    int min = 0, max = 100;
    int middle;
    middle = (min + max) / 2;
    middle = (unsigned int)min + (unsigned int)max >> 1;
}

int main(int argc, char* argv[]) {
    testBinarySplit();
    return 0;
}
```

Suppose we compile the output `temp.exe`. If we simply run the command `objdump --disassemble=testBinarySplit temp.exe`, we can find that there is no assembler code displayed to the screen. Because the symbol name of function `testBinarySplit` is mangled by the c++ compiler(e.g., g++). We should first find the symbol name of `testBinarySplit`.

Note that the `-t` option will display the symbols of the executable file. So we can run the command as `objdump -t temp.exe | grep testBinarySplit`. Then we can get the result as the following line shows:

```bash
$ objdump -t temp.exe | grep testBinarySplit
00000000000040fb g     F .text  000000000000003a              _Z15testBinarySplitv
```

`_Z15testBinarySplitv` is the symbol of function `testBinarySplit`. So now we can get the disassembler code now:

```bash
$ objdump --disassemble=_Z15testBinarySplitv temp.exe

temp.exe:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .plt.sec:

Disassembly of section .text:

00000000000040fb <_Z15testBinarySplitv>:
    40fb:       f3 0f 1e fa             endbr64 
    40ff:       55                      push   %rbp
    4100:       48 89 e5                mov    %rsp,%rbp
    4103:       c7 45 f4 00 00 00 00    movl   $0x0,-0xc(%rbp)
    410a:       c7 45 f8 64 00 00 00    movl   $0x64,-0x8(%rbp)
    4111:       8b 55 f4                mov    -0xc(%rbp),%edx
    4114:       8b 45 f8                mov    -0x8(%rbp),%eax
    4117:       01 d0                   add    %edx,%eax
    4119:       89 c2                   mov    %eax,%edx
    411b:       c1 ea 1f                shr    $0x1f,%edx
    411e:       01 d0                   add    %edx,%eax
    4120:       d1 f8                   sar    %eax
    4122:       89 45 fc                mov    %eax,-0x4(%rbp)
    4125:       8b 55 f4                mov    -0xc(%rbp),%edx
    4128:       8b 45 f8                mov    -0x8(%rbp),%eax
    412b:       01 d0                   add    %edx,%eax
    412d:       d1 e8                   shr    %eax
    412f:       89 45 fc                mov    %eax,-0x4(%rbp)
    4132:       90                      nop
    4133:       5d                      pop    %rbp
    4134:       c3                      retq   

Disassembly of section .fini:
```

We can also use the `-C` option to demangle the symbol. For instance, as the above steps shows we should first get the demangled function name. However, note that the demangled function name is not the same as the source code function name. Since this demangled function name is decoded from the c++ symbol, which has been mangled by the c++ compiler. As the following command shows:

```bash
$ objdump -Ct temp.exe | grep testBinarySplit
00000000000040fb g     F .text  000000000000003a              testBinarySplit()
```

The decoded function name is `testBinarySplit()` instead of `testBinarySplit`. So we can also run the following command to get the disassembler code of function `testBinarySplit`:

```bash
$ objdump -C --disassemble='testBinarySplit()' temp.exe

temp.exe:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .plt.sec:

Disassembly of section .text:

00000000000040fb <testBinarySplit()>:
    40fb:       f3 0f 1e fa             endbr64 
    40ff:       55                      push   %rbp
    4100:       48 89 e5                mov    %rsp,%rbp
    4103:       c7 45 f4 00 00 00 00    movl   $0x0,-0xc(%rbp)
    410a:       c7 45 f8 64 00 00 00    movl   $0x64,-0x8(%rbp)
    4111:       8b 55 f4                mov    -0xc(%rbp),%edx
    4114:       8b 45 f8                mov    -0x8(%rbp),%eax
    4117:       01 d0                   add    %edx,%eax
    4119:       89 c2                   mov    %eax,%edx
    411b:       c1 ea 1f                shr    $0x1f,%edx
    411e:       01 d0                   add    %edx,%eax
    4120:       d1 f8                   sar    %eax
    4122:       89 45 fc                mov    %eax,-0x4(%rbp)
    4125:       8b 55 f4                mov    -0xc(%rbp),%edx
    4128:       8b 45 f8                mov    -0x8(%rbp),%eax
    412b:       01 d0                   add    %edx,%eax
    412d:       d1 e8                   shr    %eax
    412f:       89 45 fc                mov    %eax,-0x4(%rbp)
    4132:       90                      nop
    4133:       5d                      pop    %rbp
    4134:       c3                      retq   

Disassembly of section .fini:
```

The `-D` option will disassemble the contents of all sections but not only the sections contain instructions.

The `-j name` option can help to display information only for section name. For example, the command `objdump -dj .text temp.o` will only display the disassembly code of the section .text of the obejct file temp.o.

For executable files with debug information(gcc/g++ use the -g option), `-l` option of objdump will try to find the filename and linenumber for each symbol. It is convinient to read the disassemler code of the object file with the help of objdump.

The `-S` option will display source code intermixed with disassembly, if possible. And using it implies using `-d`. We can combine it with `--disassemble=function` to read the disassembler code with the coressponding source code. Note as mentioned above, we can show the disassembler code of function `testBinarySplit`.

```bash
$ objdump -SC --disassemble='testBinarySplit()' temp.exe

temp.exe:     file format elf64-x86-64


Disassembly of section .init:

Disassembly of section .plt:

Disassembly of section .plt.got:

Disassembly of section .plt.sec:

Disassembly of section .text:

00000000000040fb <testBinarySplit()>:
        }
    }
    return res;
}

void testBinarySplit() {
    40fb:       f3 0f 1e fa             endbr64 
    40ff:       55                      push   %rbp
    4100:       48 89 e5                mov    %rsp,%rbp
    int min = 0, max = 100;
    4103:       c7 45 f4 00 00 00 00    movl   $0x0,-0xc(%rbp)
    410a:       c7 45 f8 64 00 00 00    movl   $0x64,-0x8(%rbp)
    int middle;
    middle = (min + max) / 2;
    4111:       8b 55 f4                mov    -0xc(%rbp),%edx
    4114:       8b 45 f8                mov    -0x8(%rbp),%eax
    4117:       01 d0                   add    %edx,%eax
    4119:       89 c2                   mov    %eax,%edx
    411b:       c1 ea 1f                shr    $0x1f,%edx
    411e:       01 d0                   add    %edx,%eax
    4120:       d1 f8                   sar    %eax
    4122:       89 45 fc                mov    %eax,-0x4(%rbp)
    middle = (unsigned int)min + (unsigned int)max >> 1;
    4125:       8b 55 f4                mov    -0xc(%rbp),%edx
    4128:       8b 45 f8                mov    -0x8(%rbp),%eax
    412b:       01 d0                   add    %edx,%eax
    412d:       d1 e8                   shr    %eax
    412f:       89 45 fc                mov    %eax,-0x4(%rbp)
}
    4132:       90                      nop
    4133:       5d                      pop    %rbp
    4134:       c3                      retq   

Disassembly of section .fini:
```

As the above code shows, if the numbers of instructions of `middle = (min + max) / 2;` and `middle = (unsigned int)min + (unsigned int)max >> 1;` are different and it seems that the latter one costs less instructions. So if we want to optimize our code, we can consider using shift operations rather than arithmetic operators.
