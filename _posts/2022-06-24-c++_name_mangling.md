---
layout: post
title: C++ Name Mangling
date: 2022-06-24
categories: C++
tags: C++_std
---

* TOC
{:toc}

Note that C++ compiler support the **name mangling** while C compiler didn't. Because C++ language supports function overload while C language doesn't. So that's why we need the extern "C" in C++. For example, I write a temp.c as the code shown below:

```c
void print(int *arr[], int rowLen, int colLen) {
    int a[rowLen];
    for (int i = 0; i < rowLen; i++) {
        for (int j = 0; j < colLen; j++) {
            printf("%d ", arr[i][j]);
        }
        printf("\n");
    }
}

void print(void) {
    
}
```

Then I use g++ to compile it and get the output file, temp.exe. Using the command **nm -l temp.exe** to display the symbol information of the temp.exe. **-l** option means that for each symbol, use debugging information to try to find a filename and line number. For a defined symbol, look for the line number of the address of the symbol. For an undefined symbol, look for the line number of a relocation entry which refers to the symbol. If line number information can be found, print it after the other symbol information. So the following code shows, we can find that the symbols of the overloaded print functions are different.

If you try to use the gcc compiler to compile the same code, you will find that an error occur.

```shell

nm --defined-only -l temp.exe

// This is the output of the g++ compiled output file

0000000000001572 T _Z5printPPiii        /home/joey/Documents/c_cpp_code/temp.c:38
00000000000016e6 T _Z5printv    /home/joey/Documents/c_cpp_code/temp.c:48

// This is the output of the gcc compiled output file
0000000000001560 T print        /home/joey/Documents/c_cpp_code/temp.c:38

gcc temp.c -g -o temp.exe

temp.c:48:6: error: conflicting types for ‘print’
   48 | void print(void) {
      |      ^~~~~
temp.c:38:6: note: previous definition of ‘print’ was here
   38 | void print(int *arr[], int rowLen, int colLen) {
```

Ok now let's talk about the extern "C" in C++. If you want to create a C++ shared library that can be used by the C program, then you must use the extern "C" to make sure that the C++ compiler will not mangle the name of the symbol so that the linker can successfully link the correct function implementation by the symbol.
