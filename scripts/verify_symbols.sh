#!/bin/bash

echo "=== Symbol Visibility Verification ==="
echo ""

if [ ! -f "build/main_exe" ]; then
    echo "Error: build/main_exe not found. Run ./build_and_test.sh first."
    exit 1
fi

cd build

echo "1. UNUSED FUNCTIONS THAT REMAIN VISIBLE:"
echo "----------------------------------------"
nm main_exe | grep unused
echo ""

echo "2. GLOBAL VARIABLES THAT REMAIN VISIBLE:"
echo "----------------------------------------"
nm main_exe | grep global_visible
echo ""

echo "3. FUNCTION POINTERS THAT REMAIN VISIBLE:"
echo "-----------------------------------------"
nm main_exe | grep function_pointer
echo ""

echo "4. CUSTOM SECTIONS CREATED:"
echo "---------------------------"
readelf -S main_exe | grep custom
echo ""

echo "5. DETAILED SYMBOL INFORMATION:"
echo "-------------------------------"
echo "Using objdump to show symbols with their sections:"
objdump -t main_exe | grep -E "(unused|visible|function_pointer)"
echo ""

echo "6. SYMBOL ADDRESSES AND SIZES:"
echo "------------------------------"
echo "unused_but_visible_function:"
readelf -s main_exe | grep unused_but_visible | awk '{printf "  Address: 0x%s, Size: %d bytes, Section: %s\n", $2, $3, $7}'

echo "global_visible_variable:"
readelf -s main_exe | grep global_visible | awk '{printf "  Address: 0x%s, Size: %d bytes, Section: %s\n", $2, $3, $7}'

echo "function_pointer:"
readelf -s main_exe | grep function_pointer | awk '{printf "  Address: 0x%s, Size: %d bytes, Section: %s\n", $2, $3, $7}'
echo ""

echo "7. VERIFICATION SUMMARY:"
echo "------------------------"
UNUSED_FUNC=$(nm main_exe | grep -c unused_but_visible_function)
GLOBAL_VAR=$(nm main_exe | grep -c global_visible_variable)
FUNC_PTR=$(nm main_exe | grep -c function_pointer)
CUSTOM_SECTIONS=$(readelf -S main_exe | grep -c custom)

echo "✓ unused_but_visible_function: $UNUSED_FUNC symbol(s) found"
echo "✓ global_visible_variable: $GLOBAL_VAR symbol(s) found"
echo "✓ function_pointer: $FUNC_PTR symbol(s) found"
echo "✓ Custom sections: $CUSTOM_SECTIONS section(s) found"
echo ""

if [ $UNUSED_FUNC -gt 0 ] && [ $GLOBAL_VAR -gt 0 ] && [ $FUNC_PTR -gt 0 ]; then
    echo "🎉 SUCCESS: All symbols remain visible despite not being used!"
else
    echo "❌ FAILURE: Some symbols were stripped during linking."
fi

echo ""
echo "Note: These symbols are visible even though main() never calls them."
echo "This demonstrates successful static linking with symbol preservation." 