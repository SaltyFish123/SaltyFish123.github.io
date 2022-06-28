---
layout: post
title: C++ Type Dedution
date: 2022-06-24
categories: C++
tags: Effective_Modern_C++
---

## Item 1 Understanding Template Type Deduction

We can think of a function template as looking like this:

```cpp
template<typename T>
void f(ParamType param);
```

A call can look like this:

```cpp
f(expr);    // call f with some expression
```

During compilation, compilers use expr to deduce two types: one for T and one for ParamType. These types are frequently different, because ParamType often contains adornments, e.g., const or reference qualifiers. For example, if the template is declared like this,

```cpp
template<typename T>
void f(const T& param);  // ParamType is const T&
```

and we have this call,

```cpp
int x = 0;
f(x);      // call f with an int
```

T is deduced to be int, but ParamType is deduced to be const int&. It’s natural to expect that the type deduced for T is the same as the type of the argument passed to the function, i.e., that T is the type of expr. In the above example, that’s the case: x is an int, and T is deduced to be int. But it doesn’t always work that way. The type deduced for T is dependent not just on the type of expr, but also on the form of ParamType. There are three cases:

* ParamType is a pointer or reference type, but not a universal reference. (Universal references are described in Item 24. At this point, all you need to know is that they exist and that they’re not the same as lvalue references or rvalue references.)
* ParamType is a universal reference.
* ParamType is neither a pointer nor a reference.

### Case 1: ParamType is a Reference or Pointer, but not a Universal Reference

For example

```cpp
template<typename T>
void f(T& param);   // param is a reference

int x = 27; // x is an int
const int cx = x;  // cx is a const int
const int& rx = x;  // rx is a reference to x as a const int

f(x); // T is int, param's type is int&
f(cx); // T is const int,
        // param's type is const int&
f(rx); // T is const int,
        // param's type is const int&
```

### Case 2: ParamType is a Universal Reference

Things are less obvious for templates taking universal reference parameters. Such parameters are declared like rvalue references (i.e., in a function template taking a type parameter T, a universal reference’s declared type is T&&), but they behave differently when lvalue arguments are passed in. The complete story is told in Item 24, but here’s the headline version:

* If expr is an lvalue, both T and ParamType are deduced to be lvalue references. That’s doubly unusual. First, it’s the only situation in template type deduction where T is deduced to be a reference. Second, although ParamType is declared using the syntax for an rvalue reference, its deduced type is an lvalue reference.
* If expr is an rvalue, the “normal” (i.e., Case 1) rules apply.

For example:

```cpp
template<typename T>
void f(T&& param); // param is now a universal reference

int x = 27; // as before
const int cx = x; // as before
const int& rx = x; // as before

f(x); // x is lvalue, so T is int&,
        // param's type is also int&

f(cx); // cx is lvalue, so T is const int&,
        // param's type is also const int&

f(rx); // rx is lvalue, so T is const int&,
        // param's type is also const int&

f(27); // 27 is rvalue, so T is int,
        // param's type is therefore int&&
```

Item 24 explains exactly why these examples play out the way they do. The key point here is that the type deduction rules for universal reference parameters are different from those for parameters that are lvalue references or rvalue references. In particular, when universal references are in use, type deduction distinguishes between lvalue arguments and rvalue arguments. That never happens for non-universal references.

### Case 3: ParamType is Neither a Pointer nor a Reference

When ParamType is neither a pointer nor a reference, we’re dealing with pass-by-value. That means that param will be a copy of whatever is passed in—a completely new object.

For example

```cpp
template<typename T>
void f(T param);  // param is now passed by value

int x = 27; // as before
const int cx = x; // as before
const int& rx = x; // as before

f(x); // T's and param's types are both int
f(cx); // T's and param's types are again both int
f(rx); // T's and param's types are still both int
```

Note that even though cx and rx represent const values, param isn’t const. That makes sense. param is an object that’s completely independent of cx and rx—a copy of cx or rx. The fact that cx and rx can’t be modified says nothing about whether param can be. That’s why expr’s constness (and volatileness, if any) is ignored when deducing a type for param: just because expr can’t be modified doesn’t mean that a copy of it can’t be. **It’s important to recognize that const (and volatile) is ignored only for by-value parameters**. As we’ve seen, for parameters that are references-to- or pointers-to-const, the constness of expr is preserved during type deduction. But consider the case where expr is a const pointer to a const object, and expr is passed to a by-value param:

