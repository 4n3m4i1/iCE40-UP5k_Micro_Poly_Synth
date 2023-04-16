
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

    output reg [(D_W - 1):0]sample_d_out,

    output reg is_chan_en_out,
    output reg [1:0]ch_assoc_w_data
);
    reg is_chan_en_buff;
    reg [1:0]ch_association_buff;

    localparam SIN_SELECTED = 2'b00;
    localparam TRI_SELECTED = 2'b01;
    localparam SQR_SELECTED = 2'b10;
    localparam SAW_SELECTED = 2'b11;

    reg enable_bram_clk;

    reg [7:0]internal_bram_address;

    wire [(D_W - 1):0] sin_output;
    wire [(D_W - 1):0] tri_output;
    wire [(D_W - 1):0] sqr_output;
    wire [(D_W - 1):0] saw_output;

    fixed_1416_sin_bram SIN_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(sin_output)
    );

    fixed_1416_tri_bram TRI_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(tri_output)
    );

    fixed_1416_sqr_bram sqr_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(sqr_output)
    );

    fixed_1416_saw_bram SAW_WAVETABLE
    (
        .bram_clk(sys_clk),
        .bram_ce(enable_bram_clk),
        .bram_addr(internal_bram_address),
        .bram_out(saw_output)
    );


    initial begin
        enable_bram_clk = 1'b1;
        is_chan_en_out = 1'b0;
        ch_assoc_w_data = 2'b00;

        ch_association_buff = 2'b00;
        is_chan_en_buff = 1'b0;

        sample_d_out = {D_W{1'b0}};
    end

/*
module state operation:
    CLK #   EDGE    DESC
    0       RISING      RAM ADDR LOAD
    0       FALLING     RAM DAT READY
    1       RISING      RAM DAT OUTPUT, NEW LOAD

There are 2 cycles of effective pipe delay here
*/

    always @ (posedge sys_clk) begin
        //Stage 0, ingest address and enable info
        internal_bram_address <= nco_addr_in;
        is_chan_en_buff <= is_chan_en;
        ch_association_buff <= channel_num;

        // Stage 1, output data and channel information
        is_chan_en_out  <= is_chan_en_buff;
        ch_assoc_w_data <= ch_association_buff;
        case (ch_association_buff) begin
            SIN_SELECTED: sample_d_out <= sin_output;
            TRI_SELECTED: sample_d_out <= tri_output;
            SQR_SELECTED: sample_d_out <= sqr_output;
            SAW_SELECTED: sample_d_out <= saw_output;
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
        $readmemh("tri_table_16x256.mem", wavetable);
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
        $readmemh("sqr_table_16x256.mem", wavetable);
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
        $readmemh("saw_table_16x256.mem", wavetable);
    end

    always @ (negedge bram_clk) begin
        if(bram_ce) bram_out <= wavetable[bram_addr];
    end
endmodule