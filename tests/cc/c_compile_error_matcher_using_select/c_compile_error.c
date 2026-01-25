#include <assert.h>

// Select the error message based on the target platform.

#if defined(__linux__)
#define ERROR_MESSAGE "The target platform is linux"
#elif defined(_WIN32) || defined(_WIN64)
#define ERROR_MESSAGE "The target platform is Windows"
#elif defined(__APPLE__) && defined(__MACH__)
#define ERROR_MESSAGE "The target platform is macOS"
#else
#define ERROR_MESSAGE "The target platform is unknown"
#endif

int main()
{
    static_assert(0, ERROR_MESSAGE);
    return 0;
}
