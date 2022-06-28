---
layout: post
title: C++ Value Categories
date: 2022-06-24
categories: C++
tags: C++_data_types
---

The following diagram illustrates the relationships between the categories:

![diagram](https://docs.microsoft.com/en-us/cpp/cpp/media/value_categories.png?view=msvc-160)

The C++17 standard defines expression value categories as follows:

* A glvalue(generalized lvalue) is an expression whose evaluation determines the identity of an object, bit-field, or function.
* A prvalue(pure rvalue) is an expression whose evaluation initializes an object or a bit-field, or computes the value of the operand of an operator, as specified by the context in which it appears.
* An xvalue(eXpiring value) is a glvalue that denotes an object or bit-field whose resources can be reused (usually because it is near the end of its lifetime). Example: Certain kinds of expressions involving rvalue references (8.3.2) yield xvalues, such as a call to a function whose return type is an rvalue reference or a cast to an rvalue reference type.
* An lvalue is a glvalue that is not an xvalue.
* An rvalue is a prvalue or an xvalue.

The following code demonstrates several correct and incorrect usages of lvalues and rvalues.

```cpp
// lvalues_and_rvalues2.cpp
int main()
{
    int i, j, *p;

    // Correct usage: the variable i is an lvalue and the literal 7 is a prvalue.
    i = 7;

    // Incorrect usage: The left operand must be an lvalue (C2106).`j * 4` is a prvalue.
    7 = i; // C2106
    j * 4 = 7; // C2106

    // Correct usage: the dereferenced pointer is an lvalue.
    *p = i;

    // Correct usage: the conditional operator returns an lvalue.
    ((i < 3) ? i : j) = 7;

    // Incorrect usage: the constant ci is a non-modifiable lvalue (C3892).
    const int ci = 7;
    ci = 9; // C3892
}
```

[参考链接](https://en.cppreference.com/w/cpp/language/value_category)
