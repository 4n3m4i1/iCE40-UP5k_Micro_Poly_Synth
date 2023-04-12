
//Table values in fix15_u16 format,
//  where SHAMT == 15

/*
    Memory addresses are setup on the rising edge of the clk,
    and data is produced after the negative edge of the clock.
    
    If the clock can be run slow enough (it can, see channel_ctrl.v comments)
    then this module can safely be assumed to run on the negative edge of the
    system clock (48MHz), and all data propagation through
    the module, specifically the channel_enabled parameter,
    should be registered on the negative edge of the clock
    to setup the initial pipeline stage on the following posedge
*/
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

    input is_chan_en,
    input [1:0]channel_num,

    output wire [(D_W - 1):0]sample_d_out,

    output reg is_chan_en_out,
    output reg [1:0]ch_assoc_w_data
);

    localparam SIN_SELECTED = 2'b00;
    localparam TRI_SELECTED = 2'b01;
    localparam SQR_SELECTED = 2'b10;
    localparam SAW_SELECTED = 2'b11;

    reg enable_bram_clk;

    reg [7:0]internal_bram_address;

    wire [(D_W - 1):0] ram_interconnect [3:0];

    assign sample_d_out = (
                            (selected_wave == SIN_SELECTED) ?   ram_interconnect[0][(D_W - 1):0] :
                            (selected_wave == TRI_SELECTED) ?   ram_interconnect[1][(D_W - 1):0] :
                            (selected_wave == SQR_SELECTED) ?   ram_interconnect[2][(D_W - 1):0] : 
                                                                ram_interconnect[3][(D_W - 1):0]
                            );

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
        enable_bram_clk = 1'b1;
        is_chan_en_out = 1'b0;
        ch_assoc_w_data = 2'b00;
    end

    always @ (negedge sys_clk) begin
        is_chan_en_out <= is_chan_en;
        ch_assoc_w_data <= channel_num;
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

    always @ (negedge bram_clk) begin
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
        //$readmemh("tri_table_16x256.mem", wavetable);
        $readmemh("sin_table_16x256.mem", wavetable);
    end

    always @ (negedge bram_clk) begin
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
        //$readmemh("sqr_table_16x256.mem", wavetable);
        $readmemh("sin_table_16x256.mem", wavetable);
    end

    always @ (negedge bram_clk) begin
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
        //$readmemh("saw_table_16x256.mem", wavetable);
        $readmemh("sin_table_16x256.mem", wavetable);
    end

    always @ (negedge bram_clk) begin
        if(bram_ce) bram_out <= wavetable[bram_addr];
    end
endmodule