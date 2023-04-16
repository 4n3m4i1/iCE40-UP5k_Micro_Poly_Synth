
/*
    Produces a time division multiplexed stream of addresses,
        one address every clock cycle.
    Dividing real time into NUM_CHANNELS clock cycles,
        you end up with channel address data printed as such:

        Clk Posedge:    0   1   2   3   4   5   6   7   ...
        Channel Sel:    0   1   2   3   0   1   2   3   ...
        
    Each "Channel Sel" indicates the selected channel's address
        to be sent to the BRAM array.

    This could be rewritten as:
        address_for_channel[n] where n = [0,3] or n = [0, NUM_CHANNELS - 1]

    On Each clock the address will be produced, and by the next rising edge
        the BRAM should have valid data on its output.
    
    This requires the BRAM to respond to the negative edge of the clock,
        or the posedge of ~clk

    The channel manager must produce 256 * 4 channels worth of addresses
        per MAX_F period on the output. This is shown by:

        F_bram_clk = 256 samples * 4 channel * 44kHz = 45 MHz

    Due to this the channel manager and BRAM clock must be run at:
        
        approx 48MHz from the internal HFOSC

    This should work well as the BRAM max frequency is approx. 150MHz
        and timing data isn't given beyond:
        
        "Provide address before clock edge, after clock edge data is valid"

        And te 150MHz figure provided on pg. 35 of the datasheet

    So we can assume the use of the negative edge isn't dangerous.
    At worst case the duty cycle of the internal HFOSC is +/-10%
    At worst case the frequency of the internal HFOSC is +/-20%

    Thus the maximum f HFOSC can be in the inducstrial temp range is:
        f_maxHFOSC = 57.6 MHz

    Which at worst case duty cycle (- 10%) gives a high time of:

        (1 / 57.6 MHz) * (0.5 - 0.1) = 6.94444 ns

    Which is nearly equivalent to the entire period of:

        1 / f_BRAMMAX or 1 / 150E6 = 6.666666 ns

    And crucially a 150MHz 50% duty cycle ideal clock produces a 
        high time of:

        6.666666 ns * 50% duty = 3.3333333 ns high time

    From this we can safely assume the negedge triggering is well
        within spec and almost a factor of 2 above the safe timing
        specifications even at worst case.

    The 150MHz clock is given as the minimum max frequency, also
        known as the worst case. It is highly likely the BRAM
        can operate quite a bit faster in normal conditions.

*/
module chanel_manager
#(
    parameter NUM_VOICES = 4,
    parameter D_W = 16,
    parameter ADDR_W = 8
)
(
    input sys_clk,

    input wire [(D_W - 1):0]voice_0_divider,
    input wire [(D_W - 1):0]voice_1_divider,
    input wire [(D_W - 1):0]voice_2_divider,
    input wire [(D_W - 1):0]voice_3_divider,

    input wire [1:0]voice_0_wave,
    input wire [1:0]voice_1_wave,
    input wire [1:0]voice_2_wave,
    input wire [1:0]voice_3_wave,

    output reg [1:0]TDM_WAVEFORM_OUT,
    output reg [(ADDR_W - 1):0]TDM_ADDRESS_OUT,
    output reg [1:0]CURRENTLY_ADDRESSED_CHANNEL,
    output reg SELECTED_CHANNEL_ENABLED
);

    localparam MIN_DIVIDER = 8;

    wire [(ADDR_W - 1):0] nco_addresses [(NUM_VOICES - 1):0];

    wire [(ADDR_W - 1):0] TDM_NCO_ADDR;

    reg [(ADDR_W - 1):0] voice_phase_advance [(NUM_VOICES - 1):0];


    wire enable_nco[3:0];

    assign enable_nco[0] = (voice_0_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[1] = (voice_1_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[2] = (voice_2_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;
    assign enable_nco[3] = (voice_3_divider > MIN_DIVIDER) ? 1'b1 : 1'b0;

    wire [1:0] wavesel [0:3];

    assign wavesel[0] = voice_0_wave;
    assign wavesel[1] = voice_1_wave;
    assign wavesel[2] = voice_2_wave;
    assign wavesel[3] = voice_3_wave;


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

    reg read_load_state;
    reg can_write_to_channel;

    reg [2:0]init_state_machine;


    initial begin
        CURRENTLY_ADDRESSED_CHANNEL = 0;
        SELECTED_CHANNEL_ENABLED = 1'b0;
        enable_nco_reg = 1'b0;
        set_phase_advance = 1'b0;
        read_load_state = 1'b0;

        TDM_WAVEFORM_OUT = 2'b00;

        voice_phase_advance[0] = 7;
        voice_phase_advance[1] = 6;
        voice_phase_advance[2] = 5;
        voice_phase_advance[3] = 4;
    end

    // Address goes out on posedge, 
    //  next posedge data is ready
    always @ (posedge sys_clk) begin
        TDM_ADDRESS_OUT <= nco_addresses[CURRENTLY_ADDRESSED_CHANNEL];
        CURRENTLY_ADDRESSED_CHANNEL <= CURRENTLY_ADDRESSED_CHANNEL + 1;
        SELECTED_CHANNEL_ENABLED <= enable_nco[CURRENTLY_ADDRESSED_CHANNEL];
        TDM_WAVEFORM_OUT <= wavesel[CURRENTLY_ADDRESSED_CHANNEL];
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

    localparam MIN_DIVIDER = 8;

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

