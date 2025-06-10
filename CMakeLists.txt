cmake_minimum_required(VERSION 3.16)
project(static_link_symbol_example)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Use Release build for production-like scenario
set(CMAKE_BUILD_TYPE Release)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -O2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -O2")

# Create static library with enhanced symbol preservation
add_library(mystaticlib STATIC
    src/static_lib_enhanced.c
)

# Set properties for the static library
target_include_directories(mystaticlib PUBLIC include)

# Create executable with symbol preservation
add_executable(main_exe
    src/main.c
)

# Link the static library to the executable
target_link_libraries(main_exe mystaticlib)

# Enhanced linker options for symbol preservation
target_link_options(main_exe PRIVATE 
    -Wl,--no-gc-sections          # Don't garbage collect unused sections
    -Wl,--whole-archive           # Include all symbols from static libraries
    $<TARGET_FILE:mystaticlib>
    -Wl,--no-whole-archive
    -Wl,--export-dynamic          # Export all dynamic symbols
    -rdynamic                     # Export symbols for backtrace
)
