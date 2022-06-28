---
layout: post
title: C++ Pointer and Reference
date: 2022-06-23
categories: C++
tags: C++_data_types
---

## Difference of being function parameters

Take a look at the following code:

```cpp
template<typename T>
//When T is int[4], the template function will create an instance like this
//template void printArr<int[4]>(const int (&arr)[4], int size)
void printArr(const T& arr, int size) {
    // The type of arr now is const int[4]&
    cout << "The size of arr is "
        <<sizeof(arr)/sizeof(int) << endl;
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

Note that if we have a function like **void printArr(const int arr[], int size)** and we pass an argument **int array[]{1, 2, 3, 4}** to the function. Though the size of argument array is int[4], when we pass it to the printArr function the local variable arr inside the function body will decays into a pointer. So sizeof(array) is sizeof(int)*4 = 16 in the main function while sizeof(arr) is sizeof(int\*) = 8.

So we just simply pass array type to a function it will decays into a pointer, even though you explicitly declare the size of the array parameter like **int arr[4]**. If we don't want this happen, we can set the parameter data type of the function to be a reference of an array as the above code shows. Note that the array size must be constant, so it is convenient to use the template function to create an implicit instance rather than we explicitly specialize the coressponding definition for different size of array.

In this way, we can create an easy template function to get the array size at compile time. The following code demonstrates it.

```cpp
template<typename T, std::size_t N>
constexpr std::size_t get_array_size(T (&)[N]) noexcept {
    return N;
}

```

Notice that the difference between **T& [N]** and **T (&)[N]**. **T& [N]** means an array of data type **T&** with size N. It is an array of reference and this is not allowed. **T (&)[N]** means that it is a reference of an array **T [N]** whose data type is T and size is N.

Arrays aren’t the only things in C++ that can decay into pointers. Function types can decay into function pointers, and everything we’ve discussed regarding type deduction for arrays applies to type deduction for functions and their decay into function pointers. This rarely makes any difference in practice, but if you’re going to know about array-to-pointer decay, you might as well know about function-to-pointer decay, too. As the following code shows:

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

Notice that the universal reference must be exactly **T&&**. All it will be a rvalue reference. And there must be a type deduction for the type **T**.

We should use std::move() for the rvalue reference and std::forward() for the universal reference. So that we can avoid the undefined behaviour if we cast a non movable reference to a rvalue reference with the universal reference.
