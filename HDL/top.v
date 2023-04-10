

module top
#(
    parameter NUM_SAMPLES = 256,
    parameter D_W = 16,
    parameter BYTE_W = 8
)
(
    input wire gpio_23,         // SCK
    input wire gpio_25,         // ~CS
    input wire gpio_26,         // MOSI
    output wire gpio_27,        // MISO

    output wire gpio_43         // DAC Out
);

    // 48 MHz internal oscillator
    wire clk_48mhz;
    SB_HFOSC internal_HFOSC
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_48mhz)
    );
    defparam internal_HFOSC.CLKHF_DIV = "0b01";


    wire PLL_LOCK, ultra_HF_clk, clk_82_MHz;
    reg dsp_clk;    // runs at ultra_HF_clk / 2

    // Internal PLL, step to 82MHz
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .PLLOUT_SELECT("GENCLK"),
        .DIVR(4'b0010),
        .DIVF(7'b0101000),
        .DIVQ(3'b011),
        .FILTER_RANGE(3'b001)
    ) pll_uut (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .PLLOUTCORE(clk_82_MHz),
        .REFERENCECLK(clk_48mhz),
        .LOCK(PLL_LOCK)
    );

    assign ultra_HF_clk = (PLL_LOCK) ? clk_82_MHz : 1'b0;

    // Handles SPI communication and the setting of voice dividers
    wire [(D_W - 1):0]voice_div_interconnect [7:0];
    main_state_machine MSM_0
    (
        .sys_clk(dsp_clk),
        .CSN_PAD(gpio_25),
        .SCK_PAD(gpio_23),
        .MOSI_PAD(gpio_26),
        .MISO_PAD(gpio_27),

        .VOICE_0_DIV(voice_div_interconnect[0]),
        .VOICE_1_DIV(voice_div_interconnect[1]),
        .VOICE_2_DIV(voice_div_interconnect[2]),
        .VOICE_3_DIV(voice_div_interconnect[3]),
        .VOICE_4_DIV(voice_div_interconnect[4]),
        .VOICE_5_DIV(voice_div_interconnect[5]),
        .VOICE_6_DIV(voice_div_interconnect[6]),
        .VOICE_7_DIV(voice_div_interconnect[7])
    );

    wire [2:0]TDM_CHANNEL;
    wire [(D_W - 1):0]TDM_DATA;
    wire [(8 - 1):0]TDM_ADDRESS;

    chanel_manager VOICE_NCO_CONTROLLER
    (
        .sys_clk(ultra_HF_clk),
        .voice_0_divider(voice_div_interconnect[0]),
        .voice_1_divider(voice_div_interconnect[1]),
        .voice_2_divider(voice_div_interconnect[2]),
        .voice_3_divider(voice_div_interconnect[3]),
        .voice_4_divider(voice_div_interconnect[4]),
        .voice_5_divider(voice_div_interconnect[5]),
        .voice_6_divider(voice_div_interconnect[6]),
        .voice_7_divider(voice_div_interconnect[7]),

        .TDM_ADDRESS_OUT(TDM_ADDRESS),
        .ENABLED_CHANNEL_TDM(TDM_CHANNEL)
    );


/*
module TDM_BRAM_Interface
#(
    parameter D_W = 16,
    parameter VOICES = 8,
    parameter VOICES_BITS = 3
)
(
    input sys_clk,

    input [1:0]selected_wave,

    input [7:0]nco_addr_in,

    output reg enable_DSP_in_phase,

    output reg [(D_W - 1):0]sample_d_out
);
*/
    TDM_BRAM_Interface BRAM_INSTANCES
    (
        .sys_clk(ultra_HF_clk),
        .selected_wave(2'b00),
        .nco_addr_in(TDM_ADDRESS),
        .sample_d_out(TDM_DATA)
    );

    wire [(D_W - 1):0]final_u16_output;
    sample_pipeline SAMP_PROCESS_PIPELINE
    (
        .dsp_clk(dsp_clk),
        .channel_in(TDM_CHANNEL),
        .data_in_fix14_16(TDM_DATA),
        .data_out_u16(final_u16_output)
    );


    fods_mod FIRST_ORDER_DEL_SIG_MODULATOR
    (
        .mod_clk(ultra_HF_clk),
        .mod_din(final_u16_output),                 // 16 bit unsigned in, mid @ 0x7FFF (32,767)
        .mod_dout(gpio_43)
    );

    initial begin
        dsp_clk = 1'b0;
    end

    always @ (posedge ultra_HF_clk) begin
        dsp_clk <= ~dsp_clk;
    end

endmodule