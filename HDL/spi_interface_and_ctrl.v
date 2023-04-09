








 


module nco_w_phase_in
#(
    parameter NCO_ADDR_BITS = 8
)
(
    input sys_clk,

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

        if(apply_phase_advance) begin
            if(phase_advance != curr_phase_offset) begin
                addr_out <= addr_out + (phase_advance - curr_phase_offset);
                curr_phase_offset <= phase_advance;
            end
        end

    end

endmodule

