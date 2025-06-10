# Symbol Preservation in Stripped Static Binaries

This project demonstrates how to ensure symbols remain discoverable even after static linking and binary stripping. The solution uses custom ELF sections and compiler attributes to embed symbol information that survives the stripping process.

## 🚀 Quick Start

### Run the Complete Demo
```bash
# Clone and run the demonstration
make demo
```

This will:
1. Build the project with symbol preservation
2. Create original and stripped versions  
3. Show symbols before/after stripping
4. Demonstrate symbol recovery from custom sections

### Other Available Commands
```bash
make build    # Build the project
make test     # Run comprehensive tests
make verify   # Quick symbol verification
make tools    # Build symbol recovery tools
make clean    # Clean build artifacts
make demo     # Run the demo to retrieve symbols with a stripped artifact
make help     # Show all available targets
```

### Requirements
- GCC compiler
- CMake 3.16+
- Standard Linux tools (`readelf`, `strip`, `nm`)

**Note**: The project uses Release builds with optimization (`-O2`) to demonstrate symbol preservation in production-like scenarios.

## 🎯 Problem Statement

When linking static libraries:
1. **Dead Code Elimination**: Linkers remove unused symbols to reduce binary size
2. **Symbol Stripping**: The `strip` command removes symbol tables for security/size reasons
3. **Lost Visibility**: Important symbols become invisible to debugging tools (`readelf`, `nm`, `gdb`)

**Goal**: Make symbols discoverable even in stripped binaries without using them in `main()`.

## ✅ Solution Overview

Our solution uses multiple complementary techniques:

### 1. Compiler Attributes
- `__attribute__((used))` - Prevents compiler optimization removal
- `__attribute__((visibility("default")))` - Ensures symbol export visibility  
- `__attribute__((section("name")))` - Places symbols in custom ELF sections
- `__attribute__((constructor))` - Runs initialization code at load time

### 2. Custom ELF Sections
- `.custom_functions` - Contains unused function code
- `.custom_data` - Contains global variables
- `.symbol_names` - String table with symbol names
- `.address_table` - Symbol names paired with their addresses
- `.symbol_registry` - Human-readable symbol list
- `.custom_symtab` - Custom symbol table with magic marker

### 3. Linker Configuration
- `--no-gc-sections` - Prevents garbage collection of unused sections
- `--whole-archive` - Forces inclusion of all symbols from static libraries
- `--export-dynamic` - Exports symbols for dynamic loading

## 📁 Project Structure

```
├── CMakeLists.txt              # Build configuration
├── Makefile                    # Main build targets
├── README.md                   # This file
├── include/
│   └── static_lib.h           # Library header
├── src/
│   ├── static_lib_enhanced.c  # Enhanced static library implementation
│   └── main.c                 # Main executable (uses only one function)
├── tools/
│   ├── Makefile               # Tools build configuration
│   └── enhanced_symbol_recovery.c  # Symbol recovery tool
├── scripts/
│   ├── test_strip_resistance.sh    # Comprehensive stripping test
│   ├── verify_symbols.sh      # Symbol verification
│   └── final_demo.sh          # Complete demonstration
└── build/                     # Build artifacts (auto-generated)
```

## 🔍 Symbol Recovery After Stripping

Even after `strip main_exe`, symbols can be recovered:

### 1. Symbol Names
```bash
readelf -p .symbol_names main_exe_stripped
```
Output:
```
String dump of section '.symbol_names':
  [     0]  unused_but_visible_function
  [    1c]  global_visible_variable
  [    34]  function_pointer
```

### 2. Symbol Addresses
```bash
readelf -x .address_table main_exe_stripped
```
The hex dump contains symbol names and their compile-time addresses.

### 3. Automated Recovery
```bash
make tools
cd tools
./enhanced_symbol_recovery ../build/main_exe_stripped
```

## 📊 Results

