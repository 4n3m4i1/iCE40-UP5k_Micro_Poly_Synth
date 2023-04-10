module main_state_machine
#(
    parameter BYTE_W = 8,
    parameter D_W = 16
)
(
    input sys_clk,
    input CSN_PAD,
    input SCK_PAD,
    input MOSI_PAD,
    output wire MISO_PAD,


    output reg [(D_W - 1):0]VOICE_0_DIV,
    output reg [(D_W - 1):0]VOICE_1_DIV,
    output reg [(D_W - 1):0]VOICE_2_DIV,
    output reg [(D_W - 1):0]VOICE_3_DIV,
    output reg [(D_W - 1):0]VOICE_4_DIV,
    output reg [(D_W - 1):0]VOICE_5_DIV,
    output reg [(D_W - 1):0]VOICE_6_DIV,
    output reg [(D_W - 1):0]VOICE_7_DIV
    
);

    localparam SPI_ACK = 8'hFF;
    localparam ZERO_BYTE = 8'h00;
    localparam RESERVED_FIELD = 8'hFF;

    reg [2:0]spi_valid_write_edge_detect;   // Rising detector for read valid

    wire [5:0]spi_bytes_recieved;
    wire spi_dreq_loopback;             // Always read data on valid
    wire spi_addr_present, spi_data_present;
    wire spi_accepting_writes;

    wire [(BYTE_W - 1):0]RXD_ADDRESS;
    wire [(BYTE_W - 1):0]RXD_DATA;

    reg [(BYTE_W - 1):0]TXD_DATA;

    
    wire valid_address_rqd;
    assign valid_address_rqd = (RXD_ADDRESS) ? 1'b1 : 1'b1;

    spi_single_clk SPI_ADDR_OPTI_0
    (
        .sys_clk(sys_clk),
        .csn_pad(CSN_PAD),
        .sck_pad(SCK_PAD),
        .mosi_pad(MOSI_PAD),
        .miso_pad(MISO_PAD),

        .spi_data_written(spi_dreq_loopback),
        .spi_dreq(spi_dreq_loopback),

        .spi_data_to_send(TXD_DATA),
        .spi_address_rx(RXD_ADDRESS),
        .spi_address_rx_valid(spi_addr_present),

        .spi_data_byte_rx(RXD_DATA),
        .spi_data_byte_rx_valid(spi_data_present),

        .valid_read(spi_accepting_writes),
        .byte_ctr(spi_bytes_recieved)
    );



    reg [15:0]t_acc;

    initial begin
        spi_valid_write_edge_detect = 0;
    
        TXD_DATA = {(BYTE_W){1'b0}};

        t_acc = 16'h0000;

        VOICE_0_DIV = 16'h0000;
        VOICE_1_DIV = 16'h0000;
        VOICE_2_DIV = 16'h0000;
        VOICE_3_DIV = 16'h0000;
        VOICE_4_DIV = 16'h0000;
        VOICE_5_DIV = 16'h0000;
        VOICE_6_DIV = 16'h0000;
        VOICE_7_DIV = 16'h0000;
    end

    
    always @ (posedge sys_clk) begin
        spi_valid_write_edge_detect <= {spi_valid_write_edge_detect[1], 
                                        spi_valid_write_edge_detect[0], 
                                        spi_accepting_writes};

        // detected valid write condition
        if(spi_valid_write_edge_detect == 3'b011) begin
        //if(valid_for_write_to_spi && spi_addr_valid) begin
            casez (spi_bytes_recieved)
                // Implicit Garbage on 1st byte sent back
                6'b000000: TXD_DATA <= SPI_ACK;                                     // Send ACK
                6'b000001: begin
                    if(RXD_ADDRESS[(BYTE_W - 1)]) begin     // Write Command
                        t_acc <= RXD_DATA;
                        /*
                        case (RXD_ADDRESS[2:0])
                            0: VOICE_0_DIV <= {RXD_DATA, VOICE_0_DIV[7:0]};
                            0: VOICE_1_DIV <= {RXD_DATA, VOICE_1_DIV[7:0]};
                            0: VOICE_2_DIV <= {RXD_DATA, VOICE_2_DIV[7:0]};
                            0: VOICE_3_DIV <= {RXD_DATA, VOICE_3_DIV[7:0]};
                            0: VOICE_4_DIV <= {RXD_DATA, VOICE_4_DIV[7:0]};
                            0: VOICE_5_DIV <= {RXD_DATA, VOICE_5_DIV[7:0]};
                            0: VOICE_6_DIV <= {RXD_DATA, VOICE_6_DIV[7:0]};
                            0: VOICE_7_DIV <= {RXD_DATA, VOICE_7_DIV[7:0]};
                        endcase
                        */
                    end
                    else begin                              // Read Command
                        case (RXD_ADDRESS[2:0])
                            0:  TXD_DATA <= VOICE_0_DIV[15:8];
                            1:  TXD_DATA <= VOICE_1_DIV[15:8];
                            2:  TXD_DATA <= VOICE_2_DIV[15:8];
                            3:  TXD_DATA <= VOICE_3_DIV[15:8];
                            4:  TXD_DATA <= VOICE_4_DIV[15:8];
                            5:  TXD_DATA <= VOICE_5_DIV[15:8];
                            6:  TXD_DATA <= VOICE_6_DIV[15:8];
                            7:  TXD_DATA <= VOICE_7_DIV[15:8];
                        endcase
                    end
                end
                6'b000010: begin
                    if(RXD_ADDRESS[(BYTE_W - 1)]) begin     // Write Command
                      //  t_acc <= {t_acc[7:0], RXD_DATA};
                        case (RXD_ADDRESS[2:0])
                            0: VOICE_0_DIV <= {t_acc[7:0], RXD_DATA};
                            0: VOICE_1_DIV <= {t_acc[7:0], RXD_DATA};
                            0: VOICE_2_DIV <= {t_acc[7:0], RXD_DATA};
                            0: VOICE_3_DIV <= {t_acc[7:0], RXD_DATA};
                            0: VOICE_4_DIV <= {t_acc[7:0], RXD_DATA};
                            0: VOICE_5_DIV <= {t_acc[7:0], RXD_DATA};
                            0: VOICE_6_DIV <= {t_acc[7:0], RXD_DATA};
                            0: VOICE_7_DIV <= {t_acc[7:0], RXD_DATA};
                        endcase
                        /*
                        case (RXD_ADDRESS[2:0])
                            0: VOICE_0_DIV <= {VOICE_0_DIV[15:8], RXD_DATA};
                            0: VOICE_1_DIV <= {VOICE_1_DIV[15:8], RXD_DATA};
                            0: VOICE_2_DIV <= {VOICE_2_DIV[15:8], RXD_DATA};
                            0: VOICE_3_DIV <= {VOICE_3_DIV[15:8], RXD_DATA};
                            0: VOICE_4_DIV <= {VOICE_4_DIV[15:8], RXD_DATA};
                            0: VOICE_5_DIV <= {VOICE_5_DIV[15:8], RXD_DATA};
                            0: VOICE_6_DIV <= {VOICE_6_DIV[15:8], RXD_DATA};
                            0: VOICE_7_DIV <= {VOICE_7_DIV[15:8], RXD_DATA};
                        endcase
                        */
                    end
                    else begin                              // Read Command
                        case (RXD_ADDRESS[2:0])
                            0:  TXD_DATA <= VOICE_0_DIV[7:0];
                            1:  TXD_DATA <= VOICE_1_DIV[7:0];
                            2:  TXD_DATA <= VOICE_2_DIV[7:0];
                            3:  TXD_DATA <= VOICE_3_DIV[7:0];
                            4:  TXD_DATA <= VOICE_4_DIV[7:0];
                            5:  TXD_DATA <= VOICE_5_DIV[7:0];
                            6:  TXD_DATA <= VOICE_6_DIV[7:0];
                            7:  TXD_DATA <= VOICE_7_DIV[7:0];
                        endcase
                    end
                end

                6'b??????: TXD_DATA <= ZERO_BYTE; 
            endcase
        end

    end

endmodule