```cpp
template<typename T>
void f(T param); // param is still passed by value
const char* const ptr = "Fun with pointers"; // ptr is const pointer to const object
f(ptr); // pass arg of type const char * const
```

Here, the const to the right of the asterisk declares ptr to be const: ptr can’t be made to point to a different location, nor can it be set to null. (The const to the left of the asterisk says that what ptr points to—the character string—is const, hence can’t be modified.) When ptr is passed to f, the bits making up the pointer are copied into param. As such, the pointer itself (ptr) will be passed by value. In accord with the type deduction rule for by-value parameters, the constness of ptr will be ignored, and the type deduced for param will be `const char*`, i.e., a modifiable pointer to a const character string. The constness of what ptr points to is preserved during type deduction, but the constness of ptr itself is ignored when copying it to create the new pointer, param.

## Item 2: Understand auto Type Deduction

If you’ve read Item 1 on template type deduction, you already know almost everything you need to know about auto type deduction, because, with only one curious exception, auto type deduction is template type deduction.

In Item 1, template type deduction is explained using this general function template

```cpp
template<typename T>
void f(ParamType param);
```

and this general call:

```cpp
f(expr);   // call f with some expression
```

In the call to f, compilers use expr to deduce types for T and ParamType.

**When a variable is declared using auto, auto plays the role of T in the template, and the type specifier for the variable acts as ParamType.** This is easier to show than to describe, so consider this example:

```cpp
auto x = 27;
```

Here, the type specifier for x is simply auto by itself. On the other hand, in this declaration, the type specifier is const auto.

```cpp
const auto cx = x;
```

And here, the type specifier is const auto&.

```cpp
const auto& rx = x;
```

To deduce types for x, cx, and rx in these examples, compilers act as if there were a template for each declaration as well as a call to that template with the corresponding initializing expression:

```cpp
template<typename T>
void func_for_x(T param); // conceptual template for
                        // deducing x's type
func_for_x(27); // conceptual call: param's
                // deduced type is x's type
template<typename T>
void func_for_cx(const T param); // conceptual template for
                                // deducing cx's type
func_for_cx(x); // conceptual call: param's
                // deduced type is cx's type
template<typename T>
void func_for_rx(const T& param); // conceptual template for
                                  // deducing rx's type
func_for_rx(x); // conceptual call: param's
                // deduced type is rx's type
```

Item 1 divides template type deduction into three cases, based on the characteristics of ParamType, the type specifier for param in the general function template. In a variable declaration using auto, the type specifier takes the place of ParamType, so there are three cases for that, too:

* Case 1: The type specifier is a pointer or reference, but not a universal reference.
* Case 2: The type specifier is a universal reference.
* Case 3: The type specifier is neither a pointer nor a reference.

For example:

```cpp
auto x = 27; // case 3 (x is neither ptr nor reference)
const auto cx = x; // case 3 (cx isn't either)
const auto& rx = x; // case 1 (rx is a non-universal ref.)

auto&& uref1 = x; // x is int and lvalue,
                    // so uref1's type is int&
auto&& uref2 = cx; // cx is const int and lvalue,
                    // so uref2's type is const int&
auto&& uref3 = 27; // 27 is int and rvalue,
                    // so uref3's type is int&&
```

Item 1 concludes with a discussion of how array and function names decay into pointers for non-reference type specifiers. That happens in auto type deduction, too:

```cpp
const char name[] =
"R. N. Briggs"; // name's type is const char[13]
auto arr1 = name; // arr1's type is const char*
auto& arr2 = name; // arr2's type is
                    // const char (&)[13]
void someFunc(int, double); // someFunc is a function;
                            // type is void(int, double)
auto func1 = someFunc; // func1's type is
                        // void (*)(int, double)
auto& func2 = someFunc; // func2's type is
                        // void (&)(int, double)
```

As you can see, auto type deduction works like template type deduction. They’re essentially two sides of the same coin. Except for the one way they differ. We’ll start with the observation that if you want to declare an int with an initial value of 27, C++98 gives you two syntactic choices:

```cpp
int x1 = 27;
int x2(27);
```

C++11, through its support for uniform initialization, adds these:

```cpp
int x3 = {27};
int x4{27};
```

All in all, four syntaxes, but only one result: an int with value 27.

But as Item 5 explains, there are advantages to declaring variables using auto instead of fixed types, so it’d be nice to replace int with auto in the above variable declarations. Straightforward textual substitution yields this code:

