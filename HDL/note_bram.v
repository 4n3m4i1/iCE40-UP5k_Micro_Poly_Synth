// BRAM look up table to convert MIDI note values
//  to 16 bit clock divider values
//
//  Eventually 128 -> 255 will be pitch bench scalars
module note_LUT
#(
    parameter D_W = 16,
    parameter NUM_SAMPLES = 256,
    parameter ADDR_BITS = 8
)
(
    input bram_clk,
    input bram_ce,
    input [(ADDR_BITS - 1):0]bram_addr,
    output reg [(D_W - 1):0]bram_out
);

    // Yosys BRAM_4k inference
    reg [(D_W - 1):0] noteLUT [(NUM_SAMPLES - 1):0];

    initial begin
        $readmemh("midi_note_table.mem", noteLUT);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) bram_out <= noteLUT[bram_addr];
    end
endmodule