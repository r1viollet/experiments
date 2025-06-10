.PHONY: all build test clean tools help demo verify structure

# Default target
all: build

# Build the main project
build:
	@echo "Building symbol preservation example..."
	@mkdir -p build
	@cd build && cmake .. && make

# Run comprehensive tests
test: build
	@echo "Running symbol preservation tests..."
	@./scripts/test_strip_resistance.sh

# Build tools
tools:
	@echo "Building symbol recovery tools..."
	@cd tools && make

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build
	@cd tools && make clean 2>/dev/null || true

# Run the final demonstration
demo: build
	@echo "Running final demonstration..."
	@echo "This will build, strip, and demonstrate symbol recovery..."
	@./scripts/final_demo.sh

# Quick verification
verify: build
	@echo "Running symbol verification..."
	@./scripts/verify_symbols.sh

# Show project structure
structure:
	@echo "Project Structure:"
	@echo "=================="
	@find . -type f -not -path "./build/*" -not -path "./.git/*" | sort

help:
	@echo "Symbol Preservation in Stripped Static Binaries"
	@echo "================================================"
	@echo ""
	@echo "Available targets:"
	@echo "  all        - Build the main project (default)"
	@echo "  build      - Build the main project"
	@echo "  demo       - Run the complete demonstration (builds, strips, recovers)"
	@echo "  test       - Run comprehensive stripping resistance tests"
	@echo "  verify     - Quick symbol verification"
	@echo "  tools      - Build symbol recovery tools"
	@echo "  structure  - Show project file structure"
	@echo "  clean      - Clean all build artifacts"
	@echo "  help       - Show this help message"
	@echo ""
	@echo "Quick start:"
	@echo "  make demo    # Complete demonstration with stripping"
	@echo "  make test    # Comprehensive tests"
	@echo ""
	@echo "The demo will:"
	@echo "  1. Build the project with symbol preservation"
	@echo "  2. Create original and stripped versions"
	@echo "  3. Show symbols before/after stripping"
	@echo "  4. Demonstrate symbol recovery from custom sections" 