```cpp
auto x1 = 27;
auto x2(27);
auto x3 = {27};
auto x4{27};
```

These declarations all compile, but they don’t have the same meaning as the ones they replace. The first two statements do, indeed, declare a variable of type int with value 27. The second two, however, declare a variable of type std::initializer_list\<int\> containing a single element with value 27!

```cpp
auto x1 = 27; // type is int, value is 27
auto x2(27); // ditto
auto x3 = { 27 }; // type is std::initializer_list<int>,
                  // value is { 27 }
auto x4{ 27 }; // ditto
```

**This is due to a special type deduction rule for auto. When the initializer for an auto-declared variable is enclosed in braces, the deduced type is a std::initializer_list**. If such a type can’t be deduced (e.g., because the values in the braced initializer are of different types), the code will be rejected:

```cpp
auto x5 = { 1, 2, 3.0 };   // error! can't deduce T for
                           // std::initializer_list<T>
```

As the comment indicates, type deduction will fail in this case, but it’s important to recognize that there are actually two kinds of type deduction taking place. One kind stems from the use of auto: x5’s type has to be deduced. Because x5’s initializer is in braces, x5 must be deduced to be a std::initializer_list. But std::initializer_list is a template. Instantiations are std::initializer_list\<T\> for some type T, and that means that T’s type must also be deduced. Such deduction falls under the purview of the second kind of type deduction occurring here: template type deduction. In this example, that deduction fails, because the values in the braced initializer don’t have a single type.

**The treatment of braced initializers is the only way in which auto type deduction and template type deduction differ**. When an auto–declared variable is initialized with a braced initializer, the deduced type is an instantiation of std::initializer_list. But if the corresponding template is passed the same initializer, type deduction fails, and the code is rejected:

```cpp
auto x = { 11, 23, 9 }; // x's type is
                        // std::initializer_list<int>

template<typename T>
void f(T param); // template with parameter
                // declaration equivalent to
                // x's declaration

f({ 11, 23, 9 }); // error! can't deduce type for T
```

However, if you specify in the template that param is a std::initializer_list\<T\> for some unknown T, template type deduction will deduce what T is:

```cpp
template<typename T>
void f(std::initializer_list<T> initList);
f({ 11, 23, 9 });   // T deduced as int, and initList's
                    // type is std::initializer_list<int>
```

**So the only real difference between auto and template type deduction is that auto assumes that a braced initializer represents a std::initializer_list, but template type deduction doesn’t**.

For C++11, this is the full story, but for C++14, the tale continues. C++14 permits auto to indicate that a function’s return type should be deduced (see Item 3), and C++14 lambdas may use auto in parameter declarations. However, these uses of auto employ template type deduction, not auto type deduction. **So a function with an auto return type that returns a braced initializer won’t compile**:

```cpp
auto createInitList()
{
  return { 1, 2, 3 };  // error: can't deduce type
}                      // for { 1, 2, 3 }
```

The same is true when auto is used in a parameter type specification in a C++14 lambda:

```cpp

std::vector<int> v;
...
auto resetV =
[&v](const auto& newValue) { v = newValue; };  // C++14
...
resetV({ 1, 2, 3 });    // error! can't deduce type
                        // for { 1, 2, 3 }
```

## Item3: Understand Decltype

In contrast to what happens during type deduction for templates and auto (see Items 1 and 2), decltype typically parrots back the exact type of the name or expression you give it:

```cpp
const int i = 0; // decltype(i) is const int
bool f(const Widget& w); // decltype(w) is const Widget&
                        // decltype(f) is bool(const Widget&)

struct Point {
    int x, y;      // decltype(Point::x) is int
};                 // decltype(Point::y) is int

Widget w; // decltype(w) is Widget
if (f(w)) ... // decltype(f(w)) is bool

template<typename T>    // simplified version of std::vector
class vector {
public:
...
T& operator[](std::size_t index);
...
};
vector<int> v;          // decltype(v) is vector<int>
...
if (v[0] == 0) ...      // decltype(v[0]) is int&
```

In C++11, perhaps the primary use for decltype is declaring function templates where the function’s return type depends on its parameter types. For example, suppose we’d like to write a function that takes a container that supports indexing via square brackets (i.e., the use of “[]”) plus an index, then authenticates the user before returning the result of the indexing operation. The return type of the function should be the same as the type returned by the indexing operation. operator[] on a container of objects of type T typically returns a T&. This is the case for std::deque, for example, and it’s almost always the case for std::vector. For std::vector\<bool\>, however, operator[] does not return a bool&. Instead, it returns a brand new object. The whys and hows of this situation are explored in Item 6, but what’s important here is that the type returned by a container’s operator[] depends on the container. decltype makes it easy to express that. Here’s a first cut at the template we’d like to write, showing the use of decltype to compute the return type. The template needs a bit of refinement, but we’ll defer that for now:

