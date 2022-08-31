---
layout: post
title: C++ Pointer and Reference
date: 2022-06-23
categories: C++
tags: C++_data_types
---

* TOC
{:toc}

## Difference of being function parameters between pointer and reference

Take a look at the following code:

```cpp
template<typename T>
//When T is int[4], the template function will create an instance like this
//template void printArr<int[4]>(const int (&arr)[4], int size)
void printArr(const T& _arr, int size) {
    // The type of arr now is const int[4]&
    cout << "The size of arr is "
        <<sizeof(_arr)/sizeof(int) << endl;
    for (int i = 0; i < size; i++) {
        cout << arr[i] << " ";
    }
    cout << endl;
}

int main(int argc, char* argv[]) {
    int arr[]{1, 2, 3, 4};
    const int size = sizeof(arr)/sizeof(int);
    cout << "size of arr is " << sizeof(arr) << " before calling func" << endl;
    printArr<int[size]>(arr, size);//Typename T is int[4] 
    return 0;
}
```

Note that if we have a function like **void printArr(const int _arr[], int size)** and we pass an argument **int arr[]{1, 2, 3, 4}** to the function. Though the data type of argument `arr` is int[4], when we pass it to the printArr function the local variable _arr inside the function body will decays into a pointer. So sizeof(arr) is sizeof(int)*4 = 16 in the main function while sizeof(_arr) is sizeof(int\*) = 8 in the printArr function.

So if we just simply pass array type to a function it will decays into a pointer, even though you explicitly declare the size of the array parameter like **int _arr[4]**. If we don't want this happen, we can set the parameter data type of the function to be a reference of an array as the above code shows. Note that the array size must be constant, so it is convenient to use the template function to create an implicit instance rather than we explicitly specialize the coressponding definition for different size of array.

In this way, we can create an easy template function to get the array size at compile time. The following code demonstrates it.

```cpp
template<typename T, std::size_t N>
constexpr std::size_t get_array_size(T (&)[N]) noexcept {
    return N;
}

```

Notice that the difference between **T& [N]** and **T (&)[N]**. **T& [N]** means an array of data type **T&** with size N. It is an array of reference and this is not allowed. **T (&)[N]** means that it is a reference of an array **T [N]** whose data type is T and size is N.

Arrays aren't the only things in C++ that can decay into pointers. Function types can decay into function pointers, and everything we've discussed regarding type deduction for arrays applies to type deduction for functions and their decay into function pointers. This rarely makes any difference in practice, but if you're going to know about array-to-pointer decay, you might as well know about function-to-pointer decay, too. As the following code shows:

```cpp
// someFunc is a function;
// type is void(int, double)
void someFunc(int, double);

template<typename T>
void f1(T param); // in f1, param passed by value
template<typename T>
void f2(T& param); // in f2, param passed by ref
f1(someFunc); // param deduced as ptr-to-func;
// type is void (*)(int, double)
f2(someFunc); // param deduced as ref-to-func;
// type is void (&)(int, double)
```

One more interesting thing about the c++ ponter is that for a 64 bits CPU, the c++ pointer uses only 48 bits. This is because the current AMD64 architecture is just defined to have 48bit of virtual address space (as can be seen by e.g. cat /proc/cpuinfo on linux)

[参考链接](https://stackoverflow.com/questions/57483/what-are-the-differences-between-a-pointer-variable-and-a-reference-variable-in?page=1&tab=votes#tab-top)

## C++ Universal Reference and rvalue reference

Both universal Reference and rvalue reference have the same format as **T&&**. And universal Reference will appear in the following two scenes. One is the fucntion tempalte parameter and the other is the auto declration. What these scenes have in common is the presence of type deduction. As the following code shows:

```cpp
template<typename T>
void f(T&& param); // param is a universal reference

template<typename T>
void f(const T&& param); // param is a rvalue reference to const

template<class T, class Allocator = allocator<T> >
class vector {
public:
void push_back(T&& x); 
// x is a rvalue reference since vector will create a explicit instantiation
// and there is no type deduction.
};

auto&& var2 = var1; //var2 is a universal reference
```

Notice that the universal reference must be exactly **T&&**. Or it will be a rvalue reference. And there must be a type deduction for the type **T**. As the following code shows:

```cpp
template<typename T>
void f(std::vector<T>&& param);  // param is an rvalue reference
void f(const T&& param);         // param is an rvalue reference
```

When f is invoked, the type T will be deduced. But the form of param's type declaration isn't "T&&", it's "std::vector<T>&&". That rules out the possibility that param is a universal reference. param is therefore an rvalue reference. Even the simple presence of a const qualifier is enough to disqualify a reference from being universal.

It is similar to the situation that auto is used. Variables declared with the type auto&& are universal references because type deduction takes place and they have the correct form ("T&&").

We should use std::move() for the rvalue reference and std::forward() for the universal reference. So that we can avoid the undefined behaviour if we cast a non movable reference to a rvalue reference with the universal reference.

## Item28: Understand reference collapsing.

As the following code shows:

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

If we pass text to p(T&& name), we can see that T is deduced as string& and the function p is p(string& && name). A reference to a reference, which is forbidden for user. When compilers generate references to references, **reference collapsing** dictates what happens next.

There are two kinds of references (lvalue and rvalue), so there are four possible reference-reference combinations (lvalue to lvalue, lvalue to rvalue, rvalue to lvalue, and rvalue to rvalue). If a reference to a reference arises in a context where this is permitted (e.g., during template instantiation), the references collapse to a single reference according to this rule:

* If either reference is an lvalue reference, the result is an lvalue reference. Otherwise (i.e., if both are rvalue references) the result is an rvalue reference.
