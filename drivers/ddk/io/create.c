
int create_file(const char *path)
{
     int retval;
     int count;
     __asm__ __volatile__ (
     "pushl $0 \n\t"
     "pushl $0 \n\t"
     "movl %2, 1(%%esp) \n\t"
     "pushl $0 \n\t"
     "pushl $0 \n\t"
     "pushl $0 \n\t"
     "pushl $0 \n\t"
     "pushl $2 \n\t"
     "movl %%esp, %%ebx \n\t"
     "movl $70, %%eax \n\t"
     "int $0x40 \n\t"
     "addl $28, %%esp \n\t"
     :"=a" (retval), "=b"(count)
     :"r" (path)
     );
  return retval;
};