```cpp
template<typename Container, typename Index>
auto authAndAccess(Container& c, Index i)
    -> decltype(c[i])
{
    authenticateUser();
    return c[i];
}
```

With this declaration, authAndAccess returns whatever type operator[] returns when applied to the passed-in container, exactly as we desire. C++11 permits return types for single-statement lambdas to be deduced, and C++14 extends this to both all lambdas and all functions, including those with multiple statements. In the case of authAndAccess, that means that in C++14 we can omit the trailing return type, leaving just the leading auto. With that form of declaration, auto does mean that type deduction will take place. In particular, it means that compilers will deduce the function’s return type from the function’s implementation:

```cpp
template<typename Container, typename Index>
auto authAndAccess(Container& c, Index i)
{
    authenticateUser();
    return c[i];
}
```

Item 2 explains that for functions with an auto return type specification, compilers employ template type deduction. In this case, that’s problematic. As we’ve discussed, operator[] for most containers-of-T returns a T&, but Item 1 explains that during template type deduction, the reference-ness of an initializing expression is ignored. Consider what that means for this client code:

```cpp
std::deque<int> d;
...
authAndAccess(d, 5) = 10;  // authenticate user, return d[5],
                        // then assign 10 to it;
                        // this won't compile!
```

Here, d[5] returns an int&, but auto return type deduction for authAndAccess will strip off the reference, thus yielding a return type of int. That int, being the return value of a function, is an rvalue, and the code above thus attempts to assign 10 to an rvalue int. That’s forbidden in C++, so the code won’t compile. To get authAndAccess to work as we’d like, we need to use decltype type deduction for its return type, i.e., to specify that authAndAccess should return exactly the same type that the expression c[i] returns. The guardians of C++, anticipating the need to use decltype type deduction rules in some cases where types are inferred, make this possible in C++14 through the decltype(auto) specifier. What may initially seem contradictory (decltype and auto?) actually makes perfect sense: auto specifies that the type is to be deduced, and decltype says that decltype rules should be used during the deduction. We can thus write authAndAccess like this:

```cpp
template<typename Container, typename Index>
decltype(auto)
authAndAccess(Container& c, Index i)
{
    authenticateUser();
    return c[i];
}
```

Now authAndAccess will truly return whatever c[i] returns. In particular, for the common case where c[i] returns a T&, authAndAccess will also return a T&, and in the uncommon case where c[i] returns an object, authAndAccess will return an object, too. The use of decltype(auto) is not limited to function return types. It can also be convenient for declaring variables when you want to apply the decltype type deduction rules to the initializing expression:

```cpp
Widget w;
const Widget& cw = w;
auto myWidget1 = cw;    // auto type deduction:
                        // myWidget1's type is Widget

decltype(auto) myWidget2 = cw;  // decltype type deduction:
                                // myWidget2's type is
                                // const Widget&
```

Applying decltype to a name yields the declared type for that name. Names are lvalue expressions, but that doesn’t affect decltype’s behavior. For lvalue expressions more complicated than names, however, decltype ensures that the type reported is always an lvalue reference. That is, if an lvalue expression other than a name has type T, decltype reports that type as T&. This seldom has any impact, because the type of most lvalue expressions inherently includes an lvalue reference qualifier. Functions returning lvalues, for example, always return lvalue references. There is an implication of this behavior that is worth being aware of, however. In

```cpp
int x = 0;
```

x is the name of a variable, so decltype(x) is int. But wrapping the name x in parentheses—“(x)”—yields an expression more complicated than a name. Being a name, x is an lvalue, and C++ defines the expression (x) to be an lvalue, too. decltype((x)) is therefore int&. Putting parentheses around a name can change the type that decltype reports for it!

In C++11, this is little more than a curiosity, but in conjunction with C++14’s support for decltype(auto), it means that a seemingly trivial change in the way you write a return statement can affect the deduced type for a function:

```cpp
decltype(auto) f1()
{
    int x = 0;
    ...
    return x; // decltype(x) is int, so f1 returns int
}
decltype(auto) f2()
{
    int x = 0;
    ...
    return (x);   // decltype((x)) is int&, so f2 returns int&
}
```

