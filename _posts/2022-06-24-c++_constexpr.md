---
layout: post
title: C++ const and constexpr
date: 2022-06-24
categories: C++
tags: C++_keywords Effective_Modern_C++
---

The keyword constexpr was introduced in C++11 and improved in C++14. It means constant expression. Like const, it can be applied to variables: A compiler error is raised when any code attempts to modify the value. Unlike const, constexpr can also be applied to functions and class constructors.

The primary difference between const and constexpr variables is that the initialization of a const variable can be deferred until run time. A constexpr variable must be initialized at compile time. All constexpr variables are const.

A constexpr function or constructor is implicitly inline. Such functions produce compile-time constants when they are called with compile-time constants. If they’re called with values not known until runtime, they produce runtime values.

```cpp
constexpr int j = 10;
int k = 2;
constexpr int i = j + 10;//Ok since j is a constant.
constexpr int m = k + 10;//Compile error since k is not constant.
```

Usage scenarios for constexpr objects become more interesting when constexpr functions are involved. Such functions produce compile-time constants when they are called with compile-time constants. If they’re called with values not known until runtime, they produce runtime values.

* constexpr functions can be used in contexts that demand compile-time constants. If the values of the arguments you pass to a constexpr function in such a context are known during compilation, the result will be computed during compilation. If any of the arguments’ values is not known during compilation, your code will be rejected.
* When a constexpr function is called with one or more values that are not known during compilation, it acts like a normal function, computing its result at runtime. This means you don’t need two functions to perform the same operation, one for compile-time constants and one for all other values. The constexpr function does it all.

As the following code shows:

```cpp
constexpr                           // pow's a constexpr func
int pow(int base, int exp) noexcept // that never throws
{                                   // impl is below
...
}

constexpr auto numConds = 5; // # of conditions
std::array<int, pow(3, numConds)> results;  // results has
                                            // 3^numConds
                                            // elements
```

Recall that the constexpr in front of pow doesn’t say that pow returns a const value, it says that if base and exp are compile-time constants, pow’s result may be used as a compile-time constant. If base and/or exp are not compile-time constants, pow’s result will be computed at runtime. That means that pow can not only be called to do things like compile-time-compute the size of a std::array, it can also be called in runtime contexts such as this:

```cpp
auto base = readFromDB("base");
auto exp = readFromDB("exponent");  // get these values
                                    // at runtime
auto baseToExp = pow(base, exp); // call pow function
                                 // at runtime
```

In C++11, all built-in types except void qualify, but user-defined types may be literal, too, because constructors and other member functions may be constexpr:

```cpp
class Point {
public:
  constexpr Point(double xVal = 0, double yVal = 0) noexcept
  : x(xVal), y(yVal)
  {}
  constexpr double xValue() const noexcept { return x; }
  constexpr double yValue() const noexcept { return y; }
  void setX(double newX) noexcept { x = newX; }
  void setY(double newY) noexcept { y = newY; }
private:
    double x, y;
};
```

Here, the Point constructor can be declared constexpr, because if the arguments passed to it are known during compilation, the value of the data members of the con‐structed Point can also be known during compilation. Points so initialized could thus be constexpr:

```cpp
constexpr Point p1(9.4, 27.7);  // fine, "runs" constexpr
                                // ctor during compilation
constexpr Point p2(28.8, 5.3);  // also fine
```

In C++11, two restrictions prevent Point’s member functions setX and setY from being declared constexpr. First, they modify the object they operate on, and in C++11, constexpr member functions are implicitly const. Second, they have void return types, and void isn’t a literal type in C++11. Both these restrictions are lifted in C++14, so in C++14, even Point’s setters can be constexpr:

```cpp
class Point {
public:
...
  constexpr void setX(double newX) noexcept  // C++14
  { x = newX; }
  constexpr void setY(double newY) noexcept  // C++14
  { y = newY; }
...
};

// return reflection of p with respect to the origin (C++14)
constexpr Point reflection(const Point& p) noexcept
{
  Point result;              // create non-const Point
  result.setX(-p.xValue());
  result.setY(-p.yValue());  // set its x and y values
  return result;             // return copy of it
}

//Client code could look like this:

constexpr Point p1(9.4, 27.7);      // as above
constexpr Point p2(28.8, 5.3);
constexpr auto mid = midpoint(p1, p2);
constexpr auto reflectedMid =       // reflectedMid's value is
reflection(mid);                    // (-19.1 -16.5) and known
                                    // during compilation
```

## References

[const vs constexpr](https://stackoverflow.com/questions/14116003/difference-between-constexpr-and-const)

[constexpr introduction](https://docs.microsoft.com/en-us/cpp/cpp/constexpr-cpp?view=msvc-160)

[when to use constexpr](https://stackoverflow.com/questions/4748083/when-should-you-use-constexpr-capability-in-c11)