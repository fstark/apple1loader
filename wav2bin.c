#include <stdio.h>

#define DIVISOR 30

int main() {
    int index = 0, last = 0, direction = 1, syncstate = 0, bitindex = 0;
    int distance;
    unsigned char outbyte;
    signed short sample;

    while (!feof(stdin)) {
        sample = getchar() | getchar()<<8;
        if (!direction) {
            if (sample>(32768/DIVISOR)) {
                distance = index-last;
                if (distance<50) {
                    if (syncstate == 2) {
                        outbyte = outbyte << 1 | (distance<32? 0:1);
                        if (!((++bitindex)&7)) putchar(outbyte);
                    }
                    if (syncstate == 1) syncstate++;
                } else if ((distance<70) && !syncstate)
                    syncstate++;
                last = index;
                direction++;
            }
        } else
            if (sample<-(32768/DIVISOR))
                direction--;
        index++;
    }

    return bitindex/8;
}