// Adapts MIDI interface and handles full byte breakout
//  supports running commands

module midi_interface_adapter
#(
    parameter D_W = 16,
    parameter BYTE_W = 8,
    parameter SYSCLK_F = 24000000
)
(
    input sys_clk,
    input MIDI_IN,
    
    output reg [(BYTE_W - 1):0]MIDI_CMD,
    output reg [(BYTE_W - 1):0]MIDI_DAT_0,
    output reg [(BYTE_W - 1):0]MIDI_DAT_1,

    output reg CMD_READY,
    output reg DATA_READY
);

    localparam OA_IDLE  =   3'b000;
    localparam OA_RD_CMD =  3'b001;
    localparam OA_RD_D0 =   3'b010;
    localparam OA_INT_IDLE = 3'b011;
    localparam OA_RD_D1 =   3'b100;
    localparam OA_STALL =   3'b101;
    localparam OA_CLR_FLAGS = 3'b110;
    localparam OA_DELAY =   3'b111;

/*
module single_midi_in
#(
    parameter BYTE_W = 8,               // std byte w
    parameter MIDI_BAUD = 31250,        // 31k250 std midi baud
    parameter MIDI_FRAME_SIZE = 10,     // 8N1 format
    parameter SYSCLK_F = 48000000       // 48M from hfosc
)
(
    input sys_clk,
    input MIDI_IN,

    output reg [(BYTE_W - 1):0] data_rx,
    output reg is_command,
    output reg new_byte_strobe
);
*/
    reg [2:0]oa_state;

    wire [(BYTE_W - 1):0]midi_data_input;
    wire midi_byte_ready, midi_byte_is_cmd;
    single_midi_in 
    #(
        .SYSCLK_F(SYSCLK_F)
    ) SMI (
        .sys_clk(sys_clk),
        .MIDI_IN(MIDI_IN),
        .data_rx(midi_data_input),
        .is_command(midi_byte_is_cmd),
        .new_byte_strobe(midi_byte_ready)
    );

    initial begin
        MIDI_CMD    = {BYTE_W{1'b0}};
        MIDI_DAT_0  = {BYTE_W{1'b0}};
        MIDI_DAT_1  = {BYTE_W{1'b0}};

        CMD_READY   = 1'b0;
        DATA_READY  = 1'b0;

        oa_state = 3'b000;
    end


    always @ (posedge sys_clk) begin
        /*
        if(midi_byte_ready)begin
            midi_temp_reg <= midi_data_input;
            
            if(midi_data_input[8]) oa_state <= oa_state + 1;
            else oa_state <= oa_state + 2;
        end
        */

        case(oa_state)
            OA_IDLE: begin                      // 0x00
                if(midi_byte_ready) begin
                    if(midi_byte_is_cmd) oa_state <= OA_RD_CMD;
                    else oa_state <= OA_RD_D0;
                end
            end
            OA_RD_CMD: begin                    // 0x01
                MIDI_CMD <= midi_data_input;
                CMD_READY <= 1'b1;
                oa_state <= OA_DELAY;
            end
            OA_RD_D0: begin                     // 0x02
                MIDI_DAT_0 <= midi_data_input;
                oa_state <= oa_state + 1;
            end
            OA_INT_IDLE: oa_state <= oa_state + 1;
            OA_RD_D1: begin                     // 0x04
                if(midi_byte_ready) begin
                    MIDI_DAT_1 <= midi_data_input;
                    oa_state <= oa_state + 1;
                end
            end
            OA_STALL: begin                     // 0x05
                DATA_READY <= 1'b1;
                oa_state <= oa_state + 1;
            end
            OA_CLR_FLAGS: begin                 // 0x06
                DATA_READY <= 1'b0;
                oa_state <= OA_IDLE;
                
            end
            OA_DELAY: begin
                oa_state <= oa_state + 1;     // 0x07

//                MIDI_CMD    <= {BYTE_W{1'b0}};
//                MIDI_DAT_0  <= {BYTE_W{1'b0}};
 //               MIDI_DAT_1  <= {BYTE_W{1'b0}};
            end
        endcase
    end 
endmodule