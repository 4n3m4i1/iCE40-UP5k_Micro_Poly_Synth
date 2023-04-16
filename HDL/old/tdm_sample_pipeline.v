
// Pipeline models for sample processing
//  each stage consists of:
//      16 bits of fix14_16 data
//      associated voice value [0,7]
module sample_pipeline
#(
    parameter NUM_VOICES = 8,
    parameter D_W = 16,
    parameter CHANBITS = 2
)
(
    input sys_clk,
    input dsp_clk,
    input dsp_enable,

    input [(CHANBITS - 1):0]channel_in,
    input is_channel_enabled,
    input [(D_W - 1):0]data_in_fix15_u16,

    output wire [(D_W - 1):0]data_out_u16
);

    // Example for pipeline stage
    wire [(CHANBITS - 1):0]stage_end_chan;
    wire [(D_W - 1):0]stage_end_data;
    wire stage_end_channel_is_enabled;
    data_and_address_pipe_register DAR_STAGE_0
    (
        .dsp_clk(dsp_clk),
        .chan_in(channel_in),
        .data_in(data_in_fix15_u16),
        .in_channel_is_enabled(is_channel_enabled),

        .chan_out(stage_end_chan),
        .data_out(stage_end_data),
        .out_channel_is_enabled(stage_end_channel_is_enabled)
    );


    // +1 stage, 8 clk to complete
    wire [(D_W - 1):0]end_stage_fixed_output;
    pipeline_terminal_summer PIPE_TERM
    (
        .dsp_clk(dsp_clk),
        .curr_channel(stage_end_chan),
        .curr_data(stage_end_data),
        .iscurrchan_en(stage_end_channel_is_enabled),
        .fixed_output(end_stage_fixed_output)
    );

    // +1 stage, 1 clk to complete
    cvt_fix15_u16_to_u16 OUTPUT_CAST
    (
        .dsp_clk(dsp_clk),
        .fixed15_u16_in(end_stage_fixed_output),
        .u16_out(data_out_u16)
    );
endmodule






module pipeline_terminal_summer
#(
    parameter NUM_VOICES = 4,
    parameter D_W = 16
)
(
    input dsp_clk,

    input [1:0]curr_channel,
    input [(D_W - 1):0]curr_data,
    input iscurrchan_en,
    output reg [(D_W - 1):0]fixed_output
);
    localparam MID_POINT = 16'h4000;

    reg [(D_W - 1 + 4):0]summ_accum;
    reg [2:0]enabled_chan_ctr;

    wire [(D_W - 1):0] normalizing_divider_outputs [0:4];


    assign normalizing_divider_outputs[0] = MID_POINT;
    assign normalizing_divider_outputs[1] = summ_accum;

    div_by_2_active_channels d2
    (
        .in(summ_accum),
        .out(normalizing_divider_outputs[2])
    );

    div_by_3_active_channels d3
    (
        .in(summ_accum),
        .out(normalizing_divider_outputs[3])
    );

    div_by_4_active_channels d4
    (
        .in(summ_accum),
        .out(normalizing_divider_outputs[4])
    );

    

    initial begin
        fixed_output = {D_W{1'b0}};
        enabled_chan_ctr = 3'b000;
    end


    always @ (posedge dsp_clk) begin
        
        case (curr_channel)
            0: begin
                // Select correct normalization for the amount of recieved
                //  valid channel samples.
                //  That is: if we RX 3 samples between (1,0] and sum them all,
                //      we must divide by 3 to re normalize the values
                fixed_output <= normalizing_divider_outputs[enabled_chan_ctr];
               
                if(iscurrchan_en) begin
                    enabled_chan_ctr <= 3'b001;
                    summ_accum <= curr_data;
                end
                else enabled_chan_ctr <= 3'b000;

            end

            1:  begin
                if(iscurrchan_en) begin
                    summ_accum <= summ_accum + curr_data;
                    enabled_chan_ctr <= enabled_chan_ctr + 1;
                end
            end
            2:  begin
                if(iscurrchan_en) begin
                    summ_accum <= summ_accum + curr_data;
                    enabled_chan_ctr <= enabled_chan_ctr + 1;
                end
            end
            3:  begin
                if(iscurrchan_en) begin
                    summ_accum <= summ_accum + curr_data;
                    enabled_chan_ctr <= enabled_chan_ctr + 1;
                end
            end
        endcase
    end
endmodule


module cvt_fix15_u16_to_u16
#(
    parameter D_W = 16,
    parameter SHAMT = 15
)
(
    input dsp_clk,
    input [(D_W - 1):0]fixed15_u16_in,
    output reg [(D_W - 1):0]u16_out
);

    initial begin
        u16_out = {16{1'b0}};
    end

    // Actually do scaling later on
    always @ (posedge dsp_clk) begin
        u16_out <= fixed15_u16_in;
    end
endmodule


// Inter module pipe stage
module data_and_address_pipe_register
#(
    parameter D_W = 16,
    parameter NUM_VOICES = 4,
    parameter NUM_VOICE_BITS = 2
)
(
    input dsp_clk,
    input [(NUM_VOICE_BITS - 1):0]chan_in,
    input [(D_W - 1):0]data_in,
    input in_channel_is_enabled,

    output reg [(NUM_VOICE_BITS - 1):0]chan_out,
    output reg [(D_W - 1):0]data_out,
    output reg out_channel_is_enabled
);


    initial begin
        chan_out = {D_W{1'b0}};
        chan_out = {NUM_VOICE_BITS{1'b0}};
        out_channel_is_enabled = 1'b0;
    end

    always @ (posedge dsp_clk) begin
        chan_out <= chan_in;
        data_out <= data_in;
        out_channel_is_enabled <= in_channel_is_enabled;
    end
endmodule

// Useful if pipeline passes thru an SBMAC
module address_only_pipe_register
#(
    parameter NUM_VOICE_BITS = 2
)
(
    input dsp_clk,
    input [(NUM_VOICE_BITS - 1):0]chan_in,
    input in_channel_is_enabled,

    output reg [(NUM_VOICE_BITS - 1):0]chan_out,
    output reg out_channel_is_enabled
);

    initial begin
        chan_out = {NUM_VOICE_BITS{1'b0}};
        out_channel_is_enabled = 1'b0;
    end

    always @ (posedge dsp_clk) begin
        chan_out <= chan_in;
        out_channel_is_enabled <= in_channel_is_enabled;
    end
endmodule





module div_by_2_active_channels
#(
    parameter D_W = 16
)
(
    input [(D_W + 3):0]in,
    output [(D_W - 1):0]out
);
    // >> 1
    assign out = {1'b0, in[(D_W - 1):1]};
endmodule

module div_by_3_active_channels
#(
    parameter D_W = 16
)
(
    input [(D_W + 3):0]in,
    output [(D_W - 1):0]out
);
    // X / 3 = (X >> 1) + (X >> 6) - (X >> 3) - (X >> 4)
    assign out =    (({1'b0, in[(D_W - 1):1]} + 
                    {6'b000000, in[(D_W - 1):6]}) -
                    ({3'b000, in[(D_W - 1):3]} +
                    {4'b0000, in[(D_W - 1):4]}));
endmodule

module div_by_4_active_channels
#(
    parameter D_W = 16
)
(
    input [(D_W + 3):0]in,
    output [(D_W - 1):0]out
);
    // >> 2
    assign out = {2'b00, in[(D_W - 1):2]};
endmodule