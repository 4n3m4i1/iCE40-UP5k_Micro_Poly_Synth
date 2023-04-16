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
);






/////////////////////////////////////////////////////
//              END OF PIPELINE SUMMATION
//                  AND NORMALIZATION
/////////////////////////////////////////////////////
    wire [(D_W - 1):0]TDM_DATA_SUMMED;
    TDM_TERMINAL_SUMMER END_OF_THE_LINE
    (
        .sys_clk(sys_clk),
        .terminal_input(),      // D_W
        .is_voice_enabled(),

        .terminal_output(TDM_DATA_SUMMED)
    );

/////////////////////////////////////////////////////
    initial begin
        TDM_DATA_OUTPUT = {D_W{1'b0}};
    end

    always @ (posedge sys_clk) begin
        TDM_DATA_OUTPUT <= TDM_DATA_SUMMED;
    end
end




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

    reg [(D_W + 3):0] accum_20_bit, post_process_accum;
    reg [(VOICE_BITS - 1):0]sample_ctr, sample_ct_buffer;
    reg [(VOICE_BITS - 1):0]clk_ctr;

    reg [(D_W - 1):0]div_3_term_0, div_3_term_1;

    reg [(D_W - 1):0]div_1_res, div_2_res, div_3_res, div_4_res;

    initial begin
        terminal_output     = {D_W{1'b0}};
        accum_20_bit        = {(D_W + 4){1'b0}};
        post_process_accum  = {(D_W + 4){1'b0}};

        clk_ctr         = {VOICE_BITS{1'b0}};
        sample_ctr      = {VOICE_BITS{1'b0}};
        sample_ct_buffer= {VOICE_BITS{1'b0}};

        div_3_term_0    = {D_W(1'b0)};
        div_3_term_1    = {D_W(1'b0)};

        div_1_res       = {D_W(1'b0)};
        div_2_res       = {D_W(1'b0)};
        div_3_res       = {D_W(1'b0)};
        div_4_res       = {D_W(1'b0)};
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
                post_process_accum <= accum_20_bit;
                
                sample_ct_buffer <= sample_ctr;

                if(is_voice_enabled) begin
                    sample_ctr <= sample_ctr + 1;
                    accum_20_bit <= {4'h0, terminal_input};
                end
                else    accum_20_bit <= {(D_W + 4){1'b0}};

                div_3_term_0 <= accum_20_bit[16:1];
                div_3_term_1 <= accum_20_bit[18:3];
            end

            1: begin
                if(is_voice_enabled) begin
                    sample_ctr <= sample_ctr + 1;
                    accum_20_bit <= accum_20_bit + {4'h0, terminal_input};
                end

                div_3_term_0 <= div_3_term_0 + {3'b000, post_process_accum[19:6]};
                div_3_term_1 <= div_3_term_1 + post_process_accum[19:4];
            end

            2: begin
                if(is_voice_enabled) begin
                    sample_ctr <= sample_ctr + 1;
                    accum_20_bit <= accum_20_bit + {4'h0, terminal_input};
                end
                
                div_1_res <= accum_20_bit[15:0];
                div_2_res <= accum_20_bit[16:1];
                div_3_res <= div_3_term_0 - div_3_term_1;
                div_4_res <= accum_20_bit[17:2];
            end

            3: begin
                if(is_voice_enabled) begin
                    sample_ctr <= sample_ctr + 1;
                    accum_20_bit <= accum_20_bit + {4'h0, terminal_input};
                end


                case(sample_ct_buffer)
                    0:  terminal_output <= div_1_res;
                    1:  terminal_output <= div_2_res;
                    2:  terminal_output <= div_3_res;
                    3:  terminal_output <= div_4_res;
                endcase

            end
        endcase
    end
endmodule