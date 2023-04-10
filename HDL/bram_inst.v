
// All values in tables are fix14_16 format,
//  bounded +/-1
module TDM_BRAM_Interface
#(
    parameter D_W = 16,
    parameter VOICES = 8,
    parameter VOICES_BITS = 3
)
(
    input sys_clk,

    input [1:0]selected_wave,

    input [7:0]nco_addr_in,

    output reg enable_DSP_in_phase,

    output reg [(D_W - 1):0]sample_d_out
);
    reg enable_bram_clk;

    reg [7:0]internal_bram_address;

    wire [(D_W - 1):0] ram_interconnect [3:0];

    // States:
    //  0:  Load new address
    //  1:  Output data
    //
    reg state;

    fixed_1416_sin_bram SIN_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(ram_interconnect[0])
    );

    fixed_1416_tri_bram TRI_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(ram_interconnect[1])
    );

    fixed_1416_sqr_bram sqr_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(ram_interconnect[2])
    );

    fixed_1416_saw_bram SAW_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(ram_interconnect[3])
    );

    initial begin
        sample_d_out = {16{1'b0}};
        enable_DSP_in_phase = 1'b0;
        enable_bram_clk = 1'b1;
        state = 1'b0;
    end


    always @ (posedge sys_clk) begin
        state <= ~state;
        if(state) begin
            internal_bram_address <= nco_addr_in;
        end
        else begin
            sample_d_out <= ram_interconnect[selected_wave];
            enable_DSP_in_phase <= 1'b1;
        end
    end

endmodule



// Sine wave table
module fixed_1416_sin_bram
#(
    parameter DATA_W = 16,
    parameter SAMPLE_CT = 256,
    parameter SAMPLE_ADDR_BITS = 8
)
(
    input bram_clk,
    input bram_ce,
    input [(SAMPLE_ADDR_BITS - 1):0]bram_addr,
    output reg [(DATA_W - 1):0]bram_out
);

    reg [(DATA_W - 1):0] wavetable [(SAMPLE_CT - 1):0];


    initial begin
        $readmemh("sin_table_16x256.mem", wavetable);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) bram_out <= wavetable[bram_addr];
    end
endmodule

// Triangle Wave Table
module fixed_1416_tri_bram
#(
    parameter DATA_W = 16,
    parameter SAMPLE_CT = 256,
    parameter SAMPLE_ADDR_BITS = 8
)
(
    input bram_clk,
    input bram_ce,
    input [(SAMPLE_ADDR_BITS - 1):0]bram_addr,
    output reg [(DATA_W - 1):0]bram_out
);

    reg [(DATA_W - 1):0] wavetable [(SAMPLE_CT - 1):0];


    initial begin
        $readmemh("tri_table_16x256.mem", wavetable);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) bram_out <= wavetable[bram_addr];
    end
endmodule


// Square Wave Table
module fixed_1416_sqr_bram
#(
    parameter DATA_W = 16,
    parameter SAMPLE_CT = 256,
    parameter SAMPLE_ADDR_BITS = 8
)
(
    input bram_clk,
    input bram_ce,
    input [(SAMPLE_ADDR_BITS - 1):0]bram_addr,
    output reg [(DATA_W - 1):0]bram_out
);

    reg [(DATA_W - 1):0] wavetable [(SAMPLE_CT - 1):0];


    initial begin
        $readmemh("sqr_table_16x256.mem", wavetable);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) bram_out <= wavetable[bram_addr];
    end
endmodule


// Saw Noise Wave Table
module fixed_1416_saw_bram
#(
    parameter DATA_W = 16,
    parameter SAMPLE_CT = 256,
    parameter SAMPLE_ADDR_BITS = 8
)
(
    input bram_clk,
    input bram_ce,
    input [(SAMPLE_ADDR_BITS - 1):0]bram_addr,
    output reg [(DATA_W - 1):0]bram_out
);

    reg [(DATA_W - 1):0] wavetable [(SAMPLE_CT - 1):0];


    initial begin
        $readmemh("saw_table_16x256.mem", wavetable);
    end

    always @ (posedge bram_clk) begin
        if(bram_ce) bram_out <= wavetable[bram_addr];
    end
endmodule