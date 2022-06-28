---
layout: post
title: C++ shared_ptr
date: 2022-06-24
categories: C++
tags: C++_data_types
---

An object’s control block is set up by the function creating the first std::shared_ptr to the object. At least that’s what’s supposed to happen. In general, it’s impossible for a function creating a std::shared_ptr to an object to know whether some other std::shared_ptr already points to that object, so the following rules for control block creation are used:

* std::make_shared always creates a control block. It manufactures a new object to point to, so there is certainly no control block for that object at the time std::make_shared is called.
* A control block is created when a std::shared_ptr is constructed from a unique-ownership pointer (i.e., a std::unique_ptr or std::auto_ptr). Unique-ownership pointers don’t use control blocks, so there should be no control block for the pointed-to object. (As part of its construction, the std::shared_ptr assumes ownership of the pointed-to object, so the unique-ownership pointer is set to null.)
* When a std::shared_ptr constructor is called with a raw pointer, it creates a control block. If you wanted to create a std::shared_ptr from an object that already had a control block, you’d presumably pass a std::shared_ptr or a std::weak_ptr as a constructor argument, not a raw pointer. std::shared_ptr constructors taking std::shared_ptrs or std::weak_ptrs as constructor arguments don’t create new control blocks, because they can rely on the smart pointers passed to them to point to any necessary control blocks.

A consequence of these rules is that constructing more than one std::shared_ptr from a single raw pointer gives you a complimentary ride on the particle accelerator of undefined behavior, because the pointed-to object will have multiple control blocks. Multiple control blocks means multiple reference counts, and multiple reference counts means the object will be destroyed multiple times (once for each reference count).

```cpp
auto pw = new Widget; // pw is raw ptr

std::shared_ptr<Widget> spw1(pw, loggingDel); // create control
                                            // block for *pw

std::shared_ptr<Widget> spw2(pw, loggingDel); // create 2nd
                                            // control block
                                            // for *pw!
```
