---
layout: post
title: C++ explicit keyword
date: 2022-06-22
categories: C++
tags: C++_keywords
---

* TOC
{:toc}

在c++中，explicit建议用于构造函数的声明，如下所示

```c++
class A {
public:
    explicit A(int);
    explicit A();
};

void doSomething(A a);

int main(int argc, char* argv[]) {
    doSomeThing(10);      //错误，因为构造函数被声明为explicit，所以int不能隐式转换成class A类型。
    doSomeThing(A(10));   //可以正确运行
}
```

在c++中，explicit关键字用于构造函数的声明，而不是用于构造函数的定义。通过在类构造函数的声明中使用explicit关键字，可以确保构造函数的使用者必须显式指定构造函数的类型，避免隐式转换。
