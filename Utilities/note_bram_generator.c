#include <stdio.h>
#include <stdint.h>

#define ICE_CLK_F   24000000
#define NUM_NOTES   128
#define TABLE_SIZE  256

#define SCALAR__	1.0594585
#define LOW_FREQ    8.18        // C-1

uint16_t cv_f_to_div(double freq);

int main(){
    FILE *file;
    file = fopen("note_bram_24MHz.mem", "w");

    uint32_t n;

    double last = LOW_FREQ;
    fprintf(file, "%04X\n", cv_f_to_div(last));

    for(n = 0; n < NUM_NOTES; n++){
        printf("%3d\t%f\n", n, last);
		fprintf(file, "%04X\n", cv_f_to_div(last));
		last *= SCALAR__;
    }

    for(; n < TABLE_SIZE; n++){
        fprintf(file, "%04X\n", 0x0000);
    }

    fclose(file);
    return 0;
}

// sysclk / (f * size of table)
uint16_t cv_f_to_div(double freq){
    return (uint16_t) ((double)ICE_CLK_F / (freq * (double)TABLE_SIZE));
}