| Aspect | Before Stripping | After Stripping | Recovery Method |
|--------|------------------|-----------------|-----------------|
| **Regular Symbols** | ✅ Visible | ❌ Stripped | N/A |
| **Custom Sections** | ✅ Present | ✅ **Preserved** | `readelf -S` |
| **Symbol Names** | ✅ In symtab | ✅ **In .symbol_names** | `readelf -p` |
| **Symbol Addresses** | ✅ In symtab | ✅ **In .address_table** | Custom parser |
| **Function Code** | ✅ In .text | ✅ **In .custom_functions** | `readelf -x` |
| **Global Data** | ✅ In .data | ✅ **In .custom_data** | `readelf -x` |

## 🛠️ Key Implementation Details

### Symbol Preservation Pattern
```c
// Function that survives stripping
__attribute__((used))
__attribute__((visibility("default")))
__attribute__((section(".custom_functions")))
int unused_but_visible_function(int x, int y) {
    return x + y;
}

// Address table that survives stripping
__attribute__((used))
__attribute__((section(".address_table")))
static const struct {
    char name[32];
    unsigned long addr;
} symbol_info = {
    .name = "unused_but_visible_function",
    .addr = (unsigned long)unused_but_visible_function
};
```

### CMake Configuration
```cmake
target_link_options(main_exe PRIVATE 
    -Wl,--no-gc-sections          # Keep all sections
    -Wl,--whole-archive           # Include all symbols
    $<TARGET_FILE:mystaticlib>
    -Wl,--no-whole-archive
    -Wl,--export-dynamic          # Export symbols
)
```

## 🧪 Verification Commands

```bash
# Check if symbols survived stripping
nm main_exe_stripped | grep unused  # Should be empty
readelf -p .symbol_names main_exe_stripped  # Should show symbols

# Verify addresses match original
nm main_exe_original | grep unused_but_visible
# Compare with recovered address from .address_table

# List all custom sections
readelf -S main_exe_stripped | grep custom
```

## 🎯 Use Cases

This technique is valuable for:

- **Debugging Stripped Binaries**: Recover symbol information for crash analysis
- **Reverse Engineering**: Maintain symbol visibility for analysis tools
- **Security Research**: Preserve important function/variable locations
- **Embedded Systems**: Keep debug symbols without bloating the main symbol table
- **Plugin Systems**: Maintain symbol visibility for dynamic loading
- **Forensics**: Recover symbol information from stripped executables

## 🔧 Advanced Techniques

### Custom Symbol Recovery Tool
The `enhanced_symbol_recovery.c` tool demonstrates:
- ELF parsing to find custom sections
- Symbol name extraction from string tables
- Address recovery from embedded data structures
- Verification against original binaries

### Multiple Preservation Strategies
1. **Compile-time embedding** - Addresses baked into binary
2. **Runtime initialization** - Constructor fills address tables
3. **String-based registry** - Human-readable symbol lists
4. **Magic markers** - Verification strings for integrity

## 🚨 Limitations and Considerations

- **Binary Size**: Custom sections increase executable size
- **Security**: Symbols remain visible to analysis tools
- **Compiler Dependency**: Relies on GCC-specific attributes
- **Architecture**: Currently tested on x86_64 Linux
- **Maintenance**: Requires keeping symbol lists synchronized

## 🔄 Compatibility

- **Tested with**: GCC 11.4.0 on Linux
- **Should work with**: GCC 8+, Clang 10+
- **Architectures**: x86_64 (easily portable to others)
- **Systems**: Linux, likely works on other Unix-like systems

## 📚 References

- [ELF Specification](https://refspecs.linuxfoundation.org/elf/elf.pdf)
- [GCC Attributes Documentation](https://gcc.gnu.org/onlinedocs/gcc/Common-Function-Attributes.html)
- [GNU Linker Manual](https://sourceware.org/binutils/docs/ld/)

## 🎉 Conclusion

This project successfully demonstrates that **symbols can be preserved and recovered even from stripped static binaries** using custom ELF sections and compiler attributes. The technique provides a robust solution for maintaining symbol visibility without relying on standard symbol tables.

The key insight is that while `strip` removes symbol tables, it preserves custom sections, allowing us to embed our own symbol information that survives the stripping process. 