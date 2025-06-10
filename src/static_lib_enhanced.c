#include "static_lib.h"
#include <stdio.h>

// Regular function that will be used
int used_function(int x) {
    return x * 2;
}

// Function that won't be called but should remain visible
__attribute__((used))
__attribute__((visibility("default")))
__attribute__((section(".custom_functions")))
int unused_but_visible_function(int x, int y) {
    printf("This function is not called but should be visible in symbols\n");
    return x + y;
}

// Global variable that should remain visible
__attribute__((used))
__attribute__((visibility("default")))
__attribute__((section(".custom_data")))
int global_visible_variable = 42;

// Function pointer that should remain visible
__attribute__((used))
__attribute__((visibility("default")))
int (*function_pointer)(int) = used_function;

// Embed symbol names as strings in a custom section
__attribute__((used))
__attribute__((section(".symbol_names")))
static const char symbol_names[] = 
    "unused_but_visible_function\0"
    "global_visible_variable\0"
    "function_pointer\0"
    "END_SYMBOLS\0";

// Create a symbol table that survives stripping
// We'll store addresses at runtime using constructor
__attribute__((used))
__attribute__((section(".custom_symtab")))
static struct {
    unsigned long addr_unused_func;
    unsigned long addr_global_var;
    unsigned long addr_func_ptr;
    char magic[16];
} custom_symbol_table = {
    .addr_unused_func = 0,  // Will be filled at runtime
    .addr_global_var = 0,   // Will be filled at runtime
    .addr_func_ptr = 0,     // Will be filled at runtime
    .magic = "SYMBOLS_HERE"
};

// Alternative approach: embed addresses as data
__attribute__((used))
__attribute__((section(".address_table")))
static const struct {
    char name1[32];
    unsigned long addr1;
    char name2[32]; 
    unsigned long addr2;
    char name3[32];
    unsigned long addr3;
} address_table = {
    .name1 = "unused_but_visible_function",
    .addr1 = (unsigned long)unused_but_visible_function,
    .name2 = "global_visible_variable", 
    .addr2 = (unsigned long)&global_visible_variable,
    .name3 = "function_pointer",
    .addr3 = (unsigned long)&function_pointer
};

// Create a simple symbol registry that can be parsed after stripping
__attribute__((used))
__attribute__((section(".symbol_registry")))
static const char symbol_registry[] = 
    "SYMBOL_START\n"
    "unused_but_visible_function\n"
    "global_visible_variable\n" 
    "function_pointer\n"
    "SYMBOL_END\n";

// Constructor to fill in runtime addresses
__attribute__((constructor))
__attribute__((used))
static void library_init(void) {
    // Fill in the runtime addresses
    custom_symbol_table.addr_unused_func = (unsigned long)unused_but_visible_function;
    custom_symbol_table.addr_global_var = (unsigned long)&global_visible_variable;
    custom_symbol_table.addr_func_ptr = (unsigned long)&function_pointer;
    
    // Force references to prevent optimization
    volatile void* refs[] = {
        (void*)unused_but_visible_function,
        (void*)&global_visible_variable,
        (void*)&function_pointer,
        (void*)symbol_names,
        (void*)&custom_symbol_table,
        (void*)&address_table,
        (void*)symbol_registry
    };
    (void)refs; // Prevent unused variable warning
} 