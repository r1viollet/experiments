#ifndef STATIC_LIB_H
#define STATIC_LIB_H

// Function that will be called (normal case)
int used_function(int x);

// Function that will NOT be called but should remain visible
int unused_but_visible_function(int x, int y);

// Variable that should remain visible
extern int global_visible_variable;

// Function pointer that should remain visible
extern int (*function_pointer)(int);

#endif // STATIC_LIB_H 