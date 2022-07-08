---
layout: post
title: C++ std::move and std::forward
date: 2022-06-24
categories: C++
tags: C++_std
---

* TOC
{:toc}

At first, it is important to learn about move semantics and perfect forwarding.

* Move semantics makes it possible for compilers to replace expensive copying operations with less expensive moves. In the same way that copy constructors and copy assignment operators give you control over what it means to copy objects, move constructors and move assignment operators offer control over the semantics of moving. Move semantics also enables the creation of move-only types, such as std::unique_ptr, std::future, and std::thread.
* Perfect forwarding makes it possible to write function templates that take arbitrary arguments and forward them to other functions such that the target functions receive exactly the same arguments as were passed to the forwarding functions.

Notice that parameters inside a function definition are always lvalues even their data types are rvalue references. For example:

```cpp
void f(int&& w); //parameter w is a lvalue inside the void f(int&&) body even w itself is a rvalue reference.
```

The std::remove_reference is used to extract the data type that without the reference with the member **type**. As the following code shows.

```cpp
/// remove_reference
  template<typename _Tp>
    struct remove_reference
    { typedef _Tp   type; };

  template<typename _Tp>
    struct remove_reference<_Tp&>
    { typedef _Tp   type; };

  template<typename _Tp>
    struct remove_reference<_Tp&&>
    { typedef _Tp   type; };
```

In fact, both std::move and std::forward functions are a type cast function. As the following code show:

```cpp
// In the move.h

/**
   *  @brief  Forward an lvalue.
   *  @return The parameter cast to the specified type.
   *
   *  This function is used to implement "perfect forwarding".
   */
  template<typename _Tp>
    constexpr _Tp&&
    forward(typename std::remove_reference<_Tp>::type& __t) noexcept
    { return static_cast<_Tp&&>(__t); }

  /**
   *  @brief  Forward an rvalue.
   *  @return The parameter cast to the specified type.
   *
   *  This function is used to implement "perfect forwarding".
   */
  template<typename _Tp>
    constexpr _Tp&&
    forward(typename std::remove_reference<_Tp>::type&& __t) noexcept
    {
      static_assert(!std::is_lvalue_reference<_Tp>::value, "template argument"
            " substituting _Tp is an lvalue reference type");
      return static_cast<_Tp&&>(__t);
    }

  /**
   *  @brief  Convert a value to an rvalue.
   *  @param  __t  A thing of arbitrary type.
   *  @return The parameter cast to an rvalue-reference to allow moving it.
  */
  template<typename _Tp>
    constexpr typename std::remove_reference<_Tp>::type&&
    move(_Tp&& __t) noexcept
    { return static_cast<typename std::remove_reference<_Tp>::type&&>(__t); }
```

Unlike std::move() that unconditionally casts its arguments to rvalue reference, std::forward() does it only under certain conditions. It is often used with the template. As the following code shows:

```cpp
void print(const string&) {
    cout << "This is the first func" << endl;
}
void print(string&&) {
    cout << "This is the second func" << endl;
}

template<typename T>
void p(T&& name) {
    print(forward<T>(name));
}

int main(int argc, char* argv[]) {
    string text = "123";
    p(text); // This will call the first function, T is string&
    p(move(text)); // This will call the second function, T is string
}
```

**T&&** is the universal reference. We can pass both lvalue reference and rvalue reference as the argument. However, the parameter **name** is always a lvalue. So we can't just simply pass the **name** parameter to print(). If we want to run the coressponding print overload, then we should use forward. It will cast name from the typename T.

Notice that neither std::move nor std::forward do anything at runtime since there are constexpr keyword with their definition.
