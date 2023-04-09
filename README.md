# iCE40-UP5k Micro Poly Synth
A multi voice polyphonic synth that can be interfaced via many methods.  
Notably I do not have devices with MIDI interfaces available at the moment  
thus interfacing is done via a SPI interface with an RP2040.  

## Software and Build  
HDL is intended for use (lint, build, upload) with the open source Project Icestorm  
toolchain, either through individual tool usage (Yosys, next-pnr, etc) or  
through Apio.  
  
RP2040 (Pi Pico) code utilizes the standard PI PICO SDK cmake -> make build  
process.  
  
## Hardware
The upduino-3.1 and Raspberry Pi Pico development boards are used.  
These are tied together with a standard 4 wire SPI interface.  
  
In terms of keyboard interface, something something something  
  
The DAC output of the FPGA requires a simple RC low pass, consisting of:  
`DAC OUT -> [1k5 R] --> Output`  
`                    |        `  
`                [1nF Cap]    `  
`                    |        `  
`                   GND       `  
  
Tying this output through a buffer opamp then to better filtering is  
preffered, however even with no buffer a (distorted) low impedance  
speaker or headphone may be driven. Decoupling the ouput to remove  
the implicit DC bias is encouraged but not required.  
  
## Additional Info  
Indended to serve as a final for SDSU COMPE470L.
