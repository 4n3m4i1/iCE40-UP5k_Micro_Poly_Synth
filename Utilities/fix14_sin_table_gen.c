#include <stdio.h>
#include <math.h>
#include <stdint.h>

#define _USE_MATH_DEFINES

#define NUM_BITS    16
#define NUM_SAMPLES 256

#define SHAMT           14  // initially 15
#define FL_CVT_CONST    16384.0 // prev 32768.0

// === the fixed point macros ========================================
typedef int16_t fix14_16 ;
//#define multfix14_16(a,b) ((fix14_16)((((signed long long)(a))*((signed long long)(b)))>>15)) //multiply two fixed 16.15
#define multfix14_16(a,b) ((fix14_16)((((int32_t)(a))*((int32_t)(b)))>>SHAMT)) //multiply two fixed 16.15
#define float2fix14_16(a) ((fix14_16)((a)*FL_CVT_CONST)) // 2^SHAMT
#define fix2float15(a) ((float)(a)/FL_CVT_CONST)
#define absfix14_16(a) abs(a)
#define int2fix14_16(a) ((fix14_16)(a << SHAMT))
#define fix2int15(a) ((int)(a >> SHAMT))
#define char2fix14_16(a) (fix14_16)(((fix14_16)(a)) << SHAMT)


void print_fix14_16(fix14_16 val){
    uint32_t t_val = (uint32_t)val;
    int max = (8 * sizeof(fix14_16) );
    for(int n = 0; n < max; n++){
        if(t_val & (1 << ((max - 1) - n))){
            printf("1");
        } else {
            printf("0");
        }
        if(n == (max - SHAMT - 1)) printf(".");
    }
}

int main(){
    FILE *file;
    file = fopen("sin_table_16x256.mem", "w");

    for(int n = 0; n < NUM_SAMPLES; n++){

        float sam = (float)(sin((2.0 * M_PI * (double)n) / (double)NUM_SAMPLES));


        fprintf(file, "%04X", (uint16_t)float2fix14_16(sam));
        if(n != NUM_SAMPLES - 1){
            fprintf(file, "\n");
        }
    }

    fclose(file);

    printf("Done!\n");

    return 0;
}