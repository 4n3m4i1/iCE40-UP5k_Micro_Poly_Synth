
// Parses midi commands and breaks
//  output into control
module midi_ctrl_unit
#(
    parameter D_W = 16,
    parameter BYTE_W = 8,
    parameter NUM_VOICES = 4,
    parameter VOICE_BITS = 2;
)
(
    input sys_clk,

    input [(BYTE_W - 1):0]MIDI_CMD,
    input [(BYTE_W - 1):0]MIDI_DAT_0,
    input [(BYTE_W - 1):0]MIDI_DAT_1,
    input MIDI_PACKET_RDY,

    output reg [(VOICE_BITS - 1):0] midi_chan_selected,  // Voice
    output reg [(D_W - 1):0]        midi_chan_divider,         // Note
    output reg [(BYTE_W - 1):0]     midi_chan_velocity,     // Velocity


    output reg midi_chan_update,                        // Updates ADSR with velocity
    output reg midi_phase_update
);
    localparam FLAG_SET                     = 1'b1;
    localparam FLAG_CLR                     = 1'b0;

    // Overall State Parameters
    localparam RESET_RDY_FLAGS              = 4'h0;
    localparam WAIT_FOR_NEW_MIDI_PACKET     = 4'h1;


    // MIDI Command Byte Parameters & 3'b111, lead bit unneeded
    localparam CMD_NOTE_OFF                 = 4'h8;
    localparam CMD_NOTE_ON                  = 4'h9;
    localparam CMD_POLY_PRESSURE            = 4'hA;
    localparam CMD_CTRL_CHANGE              = 4'hB;
    localparam CMD_PROG_CHANGE              = 4'hC;
    localparam CMD_CHAN_PRESSURE            = 4'hD;
    localparam CMD_PITCH_BEND               = 4'hE;
    localparam CMD_SYSTEM_MESSAGE           = 4'hF;


    reg [3:0]oa_state;

    reg [(BYTE_W - 1):0]midi_cmd_buffer;
    reg [(BYTE_W - 1):0]midi_da0_buffer;
    reg [(BYTE_W - 1):0]midi_da1_buffer;

    reg [(ADDR_W - 1):0]note_number;
    wire [(D_W - 1):0]note_div_out;
    note_LUT notes
    (
        .bram_clk(~sys_clk),
        .bram_ce(1'b1),
        .bram_addr(note_number),
        .bram_out(note_div_out)             // Works!
    );


    initial begin
        oa_state            = 4'h0;
        midi_chan_selected  = {VOICE_BITS{1'b0}};
        midi_chan_divider   = {D_W{1'b0}};
        midi_chan_update    = FLAG_CLR;
        midi_phase_update   = FLAG_CLR;

        midi_chan_velocity  = {BYTE_W{1'b0}};

        midi_cmd_buffer     = {BYTE_W{1'b0}};
        midi_da0_buffer     = {BYTE_W{1'b0}};
        midi_da1_buffer     = {BYTE_W{1'b0}};
    end

    always @ (posedge sys_clk) begin
        case (oa_state)
            RESET_RDY_FLAGS: begin
                midi_chan_update    <= FLAG_CLR;
                midi_phase_update   <= FLAG_CLR;
                oa_state            <= WAIT_FOR_NEW_MIDI_PACKET;
            end

            WAIT_FOR_NEW_MIDI_PACKET: begin
                if(MIDI_PACKET_RDY) begin
                    midi_cmd_buffer <= MIDI_CMD;
                    midi_da0_buffer <= MIDI_DAT_0;
                    midi_da1_buffer <= MIDI_DAT_1;

                    // Select command from byte
                    oa_state        <= midi_cmd_buffer[7:4];
                    note_number     <= MIDI_DAT_0;
                end
            end

            
            CMD_NOTE_OFF: begin
                midi_chan_selected  <= midi_cmd_buffer[(VOICE_BITS - 1):0];
                midi_chan_divider   <= 16'h0000;
                midi_chan_update    <= FLAG_SET;
            
                oa_state            <= RESET_RDY_FLAGS;
            end
            
            CMD_NOTE_ON: begin
                midi_chan_selected  <= midi_cmd_buffer[(VOICE_BITS - 1):0];
                if(|midi_da0_buffer) midi_chan_divider <= note_div_out;
                else midi_chan_divider <= 16'h0000; //Handle 0 note as turning voice off
                midi_chan_update    <= FLAG_SET;

                oa_state            <= RESET_RDY_FLAGS;
            end

/*
            CMD_POLY_PRESSURE:
            CMD_CTRL_CHANGE:
            CMD_PROG_CHANGE:
            CMD_CHAN_PRESSURE:
            CMD_PITCH_BEND:
            CMD_SYSTEM_MESSAGE:
*/          

            default: oa_state       <= RESET_RDY_FLAGS;
        endcase
    end
endmodule