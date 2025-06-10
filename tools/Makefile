CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2
TARGET = enhanced_symbol_recovery
SOURCE = enhanced_symbol_recovery.c

.PHONY: all clean help

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

clean:
	rm -f $(TARGET)

help:
	@echo "Available targets:"
	@echo "  all     - Build the enhanced symbol recovery tool"
	@echo "  clean   - Remove built binaries"
	@echo "  help    - Show this help message"
	@echo ""
	@echo "Usage:"
	@echo "  make"
	@echo "  ./$(TARGET) <stripped_binary>" 