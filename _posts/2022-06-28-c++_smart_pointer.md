---
layout: post
title: C++ Smart Pointers
date: 2022-06-28
categories: C++
tags: C++_std Effective_Modern_C++
---

## shared_ptr

There’s a control block for each object managed by std::shared_ptrs.

![shared_ptr control block](https://github.com/SaltyFish123/SaltyFish123.github.io/blob/master/_posts/images/c++_notes/shared_ptr_control_block.png?raw=true)

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

There are at least two lessons regarding std::shared_ptr use here. First, try to avoid passing raw pointers to a std::shared_ptr constructor. The usual alternative is to use std::make_shared (see Item 21), but in the example above, we’re using custom deleters, and that’s not possible with std::make_shared. Second, if you must pass a raw pointer to a std::shared_ptr constructor, pass the result of new directly instead of going through a raw pointer variable.

## weak_ptr

std::weak_ptrs can’t be dereferenced, nor can they be tested for nullness. That’s because std::weak_ptr isn’t a standalone smart pointer. It’s an augmentation of std::shared_ptr.

One of most useful usecase of weak_ptr is to prevent the shraed_ptr cycle. As the following code shows:

```cpp
class resource {
public:
    std::shared_ptr<resource> pres;
    //std::weak_ptr<resource> pres; // If pres is a weak_ptr, it will not increase the reference count
    resource() {cout << "resource constucted" << endl;}
    ~resource() {cout << "resource destructed" << endl;}
};

int main(int argc, char* argv[]) {
    auto res1 = std::make_shared<resource>();
    res1->res = res1;
    return 0;
}
```

You will find that the output of this program is only "resource constucted" without "resource destructed". That's because the reference count of the resource is 2 and res1 is now leaked. Because weak_ptr will not increase the reference count, it will prevent the cycle and everything will be fine.

## Item 21: Prefer std::make_unique and std::make_shared to direct use of new.

Let’s begin by leveling the playing field for std::make_unique and std:: make_shared. std::make_shared is part of C++11, but, sadly, std::make_unique isn’t. It joined the Standard Library as of C++14.

One important reason that prefering the make functions rather that the new operator is that make functions acquire one step while the new operator acquires two steps. As the following code shows:

```cpp
std::shared_ptr<Widget> spw(new Widget);
auto spw = std::make_shared<Widget>();
```

For the new operator, compiler will run the "new Widget" first, then the shared_ptr constructor. For the make functions, the compiler will only run the make function. So if there is an exception happens after the "new Widget" but before the constructor of shared_ptr, the object will be leaked.

A special feature of std::make_shared (compared to direct use of new) is improved efficiency. Using std::make_shared allows compilers to generate smaller, faster code that employs leaner data structures. Consider the following direct use of new:

```cpp
std::shared_ptr<Widget> spw(new Widget);
```

It’s obvious that this code entails a memory allocation, but it actually performs two. One is for the Widget object, and the other is for the control block. However for the following code:

```cpp
auto spw = std::make_shared<Widget>();
```

Only one memory allocation is required. That’s because std::make_shared allocates a single chunk of memory to hold both the Widget object and the control block. This optimization reduces the static size of the program, because the code contains only one memory allocation call, and it increases the speed of the executable code, because memory is allocated only once.

However, since the make function allocate one buffer for both the objcet and the control block. And the control block not only contain the refernce count, but also the weak count.(weak count is the number of weak_ptra pointing to the object.) As long as std::weak_ptrs refer to a control block (i.e., the weak count is greater than zero), that control block must continue to exist. And as long as a control block exists, the memory containing it must remain allocated. The memory allocated by a std::shared_ptr make function, then, can’t be deallocated until the last std::shared_ptr and the last std::weak_ptr referring to it have been destroyed. If the object type is quite large and the time between destruction of the last std::shared_ptr and the last std::weak_ptr is significant, a lag can occur between when an object is destroyed and when the memory it occupied is freed. In this situation, it is considered a good idea to use new operation instead of std::make_shared.
