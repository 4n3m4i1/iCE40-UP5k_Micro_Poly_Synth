
// Handles voice NCO address generation and
//  voice phase shifts for later SYSTEM message control
module voices
#(
    parameter D_W = 16,
    parameter BYTE_W = 8,
    parameter ADDR_W = 8,
    parameter NUM_VOICES = 4,
    parameter VOICE_BITS = 2
)
(
    input sys_clk,

    input [(VOICE_BITS - 1):0] midi_modified_channel,
    input [(D_W - 1):0] midi_modified_divider,
    input midi_chan_modified_strobe,
    input [1:0]wave_input,
    input midi_wave_modified_strobe,

    output reg [1:0] wavesel,
    output reg [(VOICE_BITS - 1):0]TDM_VOICE_NUM,
    output reg [(ADDR_W - 1):0]TDM_VOICE_ADDR,
    output reg TDM_VOICE_ENABLED

);
    localparam MIN_DIVIDER      = 8;
    localparam VOICE_ENABLED    = 1'b1;
    localparam VOICE_DISABLED   = 1'b0;

    reg [(D_W - 1):0]NCO_0_DIVIDER;
    reg [(D_W - 1):0]NCO_1_DIVIDER;
    reg [(D_W - 1):0]NCO_2_DIVIDER;
    reg [(D_W - 1):0]NCO_3_DIVIDER;

    reg [(ADDR_W - 1):0]NCO_0_PHASE_OFFSET;
    reg [(ADDR_W - 1):0]NCO_1_PHASE_OFFSET;
    reg [(ADDR_W - 1):0]NCO_2_PHASE_OFFSET;
    reg [(ADDR_W - 1):0]NCO_3_PHASE_OFFSET;

    reg [(ADDR_W - 1):0]NCO_0_PHASED_ADDR;
    reg [(ADDR_W - 1):0]NCO_1_PHASED_ADDR;
    reg [(ADDR_W - 1):0]NCO_2_PHASED_ADDR;
    reg [(ADDR_W - 1):0]NCO_3_PHASED_ADDR;

    wire [(ADDR_W - 1):0]NCO_0_ADDRESS;
    wire [(ADDR_W - 1):0]NCO_1_ADDRESS;
    wire [(ADDR_W - 1):0]NCO_2_ADDRESS;
    wire [(ADDR_W - 1):0]NCO_3_ADDRESS;


    reg NCO_0_EN, NCO_1_EN, NCO_2_EN, NCO_3_EN;
    reg [1:0]NCO_0_WAVE, NCO_1_WAVE, NCO_2_WAVE, NCO_3_WAVE;

    simple_nco V0_NCO
    (
        .sys_clk(sys_clk),
        .nco_div(NCO_0_DIVIDER),
        .nco_addr(NCO_0_ADDRESS)
    );

    simple_nco V0_NC1
    (
        .sys_clk(sys_clk),
        .nco_div(NCO_1_DIVIDER),
        .nco_addr(NCO_1_ADDRESS)
    );

    simple_nco V0_NC2
    (
        .sys_clk(sys_clk),
        .nco_div(NCO_2_DIVIDER),
        .nco_addr(NCO_2_ADDRESS)
    );

    simple_nco V0_NC3
    (
        .sys_clk(sys_clk),
        .nco_div(NCO_3_DIVIDER),
        .nco_addr(NCO_3_ADDRESS)
    );



    initial begin
        TDM_VOICE_NUM   = {VOICE_BITS{1'b0}};

        TDM_VOICE_ADDR  = {ADDR_W{1'b0}};

        TDM_VOICE_ENABLED   = VOICE_DISABLED;
/*
        NCO_0_PHASE_OFFSET  = {ADDR_W{1'b0}};
        NCO_1_PHASE_OFFSET  = {ADDR_W{1'b0}};
        NCO_2_PHASE_OFFSET  = {ADDR_W{1'b0}};
        NCO_3_PHASE_OFFSET  = {ADDR_W{1'b0}};
*/

        NCO_0_PHASE_OFFSET  = 8'h04;
        NCO_1_PHASE_OFFSET  = 8'h03;
        NCO_2_PHASE_OFFSET  = 8'h02;
        NCO_3_PHASE_OFFSET  = 8'h01;


        NCO_0_PHASED_ADDR  = {ADDR_W{1'b0}};
        NCO_0_PHASED_ADDR  = {ADDR_W{1'b0}};
        NCO_0_PHASED_ADDR  = {ADDR_W{1'b0}};
        NCO_0_PHASED_ADDR  = {ADDR_W{1'b0}};

        NCO_0_DIVIDER   = {D_W{1'b0}};
        NCO_1_DIVIDER   = {D_W{1'b0}};
        NCO_2_DIVIDER   = {D_W{1'b0}};
        NCO_3_DIVIDER   = {D_W{1'b0}};

        wavesel         = 2'b00;

        NCO_0_WAVE      = 2'b00;
        NCO_1_WAVE      = 2'b00;
        NCO_2_WAVE      = 2'b00;
        NCO_3_WAVE      = 2'b00;

        NCO_0_EN        = 1'b0;
        NCO_1_EN        = 1'b0;
        NCO_2_EN        = 1'b0;
        NCO_3_EN        = 1'b0;
         
    end


    always @ (posedge sys_clk) begin
        TDM_VOICE_NUM <= TDM_VOICE_NUM + 1;

        NCO_0_PHASED_ADDR <= NCO_0_ADDRESS + NCO_0_PHASE_OFFSET;
        NCO_1_PHASED_ADDR <= NCO_1_ADDRESS + NCO_1_PHASE_OFFSET;
        NCO_2_PHASED_ADDR <= NCO_2_ADDRESS + NCO_2_PHASE_OFFSET;
        NCO_3_PHASED_ADDR <= NCO_3_ADDRESS + NCO_3_PHASE_OFFSET;

        case (TDM_VOICE_NUM)
            0: begin
                TDM_VOICE_ADDR <= NCO_0_PHASED_ADDR;
                TDM_VOICE_ENABLED <= NCO_0_EN;
                wavesel <= NCO_0_WAVE;
            end
            1: begin
                TDM_VOICE_ADDR <= NCO_1_PHASED_ADDR;
                TDM_VOICE_ENABLED <= NCO_1_EN;
                wavesel <= NCO_1_WAVE;
            end
            2: begin
                TDM_VOICE_ADDR <= NCO_2_PHASED_ADDR;
                TDM_VOICE_ENABLED <= NCO_2_EN;
                wavesel <= NCO_2_WAVE;
            end
            3: begin
                TDM_VOICE_ADDR <= NCO_3_PHASED_ADDR;
                TDM_VOICE_ENABLED <= NCO_3_EN;
                wavesel <= NCO_3_WAVE;
            end
        endcase


        


        if(midi_chan_modified_strobe) begin
            case (midi_modified_channel)
                0: begin
                    NCO_0_DIVIDER <= midi_modified_divider;
                    if(midi_modified_divider >= MIN_DIVIDER) NCO_0_EN <= 1'b1;
                    else NCO_0_EN <= 1'b0;
                end
                1: begin
                    NCO_1_DIVIDER <= midi_modified_divider;
                    if(midi_modified_divider >= MIN_DIVIDER) NCO_1_EN <= 1'b1;
                    else NCO_1_EN <= 1'b0;
                end
                2: begin
                    NCO_2_DIVIDER <= midi_modified_divider;
                    if(midi_modified_divider >= MIN_DIVIDER) NCO_2_EN <= 1'b1;
                    else NCO_2_EN <= 1'b0;
                end
                3: begin
                    NCO_3_DIVIDER <= midi_modified_divider;
                    if(midi_modified_divider >= MIN_DIVIDER) NCO_3_EN <= 1'b1;
                    else NCO_3_EN <= 1'b0;
                end
            endcase
        end

        if(midi_wave_modified_strobe) begin
            case (midi_modified_channel)
                0: NCO_0_WAVE <= wave_input;
                1: NCO_1_WAVE <= wave_input;
                2: NCO_2_WAVE <= wave_input;
                3: NCO_3_WAVE <= wave_input;
            endcase
        end

    end
endmodule