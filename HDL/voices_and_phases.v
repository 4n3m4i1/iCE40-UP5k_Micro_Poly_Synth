
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

    output reg [1:0] wavesel,
    output reg [(VOICE_BITS - 1):0]TDM_VOICE_NUM,
    output reg [(ADDR_W - 1):0]TDM_VOICE_ADDR,
    output reg TDM_VOICE_ENABLED
);
    localparam MIN_DIVIDER      = 8;
    localparam VOICE_ENABLED    = 1'b1;
    localparam VOICE_DISABLED   = 1'b0;

    reg [(D_W - 1):]NCO_0_DIVIDER;
    reg [(D_W - 1):]NCO_1_DIVIDER;
    reg [(D_W - 1):]NCO_2_DIVIDER;
    reg [(D_W - 1):]NCO_3_DIVIDER;

    reg [(ADDR_W - 1):]NCO_0_PHASE_OFFSET;
    reg [(ADDR_W - 1):]NCO_1_PHASE_OFFSET;
    reg [(ADDR_W - 1):]NCO_2_PHASE_OFFSET;
    reg [(ADDR_W - 1):]NCO_3_PHASE_OFFSET;

    wire [(ADDR_BITS - 1):0]NCO_0_ADDRESS;
    wire [(ADDR_BITS - 1):0]NCO_1_ADDRESS;
    wire [(ADDR_BITS - 1):0]NCO_2_ADDRESS;
    wire [(ADDR_BITS - 1):0]NCO_3_ADDRESS;

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

        TDM_VOICE_ADDR  = {ADDR_BITS{1'b0}};

        TDM_VOICE_ENABLED   = VOICE_DISABLED;

        NCO_0_PHASE_OFFSET  = {ADDR_BITS{1'b0}};
        NCO_1_PHASE_OFFSET  = {ADDR_BITS{1'b0}};
        NCO_2_PHASE_OFFSET  = {ADDR_BITS{1'b0}};
        NCO_3_PHASE_OFFSET  = {ADDR_BITS{1'b0}};

        NCO_0_DIVIDER   = {D_W{1'b0}};
        NCO_1_DIVIDER   = {D_W{1'b0}};
        NCO_2_DIVIDER   = {D_W{1'b0}};
        NCO_3_DIVIDER   = {D_W{1'b0}};

        wavesel         = 2'b00;
    end


    always @ (posedge sys_clk) begin
        TDM_VOICE_NUM <= TDM_VOICE_NUM + 1;

        case (VOICE_NUM)
            0: begin
                TDM_VOICE_ADDR <= NCO_0_ADDRESS + NCO_0_PHASE_OFFSET;
                if(NCO_0_DIVIDER >= MIN_DIVIDER) TDM_VOICE_ENABLED <= VOICE_ENABLED;
                else TDM_VOICE_ENABLED <= VOICE_DISABLED;
            end
            1: begin
                TDM_VOICE_ADDR <= NCO_1_ADDRESS + NCO_1_PHASE_OFFSET;
                if(NCO_1_DIVIDER >= MIN_DIVIDER) TDM_VOICE_ENABLED <= VOICE_ENABLED;
                else TDM_VOICE_ENABLED <= VOICE_DISABLED;
            end
            2: begin
                TDM_VOICE_ADDR <= NCO_2_ADDRESS + NCO_2_PHASE_OFFSET;
                if(NCO_2_DIVIDER >= MIN_DIVIDER) TDM_VOICE_ENABLED <= VOICE_ENABLED;
                else TDM_VOICE_ENABLED <= VOICE_DISABLED;
            end
            3: begin
                TDM_VOICE_ADDR <= NCO_3_ADDRESS + NCO_3_PHASE_OFFSET;
                if(NCO_3_DIVIDER >= MIN_DIVIDER) TDM_VOICE_ENABLED <= VOICE_ENABLED;
                else TDM_VOICE_ENABLED <= VOICE_DISABLED;
            end
        endcase


        if(midi_chan_modified_strobe) begin
            case (midi_modified_channel)
                0: NCO_0_DIVIDER <= midi_modified_divider;
                0: NCO_1_DIVIDER <= midi_modified_divider;
                0: NCO_2_DIVIDER <= midi_modified_divider;
                0: NCO_3_DIVIDER <= midi_modified_divider;
            endcase
        end
    end
endmodule