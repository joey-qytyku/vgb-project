#include <stdio.h>

long GetFileSizeAndRewind(FILE **f)
{
    long ret;

    fseek(*f, 0, SEEK_END);
    ret = ftell(*f);
    rewind(*f);
    return ret;
}

int main()
{
    FILE *fdecode;
    short ins;
    long filesize;

    fdecode  = fopen("test","r");
    filesize = GetFileSizeAndRewind(&fdecode);

    printf("Binary size: %li\n", filesize);

    for (long i=0; i < filesize / 2; i++)
    {
        fread(&ins, 2, 1, fdecode);
        printf(
            "OP=0x%x    Rs1=0x%x    Rs2=0x%x    Rd=0x%x   Imm=%i.\n",
            ins>>11,
            (ins>>8)&7,
            (ins>>3)&7,
            (ins)&7,
            (ins & 63)
        );
    }
}
