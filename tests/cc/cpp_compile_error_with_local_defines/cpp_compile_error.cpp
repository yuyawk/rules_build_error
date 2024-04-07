int main()
{

#ifdef MACRO_IN_LOCAL_DEFINES
    static_assert(false, "With local_defines, this error must show up");
#endif
    return 0;
}
