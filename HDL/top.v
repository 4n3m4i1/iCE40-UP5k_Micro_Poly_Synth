

module top
#(
    parameter BYTE_W = 8,
    parameter D_W = 16
)
(
    input gpio_26,              // MIDI D IN

    output wire gpio_3,         // DAC Out

    // Debug LED Bar Graph
    output wire gpio_28,        // MSB
    output wire gpio_38,
    output wire gpio_42,
    output wire gpio_36,

    output wire gpio_43,
    output wire gpio_34,
    output wire gpio_37,
    output wire gpio_31         // LSB
);


    wire clk_48M;               // Main 48MHz Clk
    SB_HFOSC inthfosc
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_48M)
    );
    defparam inthfosc.CLKHF_DIV = "0b00";


// Midi interface and decode START
    wire [7:0]CMD_INTER, D0_INTER, D1_INTER;
    wire MIDI_RX_RDY;

    midi_interface_adapter MIDI_LOW_LEVEL
    (
        .sys_clk(clk_48M),
        .MIDI_IN(gpio_26),
        .MIDI_CMD(CMD_INTER),
        .MIDI_DAT_0(D0_INTER),
        .MIDI_DAT_1(D1_INTER),
        //.CMD_READY()
        .DATA_READY(MIDI_RX_RDY)
    );

    wire [1:0]ch_sel_0;
    wire [15:0]div_sel_0;
    wire update_channel_div;
    midi_ctrl_unit MIDI_HIGH_LEVEL
    (
        .sys_clk(clk_48M),
        .MIDI_CMD(CMD_INTER),
        .MIDI_DAT_0(D0_INTER),
        .MIDI_DAT_1(D1_INTER),
        .MIDI_PACKET_RDY(MIDI_RX_RDY),

        .midi_chan_selected(ch_sel_0),
        .midi_chan_divider(div_sel_0),
        //.midi_chan_velocity(),

        .midi_chan_update(update_channel_div)
        //.midi_phase_update()
    );
// Midi interface and decode END

// TDM Voice Pipeline Start
    // Phases and wave selection not done yet
    wire tdm_voice_enabled_0;
    wire [1:0]tdm_wavesel_0;
    wire [1:0]tdm_voice_num_0;
    wire [7:0]tdm_addr_0;
    voices NCO_AND_PHASE_CONTROL
    (
        .sys_clk(clk_48M),
        .midi_modified_channel(ch_sel_0),
        .midi_modified_divider(div_sel_0),
        .midi_chan_modified_strobe(update_channel_div),

        .wavesel(tdm_wavesel_0),
        .TDM_VOICE_NUM(tdm_voice_num_0),
        .TDM_VOICE_ADDR(tdm_addr_0),
        .TDM_VOICE_ENABLED(tdm_voice_enabled_0)
    );













// Final output DAC
    fods_mod DDS_DAC_OUT
    (
        .mod_clk(clk_48M),
        .mod_din(),
        .mod_dout(gpio_3)
    );

endmodule
