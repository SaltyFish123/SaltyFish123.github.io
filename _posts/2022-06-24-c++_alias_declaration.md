---
layout: post
title: C++ Alias Declaration
date: 2022-06-24
categories: C++
tags: C++_keywords Effective_Modern_C++
---

* TOC
{:toc}

Prefering alias declaration than typedef. It is much complicated to use typedef for template than the other. As the following code shows:

```cpp
template<typename T>
using MyAllocList = std::list<T, MyAlloc<T> >; // MyAllocList<T>
// is synonym for
// std::list<T, MyAlloc<T> >
MyAllocList<Widget> lw; // client code

template<typename T>                        // MyAllocList<T>::type
struct MyAllocList {                        // is synonym for
    typedef std::list<T, MyAlloc<T> > type; // std::list<T, MyAlloc<T> >
};
MyAllocList<Widget>::type lw;
// client code
```

In the above code both alias declaration and typedef works as the same thing.
