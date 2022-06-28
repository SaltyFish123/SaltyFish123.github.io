---
layout: post
title: C++ initialization with () and {}
date: 2022-06-26
categories: C++
tags: Effective_Modern_C++
---

## Item 7: Distinguish between () and {} when creating objects.

Depending on your perspective, syntax choices for object initialization in C++11 embody either an embarrassment of riches or a confusing mess. As a general rule, initialization values may be specified with parentheses, an equals sign, or braces:

```cpp
int x(0); // initializer is in parentheses
int y = 0; // initializer follows "="
int z{ 0 }; // initializer is in braces
```

In many cases, it’s also possible to use an equals sign and braces together:

```cpp
int z = { 0 };  // initializer uses "=" and braces
```

For the remainder of this Item, I’ll generally ignore the equals-sign-plus-braces syntax, because C++ usually treats it the same as the braces-only version.

To address the confusion of multiple initialization syntaxes, as well as the fact that they don’t cover all initialization scenarios, C++11 introduces uniform initialization: a single initialization syntax that can, at least in concept, be used anywhere and express everything. It’s based on braces, and for that reason I prefer the term braced initialization. “Uniform initialization” is an idea. “Braced initialization” is a syntactic construct.

Braced initialization lets you express the formerly inexpressible. Using braces, specifying the initial contents of a container is easy:

```cpp
std::vector<int> v{ 1, 3, 5 }; // v's initial content is 1, 3, 5
```

Braces can also be used to specify default initialization values for non-static data members. This capability—new to C++11—is shared with the “=” initialization syntax, but not with parentheses:

```cpp
class Widget {
...
private:
    int x{ 0 };   // fine, x's default value is 0
    int y = 0;    // also fine
    int z(0);     // error!
};
```

On the other hand, uncopyable objects (e.g., std::atomics—see Item 40) may be initialized using braces or parentheses, but not using “=”:

```cpp
std::atomic<int> ai1{ 0 };  // fine
std::atomic<int> ai2(0); // fine
std::atomic<int> ai3 = 0; // error!
```

A novel feature of braced initialization is that it prohibits implicit **narrowing conversions** among built-in types. If the value of an expression in a braced initializer isn’t guaranteed to be expressible by the type of the object being initialized, the code won’t compile. Initialization using parentheses and “=” doesn’t check for narrowing conversions, because that could break too much legacy code:

```cpp
double x, y, z;
...
int sum1{ x + y + z };  // error! sum of doubles may
                        // not be expressible as int

int sum2(x + y + z);    // okay (value of expression
                        // truncated to an int)
int sum3 = x + y + z;   // ditto
```

Another noteworthy characteristic of braced initialization is its immunity to C++’s **most vexing parse**. A side effect of C++’s rule that anything that can be parsed as a declaration must be interpreted as one, the most vexing parse most frequently afflicts developers when they want to default-construct an object, but inadvertently end up declaring a function instead. The root of the problem is that if you want to call a constructor with an argument, you can do it like this,

```cpp
Widget w1(10);  // call Widget ctor with argument 10
```

but if you try to call a Widget constructor with zero arguments using the analogous syntax, you declare a function instead of an object:

```cpp
Widget w2();   // most vexing parse! declares a function
               // named w2 that returns a Widget!
```

Functions can’t be declared using braces for the parameter list, so default-constructing an object using braces doesn’t have this problem:

```cpp
Widget w3{};  // calls Widget ctor with no args
```

In constructor calls, parentheses and braces have the same meaning as long as std::initializer_list parameters are not involved. If, however, one or more constructors declare a parameter of type std::initializer_list, calls using the braced initialization syntax strongly prefer the overloads taking std::initializer_lists. Strongly. If there’s any way for compilers to construe a call using a braced initializer to be to a constructor taking a std::initial izer_list, compilers will employ that interpretation. Even what would normally be copy and move construction can be hijacked by std::initializer_list constructors. Compilers’ determination to match braced initializers with constructors taking std::initializer_lists is so strong, it prevails even if the best-match std::initializer_list constructor can’t be called. For example:

```cpp
class Widget {
public:
Widget(int i, bool b);
Widget(int i, double d);
Widget(std::initializer_list<bool> il); // element type is
                                        // now bool
...                                     // no implicit
                                        // conversion funcs
};
Widget w{10, 5.0};  // error! requires narrowing conversions
```

Here, compilers will ignore the first two constructors (the second of which offers an exact match on both argument types) and try to call the constructor taking a std::initializer_list\<bool\>. Calling that constructor would require converting an int (10) and a double (5.0) to bools. Both conversions would be narrowing (bool can’t exactly represent either value), and narrowing conversions are prohibited inside braced initializers, so the call is invalid, and the code is rejected.

Only if there’s no way to convert the types of the arguments in a braced initializer to the type in a std::initializer_list do compilers fall back on normal overload resolution. For example, if we replace the std::initializer_list\<bool\> constructor with one taking a std::initializer_list<std::string>, the non-std::initializer_list constructors become candidates again, because there is no way to convert ints and bools to std::strings

This brings us near the end of our examination of braced initializers and constructor overloading, but there’s an interesting edge case that needs to be addressed. Suppose you use an empty set of braces to construct an object that supports default construction and also supports std::initializer_list construction. What do your empty braces mean? If they mean “no arguments,” you get default construction, but if they mean “empty std::initializer_list,” you get construction from a std::initializer_list with no elements. The rule is that you get default construction. Empty braces mean no arguments, not an empty std::initializer_list. If you want to call a std::initializer_list constructor with an empty std::initializer_list, you do it by making the empty braces a constructor argument—by putting the empty braces inside the parentheses or braces demarcating what you’re passing:

```cpp
Widget w4({});  // calls std::initializer_list ctor
                // with empty list
Widget w5{{}};  // ditto
```
