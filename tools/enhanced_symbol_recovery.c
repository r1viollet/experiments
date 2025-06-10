#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <elf.h>
#include <sys/mman.h>
#include <sys/stat.h>

void parse_address_table(void* map, Elf64_Shdr* shdr) {
    printf("  Parsing address table:\n");
    
    // The address table structure:
    // char name1[32]; unsigned long addr1; char name2[32]; unsigned long addr2; ...
    char* data = (char*)map + shdr->sh_offset;
    size_t offset = 0;
    int symbol_count = 0;
    
    while (offset < shdr->sh_size && symbol_count < 10) {
        // Read symbol name (32 bytes)
        char name[33] = {0};
        memcpy(name, data + offset, 32);
        offset += 32;
        
        if (offset + 8 > shdr->sh_size) break;
        
        // Read address (8 bytes)
        unsigned long addr = *(unsigned long*)(data + offset);
        offset += 8;
        
        if (strlen(name) > 0) {
            printf("    Symbol: %-30s Address: 0x%016lx\n", name, addr);
            symbol_count++;
        }
        
        if (offset >= shdr->sh_size) break;
    }
}

void parse_symbol_names(void* map, Elf64_Shdr* shdr) {
    printf("  Symbol names found:\n");
    char* data = (char*)map + shdr->sh_offset;
    size_t pos = 0;
    int count = 0;
    
    while (pos < shdr->sh_size && count < 20) {
        if (data[pos] != '\0') {
            char* name = data + pos;
            printf("    [%d] %s\n", count++, name);
            pos += strlen(name) + 1;
        } else {
            pos++;
        }
    }
}

void parse_symbol_registry(void* map, Elf64_Shdr* shdr) {
    printf("  Symbol registry:\n");
    char* data = (char*)map + shdr->sh_offset;
    
    // Null-terminate and print
    char* registry = malloc(shdr->sh_size + 1);
    memcpy(registry, data, shdr->sh_size);
    registry[shdr->sh_size] = '\0';
    
    printf("    %s", registry);
    free(registry);
}

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
    
    printf("=== SYMBOL RECOVERY FROM %s ===\n", filename);
    
    // Check if symbols exist in regular symbol table
    printf("\n1. Regular symbol table check:\n");
    int has_symbols = 0;
    for (int i = 0; i < ehdr->e_shnum; i++) {
        if (shdr[i].sh_type == SHT_SYMTAB || shdr[i].sh_type == SHT_DYNSYM) {
            has_symbols = 1;
            break;
        }
    }
    printf("   Regular symbols: %s\n", has_symbols ? "PRESENT" : "STRIPPED");
    
    printf("\n2. Custom sections analysis:\n");
    int found_sections = 0;
    
    for (int i = 0; i < ehdr->e_shnum; i++) {
        char* name = strtab + shdr[i].sh_name;
        
        if (strstr(name, "custom") || strstr(name, "symbol") || strstr(name, "address")) {
            printf("\n  Section: %s\n", name);
            printf("    Offset: 0x%lx, Size: %lu bytes\n", shdr[i].sh_offset, shdr[i].sh_size);
            found_sections++;
            
            if (strcmp(name, ".symbol_names") == 0) {
                parse_symbol_names(map, &shdr[i]);
            }
            else if (strcmp(name, ".address_table") == 0) {
                parse_address_table(map, &shdr[i]);
            }
            else if (strcmp(name, ".symbol_registry") == 0) {
                parse_symbol_registry(map, &shdr[i]);
            }
            else if (strcmp(name, ".custom_symtab") == 0) {
                printf("    Magic string check: ");
                char* data = (char*)map + shdr[i].sh_offset;
                if (shdr[i].sh_size >= 16) {
                    char magic[17] = {0};
                    memcpy(magic, data + shdr[i].sh_size - 16, 16);
                    printf("'%s'\n", magic);
                }
            }
            else if (strcmp(name, ".custom_functions") == 0) {
                printf("    Contains function code (%lu bytes)\n", shdr[i].sh_size);
            }
            else if (strcmp(name, ".custom_data") == 0) {
                printf("    Contains data: ");
                if (shdr[i].sh_size >= 4) {
                    int* data = (int*)((char*)map + shdr[i].sh_offset);
                    printf("%d (0x%x)\n", *data, *data);
                }
            }
        }
    }
    
    printf("\n3. Summary:\n");
    printf("   Custom sections found: %d\n", found_sections);
    printf("   Symbol recovery: %s\n", found_sections > 0 ? "POSSIBLE" : "FAILED");
    
    if (found_sections > 0) {
        printf("\n✅ SUCCESS: Symbols can be recovered from custom sections even after stripping!\n");
    } else {
        printf("\n❌ FAILURE: No custom sections found for symbol recovery.\n");
    }
    
cleanup:
    munmap(map, st.st_size);
    close(fd);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Enhanced Symbol Recovery Tool\n");
        printf("Usage: %s <elf_file>\n", argv[0]);
        printf("\nThis tool recovers symbol information from stripped binaries\n");
        printf("by analyzing custom sections that survive the stripping process.\n");
        return 1;
    }
    
    find_custom_sections(argv[1]);
    return 0;
} 