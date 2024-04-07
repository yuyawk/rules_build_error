int main()
{

#ifdef MACRO_IN_DEFINES
    static_assert(false, "With transitive defines, this error must show up");
#endif
    return 0;
}
