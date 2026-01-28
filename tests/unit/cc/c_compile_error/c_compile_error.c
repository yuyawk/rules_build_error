#include <assert.h>

int main()
{
    static_assert(0, "Compile error message for c_compile_error.c");
    return 0;
}
