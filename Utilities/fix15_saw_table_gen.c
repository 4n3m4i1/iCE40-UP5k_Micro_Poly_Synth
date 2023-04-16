#include <stdio.h>
#include <math.h>
#include <stdint.h>

// actually fix15_u16 now for unsigned centered on 2^15

// Uncomment for actual table generation, comment out for spreadsheet use
#define FOR_USE

#define _USE_MATH_DEFINES

//#define FL_SCALAR   65535.0 / 65536.0
#define FL_SCALAR   1.0
#define FL_MAX      65535.0
#define FL_MIN      0.0

#define NUM_BITS    16
#define NUM_SAMPLES 256

#define SHAMT           15  // initially 15
//#define FL_CVT_CONST    16384.0 // prev 32768.0
#define FL_CVT_CONST    32768.0 // prev 32768.0

/*
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
*/


typedef uint16_t fix15_u16;
#define float2fix15_u16(a) ((fix15_u16)((a)*FL_CVT_CONST)) // 2^SHAMT

void print_fix15_u16(fix15_u16 val){
    uint32_t t_val = (uint32_t)val;
    int max = (8 * sizeof(fix15_u16) );
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
    file = fopen("saw_table_16x256.mem", "w");


    int saw_pk_0 = (NUM_SAMPLES / 2);

    double rise = 2.0;
    double run = ((double)NUM_SAMPLES) / 2.0;
    //double tri_slope = rise / run;

    double saw_slope = rise / run;

    int n;
    float sam, samlast;

    printf("Limit 0: %3d\nSawSlope %f\n", saw_pk_0, saw_slope);
// SEGMENT 1
    for(n = 0; n < saw_pk_0; n++){

        //float sam = (float)(sin((2.0 * M_PI * (double)n) / (double)NUM_SAMPLES));

        sam = (float)(saw_slope * n) * FL_SCALAR;
#ifdef FOR_USE
        fprintf(file, "%04X\n", float2fix15_u16((sam)));
#else
        fprintf(file, "%u\n", float2fix15_u16((sam)));
#endif

    }

    // SEGMENT 1
    for(n = 0; n < saw_pk_0; n++){

        //float sam = (float)(sin((2.0 * M_PI * (double)n) / (double)NUM_SAMPLES));

        sam = (float)(saw_slope * n) * FL_SCALAR;
#ifdef FOR_USE
        fprintf(file, "%04X", float2fix15_u16((sam)));
#else
        fprintf(file, "%u", float2fix15_u16((sam)));
#endif
        if(n != saw_pk_0 - 1){
            fprintf(file, "\n");
        }

    }


    fclose(file);

    printf("Done!\n");

    return 0;
}
