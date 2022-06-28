---
layout: post
title: C++ template
date: 2022-06-23
categories: C++
tags: C++_keywords
---

## C++ template function

Explicit instantiation differs from explicit specialization. Explicit instantiation means that the template should create an instance function definition that use the explicit data type. And Explicit specicalization means that the template function should not create any instance. It should use a specific function definition that the code is different from the template definitoin. The following code demonstrates.

```cpp
template<typename T>
void Swap(T& a, T& b);

template void Swap<int>(int, int);  //Explicit instantiation
template <> void Swap<int>(int, int); //Explicit specialization
```

Notice that in the same cpp file, if you want to use explicit instantiation and explicit specialization for the same data type then there will be a compile error. And also take care that if you want to seperate the declaration and implementation of the template class and template function, you should explicit instantiation the type T and you can only use the type that you explicit instantiation. Because templates are compiled when required, this forces a restriction for multi-file projects: the implementation (definition) of a template class or function must be in the coressponding cpp files. Or there will be a link error. For example, as the following code shows:

```cpp
//in A.h
template<typename T>
T bigger(T lhs, T rhs);

//in A.cpp
template<typename T>
T bigger(T lhs, T rhs) {
    return (lhs >= rhs) ? lhs : rhs;
}

//If you comment out the following code, you will get a link error.
template int bigger(int, int);

//in main.cpp
#include "A.h"

int main(int argc, char* argv[]) {
    bigger(10, 20);
    return 0;
}
```

If you don't explicit instantiate the `bigger` template function with type int in the A.cpp file and use it in the main.cpp. then you wil get a linker error for "undefined reference to `int bigger<int>(int, int)'". You can read these [solutions](https://stackoverflow.com/questions/495021/why-can-templates-only-be-implemented-in-the-header-file) to learn more about this question.

There are more details about the template function, you can watch this [post](https://docs.microsoft.com/en-us/cpp/cpp/templates-cpp?view=msvc-170).

It is also useful to use the template deduction to get the size of the array. If we pass an array variable to the function as an argument, the parameter inside the function body will decay to a pointer without the information of the array size. To solve this problem, we can use the non-type parameter template instantiation. As the following code shows:

```cpp
template<size_t N>
void printBits(const bytes& byte, const unsigned char(&mask)[N]) {
    cout << "The bits of " << byte.value << " is ";
    for (auto i : byte.value_arr) {
        for (int j = 0; j < N; j++) {
            cout << ((i & mask[j]) > 0) ? 1 : 0;
        }
    }
    cout << endl;
}
```

As the above code shows, if the size of `mask` we pass to the function is 10 then compiler will create an instantiation `void printBits(const bytes& byte, const unsigned char(&mask)[10])`. If the size of `mask` we pass to the function is 100 then compiler will create an instantiation `void printBits(const bytes& byte, const unsigned char(&mask)[100])`. Notice that these two instantiation are different one parameter type is `const unsigned char(&)[10]` and the other is `const unsigned char(&)[100]`.

## C++ template class

Partial specialization is used for template class or struct. As the following code shows:

```cpp
template<typename T>
class person {

};

// Partical specialization for pointer type.
template<typename T>
class person<T*> {

};

// Compile error
// A template argument list is not allowed
// in a declaration of a primary template
template<typename T>
class animal<T*> {

};
```

A template argument list is not allowed in a declaration of a primary template. So we can't just simply specific the pointer type of the template without the primary template declaration.
