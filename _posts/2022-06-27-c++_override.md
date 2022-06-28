---
layout: post
title: C++ override
date: 2022-06-27
categories: C++
tags: C++_keywords Effective_Modern_C++
---

For overriding to occur, several requirements must be met:

* The base class function must be virtual.
* The base and derived function names must be identical (except in the case of destructors).
* The parameter types of the base and derived functions must be identical.
* The constness of the base and derived functions must be identical.
* The return types and exception specifications of the base and derived functions must be compatible.

To these constraints, which were also part of C++98, C++11 adds one more:

* The functions’ reference qualifiers must be identical. Member function reference qualifiers are one of C++11’s less-publicized features, so don’t be surprised if you’ve never heard of them. They make it possible to limit use of a member function to lvalues only or to rvalues only. Member functions need not be virtual to use them:

```cpp
class Widget {
public:
...
void doWork() &;    // this version of doWork applies
                    // only when *this is an lvalue

void doWork() &&;   // this version of doWork applies
                    // only when *this is an rvalue
};
...
Widget makeWidget(); // factory function (returns rvalue)
Widget w;           // normal object (an lvalue)
...
w.doWork();             // calls Widget::doWork for lvalues
                        // (i.e., Widget::doWork &)
makeWidget().doWork();  // calls Widget::doWork for rvalues
                        // (i.e., Widget::doWork &&)
```

Because declaring derived class overrides is important to get right, but easy to get wrong, C++11 gives you a way to make explicit that a derived class function is supposed to override a base class version: declare it override. Applying this to the example above would yield this derived class:

```cpp
class Base {
public:
  virtual void mf1() const;
  virtual void mf2(int x);
  virtual void mf3() &;
  void mf4() const;
};

class Derived: public Base {
public:
  virtual void mf1() override;
  virtual void mf2(unsigned int x) override;
  virtual void mf3() && override;
  virtual void mf4() const override;
};
```

This won’t compile, of course, because when written this way, compilers will kvetch about all the overriding-related problems. That’s exactly what you want, and it’s why you should declare all your overriding functions override.

A policy of using override on all your derived class overrides can do more than just enable compilers to tell you when would-be overrides aren’t overriding anything. It can also help you gauge the ramifications if you’re contemplating changing the signature of a virtual function in a base class. If derived classes use override everywhere, you can just change the signature, recompile your system, see how much damage you’ve caused (i.e., how many derived classes fail to compile), then decide whether the signature change is worth the trouble.
