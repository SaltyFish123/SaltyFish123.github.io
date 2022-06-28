---
layout: post
title: C++ std::move and std::forward
date: 2022-06-24
categories: C++
tags: C++_std
---

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
    p(text); // This will call the first function
    p(move(text)); // This will call the second function
}
```

**T&&** is the universal reference. We can pass both lvalue reference and rvalue reference as the argument. However, the parameter **name** is always a lvalue. So we can't just simply pass the **name** parameter to print(). If we want to run the coressponding print overload, then we should use forward. It will cast name from the typename T.

Notice that neither std::move nor std::forward do anything at runtime since there are constexpr keyword with their definition.
