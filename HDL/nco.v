
module simple_nco
#(
    parameter D_W = 16,
    parameter ADDR_W = 8
)
(
    input sys_clk,
    input [(D_W - 1):0]nco_div,
    output reg [(ADDR_W - 1):0]nco_addr
);
    localparam RST_ADDR = {ADDR_W{1'b0}};

    reg [(D_W - 1):0]buffered_div;
    reg [(D_W - 1):0]nco_ctr;

    reg note_state;

    initial begin
        nco_addr = RST_ADDR;
        buffered_div = {D_W{1'b0}};
        nco_ctr = {D_W{1'b0}};

        note_state = 1'b0;
    end

    always @ (posedge sys_clk) begin
        case (note_state)
            0: begin
                nco_ctr <= nco_ctr + 1;
                buffered_div <= nco_div;
                
                if(nco_ctr >= buffered_div) note_state <= 1'b1;
            end

            1: begin
                nco_ctr <= 16'h0000;
                nco_addr <= nco_addr + 1;
                note_state <= 1'b0;
            end
        endcase
    end
endmodule