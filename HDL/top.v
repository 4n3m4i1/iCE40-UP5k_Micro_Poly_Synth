

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

    wire [7:0]dbg_div;
 //   wire enable_0;

    assign gpio_28 = dbg_div[7];
    assign gpio_38 = dbg_div[6];
    assign gpio_42 = dbg_div[5];
    assign gpio_36 = dbg_div[4];
    assign gpio_43 = dbg_div[3];
    assign gpio_34 = dbg_div[2];
    assign gpio_37 = dbg_div[1];
    assign gpio_31 = dbg_div[0];


    wire clk_48M;               // Main 48MHz Clk
    SB_HFOSC inthfosc
    (
        .CLKHFEN(1'b1),
        .CLKHFPU(1'b1),
        .CLKHF(clk_48M)
    );
    defparam inthfosc.CLKHF_DIV = "0b00";


////////////////////////////////////////////////////////////
//              MIDI Interface and Control Unit
//                  Read up to 3 byte messages
//                  Supports running command bytes
////////////////////////////////////////////////////////////
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
    wire update_channel_wave;
    wire [1:0]midi_wave_data;
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
        .midi_chan_wave(midi_wave_data),
        .midi_wave_update(update_channel_wave),

        .midi_chan_update(update_channel_div)
        //.midi_phase_update()
    );
// Midi interface and decode END

    assign dbg_div = CMD_INTER;

////////////////////////////////////////////////////////////
//              TDM Start
//                  Multiplex Voices 0 - 3
//                  Every clock into the pipeline
////////////////////////////////////////////////////////////
    wire tdm_voice_enabled;
    wire [1:0]tdm_wavesel;
    wire [1:0]tdm_voice_num;
    wire [7:0]tdm_address;
    voices NCO_AND_PHASE_CONTROL
    (
        .sys_clk(clk_48M),
        .midi_modified_channel(ch_sel_0),
        .midi_modified_divider(div_sel_0),
        .midi_chan_modified_strobe(update_channel_div),

        .wave_input(midi_wave_data),
        .midi_wave_modified_strobe(update_channel_wave),

        .wavesel(tdm_wavesel),
        .TDM_VOICE_NUM(tdm_voice_num),
        .TDM_VOICE_ADDR(tdm_address),
        .TDM_VOICE_ENABLED(tdm_voice_enabled)
    );


////////////////////////////////////////////////////////////
//              BRAM Wavetable LUTs
//                  Pos -> set N, read N-1
//                  Pos -> set N+1, read N
////////////////////////////////////////////////////////////
    wire [(D_W - 1):0]pipeline_data_from_bram;
    wire pipeline_channel_enabled;
    wire [1:0]pipeline_channel_num;
    TDM_BRAM_Interface WAVETABLE_ACCESS
    (
        .sys_clk(clk_48M),
        .selected_wave(tdm_wavesel),
        .nco_addr_in(tdm_address),
        .is_chan_en(tdm_voice_enabled),
        .channel_num(tdm_voice_num),

        .sample_d_out(pipeline_data_from_bram),
        .is_chan_en_out(pipeline_channel_enabled),
        .ch_assoc_w_data(pipeline_channel_num)
    );


////////////////////////////////////////////////////////////
//              Sample Processing Pipeline
//                  Apply: ADSR per channel, filters?, effects?
//                  Apply Modulation maybe?
//        process -> sum -> normalize -> output
////////////////////////////////////////////////////////////
    wire [(D_W - 1):0]DAC_DATA_FROM_PIPELINE;
    TDM_PIPELINE PIPELINE_0
    (
        .sys_clk(clk_48M),
        //.TDM_CHANNEL_NUM(pipeline_channel_num),
        .TDM_DATA_INPUT(pipeline_data_from_bram),
        .TDM_CHANNEL_IS_EN(pipeline_channel_enabled),

        .TDM_DATA_OUTPUT(DAC_DATA_FROM_PIPELINE)
        //.TDM_DATA_SUMMED(DAC_DATA_FROM_PIPELINE)
    );





// Final output DAC
    fods_mod DDS_DAC_OUT
    (
        .mod_clk(clk_48M),
        .mod_din(DAC_DATA_FROM_PIPELINE),
        .mod_dout(gpio_3)
    );

endmodule
