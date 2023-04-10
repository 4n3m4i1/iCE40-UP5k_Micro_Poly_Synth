




module chanel_manager
#(
    parameter NUM_VOICES = 8,
    parameter D_W = 16,
    parameter ADDR_W = 8
)
(
    input sys_clk,

    input wire [(D_W - 1):0]voice_0_divider,
    input wire [(D_W - 1):0]voice_1_divider,
    input wire [(D_W - 1):0]voice_2_divider,
    input wire [(D_W - 1):0]voice_3_divider,
    input wire [(D_W - 1):0]voice_4_divider,
    input wire [(D_W - 1):0]voice_5_divider,
    input wire [(D_W - 1):0]voice_6_divider,
    input wire [(D_W - 1):0]voice_7_divider,


    output reg [(ADDR_W - 1):0]TDM_ADDRESS_OUT,
    output wire [2:0]ENABLED_CHANNEL_TDM
);
    localparam MIN_DIVIDER = 8;

    // Currently enabled channel to read into
    //  pipeline
    reg [2:0]TDM_CHANNEL_ENABLE;

    assign ENABLED_CHANNEL_TDM = TDM_CHANNEL_ENABLE;

    wire [(ADDR_W - 1):0] nco_addresses [7:0];

    wire [(ADDR_W - 1):0] TDM_NCO_ADDR;

    reg [(ADDR_W - 1):0] voice_phase_advance [7:0];


    wire enable_nco[7:0];

    assign enable_nco[0] = (voice_0_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[1] = (voice_1_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[2] = (voice_2_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[3] = (voice_3_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[4] = (voice_4_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[5] = (voice_5_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[6] = (voice_6_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[7] = (voice_7_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;


    reg enable_nco_reg, set_phase_advance;
    nco_w_phase_in VOICE_0
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[0]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[0]),
        .nco_divider(voice_0_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[0])
    );

    nco_w_phase_in VOICE_1
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[1]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[1]),
        .nco_divider(voice_1_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[1])
    );

    nco_w_phase_in VOICE_2
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[2]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[2]),
        .nco_divider(voice_2_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[2])
    );

    nco_w_phase_in VOICE_3
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[3]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[3]),
        .nco_divider(voice_3_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[3])
    );

    nco_w_phase_in VOICE_4
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[4]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[4]),
        .nco_divider(voice_4_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[4])
    );

    nco_w_phase_in VOICE_5
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[5]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[5]),
        .nco_divider(voice_5_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[5])
    );

    nco_w_phase_in VOICE_6
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[6]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[6]),
        .nco_divider(voice_6_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[6])
    );

    nco_w_phase_in VOICE_7
    (
        .sys_clk(sys_clk),
        .nco_en(enable_nco_reg & enable_nco[7]),
        .apply_phase_advance(set_phase_advance),
        .phase_advance(voice_phase_advance[7]),
        .nco_divider(voice_7_divider),
        .nco_lfo(1'b0),
        .addr_out(nco_addresses[7])
    );

    reg read_load_state;
    reg can_write_to_channel;

    reg [2:0]init_state_machine;


    initial begin
        TDM_CHANNEL_ENABLE = 3'b000;
        enable_nco_reg = 1'b0;
        set_phase_advance = 1'b0;
        read_load_state = 1'b0;

        voice_phase_advance[0] = 7;
        voice_phase_advance[1] = 6;
        voice_phase_advance[2] = 5;
        voice_phase_advance[3] = 4;
        voice_phase_advance[4] = 3;
        voice_phase_advance[5] = 2;
        voice_phase_advance[6] = 1;
        voice_phase_advance[7] = 0;
    end

    // Read state machine
    //  allow 1 cycle for data to propagate from BRAM
    always @ (posedge sys_clk) begin
        read_load_state <= ~read_load_state;

        if(read_load_state) begin
            TDM_ADDRESS_OUT <= nco_addresses[TDM_CHANNEL_ENABLE];
        end
        else begin
            TDM_CHANNEL_ENABLE <= TDM_CHANNEL_ENABLE + 1;
        end
    end


    // Load in hardcoded phase offsets
    //  and initialize state machine
    always @ (posedge sys_clk) begin
        case (init_state_machine)
            0: init_state_machine <= init_state_machine + 1;
            1: begin
                set_phase_advance <= 1'b1;
                init_state_machine <= init_state_machine + 1;
            end
            2: init_state_machine <= init_state_machine + 1;
            3: begin
                set_phase_advance <= 1'b0;
                init_state_machine <= init_state_machine + 1;
            end
            4: begin
                init_state_machine <= init_state_machine + 1;
                enable_nco_reg <= 1'b1;
            end


        endcase
    end
endmodule



 


module nco_w_phase_in
#(
    parameter NCO_ADDR_BITS = 8
)
(
    input sys_clk,
    input nco_en,
    input apply_phase_advance,
    input [(NCO_ADDR_BITS - 1):0]phase_advance,

    input [15:0]nco_divider,
    input nco_lfo,

    output reg [(NCO_ADDR_BITS - 1):0]addr_out
);

    reg [15:0]nco_accum;

    reg [(NCO_ADDR_BITS - 1):0]curr_phase_offset;

    initial begin
        addr_out = 8'h00;
        curr_phase_offset = 8'h00;
        nco_accum = {16{1'b0}};
    end


    always @ (posedge sys_clk) begin
        nco_accum <= nco_accum + 1;

        if(nco_en) begin
            if(nco_lfo) begin
                // Make this half speed
                if(nco_accum == nco_divider) begin
                    addr_out <= addr_out + 1;
                    nco_accum <= {16{1'b0}};
                end
            end
            else begin
                // Lowest potential output is like 4Hz
                if(nco_accum == nco_divider) begin
                    addr_out <= addr_out + 1;
                    nco_accum <= {16{1'b0}};
                end
            end
        end
        else begin
            addr_out <= curr_phase_offset;
        end

        if(apply_phase_advance) begin
            if(phase_advance != curr_phase_offset) begin
                addr_out <= addr_out + (phase_advance - curr_phase_offset);
                curr_phase_offset <= phase_advance;
            end
        end

    end

endmodule

