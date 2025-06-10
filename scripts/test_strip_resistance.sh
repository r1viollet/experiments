#!/bin/bash

echo "=== Enhanced Symbol Preservation Test ==="
echo ""

# Clean and rebuild
rm -rf build
mkdir -p build
cd build

echo "Building enhanced version..."
cmake .. && make

if [ $? -ne 0 ]; then
    echo "Build failed!"
    exit 1
fi

echo ""
echo "=== TESTING SYMBOL RECOVERY AFTER STRIPPING ==="
echo ""

# Test both executables
for exe in main_exe main_exe_protected; do
    if [ ! -f "$exe" ]; then
        echo "Skipping $exe (not built)"
        continue
    fi
    
    echo "--- Testing $exe ---"
    
    # Create copies for testing
    cp "$exe" "${exe}_original"
    cp "$exe" "${exe}_stripped"
    
    # Strip the copy
    strip "${exe}_stripped"
    
    echo "Before stripping:"
    echo "  Symbols: $(nm "${exe}_original" 2>/dev/null | grep -E "(unused|visible)" | wc -l)"
    echo "  Custom sections: $(readelf -S "${exe}_original" | grep -E "(custom|symbol)" | wc -l)"
    
    echo "After stripping:"
    echo "  Symbols: $(nm "${exe}_stripped" 2>/dev/null | grep -E "(unused|visible)" | wc -l)"
    echo "  Custom sections: $(readelf -S "${exe}_stripped" | grep -E "(custom|symbol)" | wc -l)"
    
    echo ""
    echo "Custom sections in stripped binary:"
    readelf -S "${exe}_stripped" | grep -E "(custom|symbol)" || echo "  None found"
    
    echo ""
    echo "Extracting symbol information from custom sections:"
    
    # Extract symbol metadata
    if readelf -S "${exe}_stripped" | grep -q ".symbol_metadata"; then
        echo "  Found .symbol_metadata section"
        readelf -x .symbol_metadata "${exe}_stripped" | head -10
    fi
    
    # Extract symbol names
    if readelf -S "${exe}_stripped" | grep -q ".symbol_names"; then
        echo "  Found .symbol_names section"
        readelf -p .symbol_names "${exe}_stripped" 2>/dev/null || readelf -x .symbol_names "${exe}_stripped" | head -5
    fi
    
    # Extract custom symbol table
    if readelf -S "${exe}_stripped" | grep -q ".custom_symtab"; then
        echo "  Found .custom_symtab section"
        readelf -x .custom_symtab "${exe}_stripped" | head -10
    fi
    
    # Look for magic string
    echo "  Searching for magic string 'SYMBOLS_HERE':"
    strings "${exe}_stripped" | grep "SYMBOLS_HERE" || echo "    Not found in strings"
    
    # Try to find embedded assembly symbols
    if readelf -S "${exe}_stripped" | grep -q ".asm_symbols"; then
        echo "  Found .asm_symbols section"
        readelf -x .asm_symbols "${exe}_stripped" | head -10
    fi
    
    echo ""
    echo "Attempting to recover symbol addresses:"
    
    # Try to extract addresses from custom sections
    if readelf -x .custom_symtab "${exe}_stripped" 2>/dev/null | grep -q "0x"; then
        echo "  Custom symbol table contains address data"
        # Parse the hex dump to extract addresses
        readelf -x .custom_symtab "${exe}_stripped" | grep "0x" | head -3
    fi
    
    echo ""
    echo "--- End $exe test ---"
    echo ""
done

echo "=== CREATING SYMBOL RECOVERY TOOL ==="

# Create a simple symbol recovery tool
cat > symbol_recovery.c << 'EOF'
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <elf.h>
#include <sys/mman.h>
#include <sys/stat.h>

void find_custom_sections(const char* filename) {
    int fd = open(filename, O_RDONLY);
    if (fd < 0) {
        perror("open");
        return;
    }
    
    struct stat st;
    if (fstat(fd, &st) < 0) {
        perror("fstat");
        close(fd);
        return;
    }
    
    void* map = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (map == MAP_FAILED) {
        perror("mmap");
        close(fd);
        return;
    }
    
    Elf64_Ehdr* ehdr = (Elf64_Ehdr*)map;
    if (memcmp(ehdr->e_ident, ELFMAG, SELFMAG) != 0) {
        printf("Not an ELF file\n");
        goto cleanup;
    }
    
    Elf64_Shdr* shdr = (Elf64_Shdr*)((char*)map + ehdr->e_shoff);
    char* strtab = (char*)map + shdr[ehdr->e_shstrndx].sh_offset;
    
    printf("Searching for custom sections in %s:\n", filename);
    
    for (int i = 0; i < ehdr->e_shnum; i++) {
        char* name = strtab + shdr[i].sh_name;
        if (strstr(name, "custom") || strstr(name, "symbol")) {
            printf("  Section: %s (offset: 0x%lx, size: %lu)\n", 
                   name, shdr[i].sh_offset, shdr[i].sh_size);
            
            if (strcmp(name, ".symbol_names") == 0) {
                printf("    Symbol names: ");
                char* data = (char*)map + shdr[i].sh_offset;
                for (size_t j = 0; j < shdr[i].sh_size; j++) {
                    if (data[j] == '\0') printf(" | ");
                    else printf("%c", data[j]);
                }
                printf("\n");
            }
            
            if (strcmp(name, ".custom_symtab") == 0) {
                printf("    Symbol addresses:\n");
                unsigned long* addrs = (unsigned long*)((char*)map + shdr[i].sh_offset);
                printf("      unused_func: 0x%lx\n", addrs[0]);
                printf("      global_var:  0x%lx\n", addrs[1]);
                printf("      func_ptr:    0x%lx\n", addrs[2]);
            }
        }
    }
    
cleanup:
    munmap(map, st.st_size);
    close(fd);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Usage: %s <elf_file>\n", argv[0]);
        return 1;
    }
    
    find_custom_sections(argv[1]);
    return 0;
}
EOF

echo "Compiling symbol recovery tool..."
gcc -o symbol_recovery symbol_recovery.c

echo ""
echo "=== TESTING SYMBOL RECOVERY TOOL ==="
for exe in main_exe_stripped main_exe_protected_stripped; do
    if [ -f "$exe" ]; then
        echo "--- Analyzing $exe ---"
        ./symbol_recovery "$exe"
        echo ""
    fi
done

echo "=== TEST COMPLETE ===" 