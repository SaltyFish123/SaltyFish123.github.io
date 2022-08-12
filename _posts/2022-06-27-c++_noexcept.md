---
layout: post
title: C++ noexcept
date: 2022-06-27
categories: C++
tags: C++_keywords Effective_Modern_C++
---

* TOC
{:toc}

## Item 14: Declare functions noexcept if they won't emit exceptions.

For **stack unwinding**, you can read this [article](https://docs.microsoft.com/en-us/cpp/cpp/exceptions-and-stack-unwinding-in-cpp?view=msvc-170) to get more information.

In a noexcept function, optimizers need not keep the runtime stack in an unwindable state if an exception would propagate out of the function, nor must they ensure that objects in a noexcept function are destroyed in the inverse order of construction should an exception leave the function. Functions with "throw()" exception specifications lack such optimization flexibility, as do functions with no exception specification at all. The situation can be summarized this way:

```cpp
RetType function(params) noexcept; // most optimizable
RetType function(params) throw(); // less optimizable
RetType function(params); // less optimizable
```

The fact of the matter is that most functions are **exception-neutral**. Such functions throw no exceptions themselves, but functions they call might emit one. When that happens, the exception-neutral function allows the emitted exception to pass through on its way to a handler further up the call chain. Exception-neutral functions are never noexcept, because they may emit such "just passing through" exceptions. Most functions, therefore, quite properly lack the noexcept designation.

For some functions, being noexcept is so important, they're that way by default. In C++98, it was considered bad style to permit the memory deallocation functions (i.e., operator delete and operator delete[]) and destructors to emit exceptions, and in C++11, this style rule has been all but upgraded to a language rule. By default, all memory deallocation functions and all destructors—both user-defined and compiler-generated—are implicitly noexcept. There's thus no need to declare them noexcept. (Doing so doesn't hurt anything, it's just unconventional.)