Note that not only does f2 have a different return type from f1, it’s also returning a reference to a local variable. The primary lesson is to pay very close attention when using decltype(auto). Seemingly insignificant details in the expression whose type is being deduced can affect the type that decltype(auto) reports. To ensure that the type being deduced is the type you expect, use the techniques described in Item 4.

## Item4: Know How to View Deduced Types

The choice of tools for viewing the results of type deduction is dependent on the phase of the software development process where you want the information. We’ll explore three possibilities: getting type deduction information as you edit your code, getting it during compilation, and getting it at runtime.

1. IDE Editors
2. Compiler Diagnostics
3. Runtime Output

Code editors in IDEs often show the types of program entities (e.g., variables, parameters, functions, etc.) when you do something like hover your cursor over the entity.

An effective way to get a compiler to show a type it has deduced is to use that type in a way that leads to compilation problems.

Suppose, for example, we’d like to see the types that were deduced for x and y. We first declare a class template that we don’t define. Something like this does nicely:

```cpp
const int theAnswer = 42;
auto x = theAnswer;
auto y = &theAnswer;

template<typename T> // declaration only for TD;
class TD;            // TD == "Type Displayer"
```

Attempts to instantiate this template will elicit an error message, because there’s no template definition to instantiate. To see the types for x and y, just try to instantiate TD with their types:

```cpp
TD<decltype(x)> xType; // elicit errors containing
TD<decltype(y)> yType; // x's and y's types
```

Then the compiler will print out the error message of the compilation error. The error message will look something like this:

```cpp
error: aggregate 'TD<int> xType' has incomplete type and cannot be defined
error: aggregate 'TD<const int *> yType' has incomplete type and cannot be defined
```

For runtime output, the printf approach to displaying type information (not that I’m recommending you use printf) can’t be employed until runtime, but it offers full control over the formatting of the output. The challenge is to create a textual representation of the type you care about that is suitable for display. In our continuing quest to see the types deduced for x and y, you may figure we can write this:

```cpp
std::cout << typeid(x).name() << '\n'; // display types for
std::cout << typeid(y).name() << '\n'; // x and y
```

This approach relies on the fact that invoking typeid on an object such as x or y yields a std::type_info object, and std::type_info has a member function, name, that produces a C-style string (i.e., a const char*) representation of the name of the type. The GNU and Clang compilers report that the type of x is “i”, and the type of y is “PKi”, for example.

Consider a more complex example:

```cpp
template<typename T> // template function to
void f(const T& param); // be called

std::vector<Widget> createVec(); // factory function
const auto vw = createVec(); // init vw w/factory return
if (!vw.empty()) {
    f(&vw[0]);
...
}
```

This code, which involves a user-defined type (Widget), an STL container (std::vector), and an auto variable (vw), is more representative of the situations where you might want some visibility into the types your compilers are deducing. For example, it’d be nice to know what types are inferred for the template type parameter T and the function parameter param in f.

Loosing typeid on the problem is straightforward. Just add some code to f to display the types you’d like to see:

```cpp
template<typename T>
void f(const T& param)
{
    using std::cout;
    cout << "T = " << typeid(T).name() << '\n'; // show T
    cout << "param = " << typeid(param).name() << '\n'; // show param
                                                      //type
}
```

Executables produced by the GNU and Clang compilers produce this output:

```cpp
T =     PK6Widget
param = PK6Widget
```

We already know that for these compilers, PK means “pointer to const,” so the only mystery is the number 6. That’s simply the number of characters in the class name that follows (Widget). So these compilers tell us that both T and param are of type const Widget*.

However, as we can see that the type specifier of declaration of f is const T&, it is strange that both T and param are of type const Widget*.

Sadly, the results of std::type_info::name are not reliable. In this case, for example, the type that all three compilers report for param are incorrect. Furthermore, they’re essentially required to be incorrect, because the specification for std::type_info::name mandates that the type be treated as if it had been passed to a template function as a by-value parameter. As Item 1 explains, that means that if the type is a reference, its reference-ness is ignored, and if the type after reference removal is const (or volatile), its constness (or volatileness) is also ignored. That’s why param’s type—which is const Widget \* const &—is reported as const Widget*. First the type’s reference-ness is removed, and then the constness of the resulting pointer is eliminated. Equally sadly, the type information displayed by IDE editors is also not reliable—or at least not reliably useful.
