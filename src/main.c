#include <stdio.h>
#include "static_lib.h"

int main() {
    printf("=== Static Library Symbol Visibility Example ===\n");
    
    // Only use one function from the static library
    int result = used_function(21);
    printf("Result from used_function(21): %d\n", result);
    
    // We intentionally do NOT call:
    // - unused_but_visible_function()
    // - access global_visible_variable
    // - use function_pointer
    // These should still be visible in the final executable's symbol table
    
    printf("\nNote: unused_but_visible_function and other symbols should still be visible\n");
    printf("Check with: readelf -s main_exe | grep -E '(unused_but_visible|global_visible|function_pointer)'\n");
    
    return 0;
} 