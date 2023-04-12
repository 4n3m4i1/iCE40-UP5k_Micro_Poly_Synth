
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

    output reg [(D_W - 1):0]fixed_output
);

    reg [(D_W - 1 + 4):0]summ_accum;

    initial begin
        fixed_output = {D_W{1'b0}};
    end


    always @ (posedge dsp_clk) begin
        case (curr_channel)
            0: begin
                // Shift by 3 bits or /8 to normalize sum
                fixed_output <= summ_accum[18:3];
                summ_accum <= curr_data;
            end

            1:  summ_accum <= summ_accum + curr_data;
            2:  summ_accum <= summ_accum + curr_data;
            3:  summ_accum <= summ_accum + curr_data;
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