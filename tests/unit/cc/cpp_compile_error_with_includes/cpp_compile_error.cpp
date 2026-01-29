#include <foo/bar.hpp>

int main()
{
    static_assert(::foo::Bar(), "If ::foo::Bar() is correctly declared, this will fail");
    return 0;
}
