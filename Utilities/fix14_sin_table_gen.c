#include <stdio.h>
#include <math.h>
#include <stdint.h>

// actually fix15_u16 now for unsigned centered on 2^15

#define _USE_MATH_DEFINES

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
    file = fopen("sin_table_16x256.mem", "w");

    for(int n = 0; n < NUM_SAMPLES; n++){

        float sam = (float)(sin((2.0 * M_PI * (double)n) / (double)NUM_SAMPLES));


        fprintf(file, "%04X", float2fix15_u16(0.5f * (sam + 1.0)));
        //fprintf(file, "%u", float2fix15_u16(0.5f * (sam + 1.0)));
        if(n != NUM_SAMPLES - 1){
            fprintf(file, "\n");
        }
    }

    fclose(file);
/*
    fix15_u16 A = float2fix15_u16(1.0 / 3.0);

    printf("1/3 == 0x%04X\n", A);

    float fv = 0.5f;

    fix15_u16 C = float2fix15_u16(fv);
    fix15_u16 B = (fix15_u16)(((uint32_t)A * (uint32_t)float2fix15_u16(fv)) >> SHAMT);
/*
    C += (C + 2) >> 2;
    C += (C + 8) >> 4;
    C += (C + 128) >> 8;
    C += (C + (1 << 15)) >> 16;
*/
    // 21845 == 0x5555
    //C = (fix15_u16)(((uint32_t)C * 21845) >> SHAMT);
    
    //fix15_u16 T1 = C >> 2;
    //fix15_u16 T2 = C >> 3;

    //C = T1 + T1;
    
    // 0.5x - 0.125x 
 //   C = (C >> 1) - (C >> 3) - (C >> 4) + (C >> 6);

    // C/3 = 0.5C - 0.125C - 0.0625C + 0.01625C
    // 0.5% off
/*
    printf("CVT = 0x%04X == %u\n", float2fix15_u16(fv), float2fix15_u16(fv));
    
    printf("B = 0x%04X == %u\n", B, B);

    printf("C = 0x%04X == %u\n", C, C);

    printf("B - C = 0x%04X == %d\n", B - C, B - C);
*/
    printf("Done!\n");

    return 0;
}