# Build Instructions for Upduino 3.1
Clone repository into some directory  
  
## Apio
If your board is plugged in with correct drivers:
`apio clean && apio verify && apio build -v && apio upload`

## Time Division Multiplexed Processing
Each channel when active must be able to produce between  
	`8.18 - 12543.85 Hz`  
    or
    `C-1 to G9`
  
Since each wavetable is fixed at a 256x16 sample makeup we must  
consider the DAC update frequency range as `f_out * TABLE_SIZE`  
or `8.18 * 256 to 12,543.85 * 256 Hz` = `2,094 - 3,211,226 Hz`  
These values have been rounded to the closest integer value.  
  
These rates are the rates apparent at the DAC input.  
Considering the serial processing pipeline where `N` samples  
must be processed per DAC value update, we must multiply these  
rates by the number of voices. In this case that value is `4`  
to maintain a reasonable upper bound in system clock frequency  
as the iCE40-UP5k is somewhat slow.  
  
Adapting the values from above to 4 channels we see our NCO  
range must be: `8,376 - 12,844,902`, this is easily attainable  
in the iCE40-UP5k! To ensure some overhead such that the  
NCO isn't dividing by low numbers we should run the system clock  
faster than this value, luckily the internal `HFOSC` primitive  
can output a 24MHz clock with its built in divider.  
  
When updating the system clock values few values must be changed.  
Notably:
- MIDI Interface clock divider (parameterized)  
- Note BRAM LUT (in Utilities)