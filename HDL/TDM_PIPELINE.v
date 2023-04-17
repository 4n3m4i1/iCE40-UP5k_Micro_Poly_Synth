/*
    The TDM Pipeline is a serial processing pipeline
    to maximize the hardware utilization on the limited
    resources provided by the iCE40-UP5k.

    By multiplexing with time and ensuring processing
    operations take a single cycle (sans terminal 
    summation and normalization), we can use the same
    hardware with no switching to process all data, at the
    cost of reducing throughput by our number of voices.
*/



module TDM_PIPELINE
#(
    parameter D_W = 16,
    parameter ADDR_W = 8,
    parameter BYTE_W = 8,
    parameter NUM_VOICES = 4,
    parameter VOICE_BITS = 2
)
(
    input sys_clk,

    input [(VOICE_BITS - 1):0]TDM_CHANNEL_NUM,
    input [(D_W - 1):0]TDM_DATA_INPUT,
    input TDM_CHANNEL_IS_EN,

    output reg [(D_W - 1):0]TDM_DATA_OUTPUT
    //output [(D_W - 1):0]TDM_DATA_SUMMED
);


/*
    // Pre pipeline processing to remove invalid samples
    wire [(D_W - 1):0]CLEANED_TDM_STREAM;
    wire CLEANED_TDM_ENABLE;
    wire [(VOICE_BITS - 1):0]CLEANED_TDM_CHANNEL;
    insert_zero_sample disabled_channel_data_rejection
    (
        .sys_clk(sys_clk),
        .sample_din(BUFFDAT0),
        .is_chan_enabled(BUFFEN0),
        .vin(BUFFCHANNUM0),
        .sample_dout(CLEANED_TDM_STREAM),
        .sample_enabled(CLEANED_TDM_ENABLE),
        .vout(CLEANED_TDM_CHANNEL)
    );
*/

    /////////////////////////////////////////////////////
    //              END OF PIPELINE SUMMATION
    //                  AND NORMALIZATION
    /////////////////////////////////////////////////////
    wire [(D_W - 1):0]TDM_DATA_SUMMED;
    TDM_TERMINAL_SUMMER END_OF_THE_LINE
    (
        .sys_clk(sys_clk),
        .terminal_input(TDM_DATA_INPUT),      // D_W
        .is_voice_enabled(TDM_CHANNEL_IS_EN),

        .terminal_output(TDM_DATA_SUMMED)
    );

    /////////////////////////////////////////////////////
    initial begin
        TDM_DATA_OUTPUT = {D_W{1'b0}};
    end

    always @ (posedge sys_clk) begin
        TDM_DATA_OUTPUT <= TDM_DATA_SUMMED;
    end
endmodule


////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////
//              MODULES IN PIPELINE
////////////////////////////////////////////////////////////

module TDM_TERMINAL_SUMMER
#(
    parameter D_W = 16,
    parameter NUM_VOICES = 4,
    parameter VOICE_BITS = 2
)
(
    input sys_clk,
    input [(D_W - 1):0]terminal_input,
    input is_voice_enabled,
    output reg [(D_W - 1):0]terminal_output
);

    reg [(D_W + 3):0] accum_20_bit;

    reg [(VOICE_BITS - 1):0]clk_ctr;

    initial begin
        terminal_output     = {D_W{1'b0}};
        accum_20_bit        = {(D_W + 4){1'b0}};
        
        clk_ctr         = {VOICE_BITS{1'b0}};
    end

/*
    Div / 1:
        out = in
    
    Div / 2:
        out = in >> 1
    
    Div / 3:
        out = ((in >> 1) + (in >> 6)) - ((in >> 3) + (in >> 4))

    Div / 4:
        out = in >> 2
*/

    always @ (posedge sys_clk) begin
        clk_ctr <= clk_ctr + 1;

        case (clk_ctr)
            0: begin
                accum_20_bit <= terminal_input;
                terminal_output <= accum_20_bit[17:2];
            end
            1: accum_20_bit <= accum_20_bit + terminal_input;
            2: accum_20_bit <= accum_20_bit + terminal_input;
            3: accum_20_bit <= accum_20_bit + terminal_input;
        endcase

    end
endmodule



module insert_zero_sample
#(
    parameter D_W = 16,
    parameter VOICE_BITS = 2
)
(
    input sys_clk,
    input [(D_W - 1):0]sample_din,
    input [(VOICE_BITS - 1):0]vin,
    input is_chan_enabled,

    output reg [(D_W - 1):0]sample_dout,
    output reg sample_enabled,
    output reg [(VOICE_BITS - 1):0]vout
);

    reg [(D_W - 1):0]t_zero;

    initial begin
        t_zero = {D_W{1'b0}};
        sample_dout = {D_W {1'b0}};
        sample_enabled = 1'b0;
        vout = {VOICE_BITS{1'b0}};
    end


    always @ (posedge sys_clk) begin
        if(is_chan_enabled) sample_dout <= sample_din;
        else sample_dout <= t_zero;

        sample_enabled <= is_chan_enabled;
        vout <= vin;
    end
endmodule





module full_TDM_pipe_register
#(
    parameter D_W = 16,
    parameter VOICE_BITS = 2
)
(
    input sys_clk,

    input en_i,
    input [(VOICE_BITS - 1):0]vin,
    input [(D_W - 1):0]din,

    output reg [(D_W - 1):0]dout,
    output reg [(VOICE_BITS - 1):0]vout,
    output reg en_o
);



    initial begin
        dout = {D_W {1'b0}};
        vout = {VOICE_BITS{1'b0}};
        en_o = 1'b0;
    end

    always @ (posedge sys_clk) begin
        dout <= din;
        vout <= vin;
        en_o <= en_i;
    end

endmodule