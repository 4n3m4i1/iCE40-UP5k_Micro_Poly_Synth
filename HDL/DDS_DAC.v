
// First Order delta sigma modulator
module fods_mod
#(
    parameter DATA_W = 16
)
(
    input mod_clk,
    input [(DATA_W - 1):0]mod_din,
    output wire mod_dout
);

    reg [(DATA_W):0]mod_accum;

    assign mod_dout = mod_accum[DATA_W];

    initial begin
        //mod_accum = {DATA_W + 1{1'b0}};
        mod_accum = 0;
    end

    always @ (posedge mod_clk) mod_accum <= mod_accum[(DATA_W - 1):0] + mod_din;

endmodule