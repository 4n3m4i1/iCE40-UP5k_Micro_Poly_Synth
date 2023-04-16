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

    // Should be 1536 - 2
    localparam CLK_PER_MIDI_BIT = (SYSCLK_F / MIDI_BAUD) - 2;
    //localparam CLK_PER_MIDI_BIT = 11'd768;


    // 768 - 1
    localparam HALF_BIT_PERIOD = CLK_PER_MIDI_BIT / 2;
    //localparam HALF_BIT_PERIOD = 11'd384;

    // Falling edge for start bit
    localparam START_CONDITION = 3'b100;

    //  Start + 8 Data, no parity. +1 for frameindic
    localparam FRAME_SIZE = ( 1 + 8 + 1);

    reg input_buffer;
    reg [1:0]state;
    reg [10:0]clk_accumulator;
    reg [2:0]start_bit_detector;
    reg [(FRAME_SIZE - 1):0]frame_input;
    reg delay_line;

    initial begin
        input_buffer    = 1'b0;
        data_rx         = 8'h00;
        is_command      = 1'b0;
        new_byte_strobe = 1'b0;

        state           = 2'b00;
        clk_accumulator = {11{1'b0}};
        start_bit_detector = 3'b000;
        frame_input     = {FRAME_SIZE{1'b0}};
        delay_line = 1'b0;
    end


    always @ (posedge sys_clk) begin
        input_buffer <= MIDI_IN;
        case(state)
            0: begin // wait for start
                start_bit_detector <= {start_bit_detector[1], start_bit_detector[0], input_buffer};

                new_byte_strobe <= 1'b0;
                is_command <= 1'b0;
                delay_line <= 1'b0;

                if(start_bit_detector == START_CONDITION) begin
                    state <= state + 1;     
                    clk_accumulator <= {11{1'b0}};
                    frame_input <= {1'b1, {(FRAME_SIZE - 1){1'b0}}};
                end
            end

            1: begin    // wait for half bit time offset
                clk_accumulator <= clk_accumulator + 1;

                if(clk_accumulator == HALF_BIT_PERIOD) begin
                    state <= state + 1;
                    clk_accumulator <= {11{1'b0}};
                end
            end

            2: begin    // read in bits
                clk_accumulator <= clk_accumulator + 1;

                if(clk_accumulator == CLK_PER_MIDI_BIT) begin
                    // 10 bit size [9:0], frame size == 10
                    frame_input <= {input_buffer, frame_input[FRAME_SIZE - 1:1]};
                    clk_accumulator <= {11{1'b0}};
                end

                if(frame_input[0]) state <= state + 1;
            end

            3: begin    // Post output
                data_rx <= frame_input[8:1];
                is_command <= frame_input[8];
                new_byte_strobe <= 1'b1;
                delay_line <= 1'b1;
                if(delay_line) begin
                    state <= state + 1;
                    start_bit_detector <= 3'b111;
                end
            end
        endcase
    end


endmodule