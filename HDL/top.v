

module top
#(
    parameter NUM_SAMPLES = 256,
    parameter D_W = 16,
    parameter BYTE_W = 8,
    parameter NUM_VOICES = 4
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
    defparam internal_HFOSC.CLKHF_DIV = "0b00";

/*
    Currently this is a poor SPI implementation that doesn't work
    that well (or really at all, something is being lost in synthesis.)

    Eventually a MIDI inerface will be here that will handle basic control
    bytes, and allocation of channel frequency values.

    Long term goals include implementing velocity/ADSR input and volume.

    The communications interface should allocate dividers as appropriate
    and not overwrite a divider (voice) until that channel is freed by
    release of a keypress (key off, or key amplitude 0).

    The interface should also latch the command byte until a new command
    byte is sent such that control bytes need not be sent for every channel
    update. As per the MIDI spec of course.
*/

    // Handles SPI communication and the setting of voice dividers
    wire [(D_W - 1):0]voice_div_interconnect [(NUM_VOICES - 1):0];
    main_state_machine MSM_0
    (
        .sys_clk(clk_48mhz),
        .CSN_PAD(gpio_25),
        .SCK_PAD(gpio_23),
        .MOSI_PAD(gpio_26),
        .MISO_PAD(gpio_27),

        .VOICE_0_DIV(voice_div_interconnect[0]),
        .VOICE_1_DIV(voice_div_interconnect[1]),
        .VOICE_2_DIV(voice_div_interconnect[2]),
        .VOICE_3_DIV(voice_div_interconnect[3])
    );

    wire [1:0]TDM_CHANNEL;
    wire [(D_W - 1):0]TDM_DATA;
    wire [(8 - 1):0]TDM_ADDRESS;
/*
    The NCO controller drives the frequency of all voices and acts
    primarily as an address generator.

    Each BRAM wavetable contains a single period of the periodic
    SIN, TRI, SQUARE, and SAW waveforms, meaning:

        f_out = ((input clk / NUM_VOICES) / (nco_divider)) / NUM_SAMPLES

    OR

        f_out = (12E6 / (nco_divider)) / 256 hz

    OR

        f_out = 12E6 / (256 * (nco_divider)) hz

    This means our f_max is:

        f_out_max = 12E6 / (256 * (1)) = 46.87 kHz

    NOTE: This is not the sample rate, rather the fundamental of
        an output sine wave. The sample rate is approx. 48MHz

    The reasonable output range for music is on the order of:

        20Hz - 10kHz

    Humans can hear up to 20kHz when young, however this is annoying
    and too high pitch.

    To bound the frequency ranges a minimum divider of 4 is implemented,
    disabling the NCO and channel if the divider is set lower than this.

    At a min divider of n = 4:

        f_upper_limit = 46.87 kHz / 4 = 11.719 kHz

    OR:

        f_upper_limit = 12E6 / (256 * 4) = 11.719 kHz

    Our reasonable minimum is found at approx 100Hz:

        f_lower_limit = 100

        100 = 12E6 / (256 * div)

        div = 12E6 / (100 * 256) = 468.75 ~= 470

    Solving for nco_divider = 470:

        f_lower_limit = 12E6 / (256 * 470)

        f_lower_limit = 99.73 Hz

    This gives a reasonable input range of:

        Div_lo - Div_hi = 470 - 4 = 464

    This gives an accuracy of:

        f / step = (f_max - f_min) / (div_max - div_min)

        f / step = (11.719kHz - 99.73Hz) / (464)

        f / step = 25 Hz per step

    This makes mapping to lower notes quite difficult,
        however is good resolution for higher frquencies.

    The mapping is approx. 1 note per step near A_4

    The channel manager will produce the address associated with the
        currently selected channel, a flag indicating if the channel
        is enabled (and thus should be considered for end of pipe
        normalization steps), and the value of the currently addressed
        channel that is entering the pipeline.
*/
    wire is_selected_channel_enabled_0;
    wire [1:0]TDM_WAVE;
    chanel_manager VOICE_NCO_CONTROLLER
    (
        .sys_clk(clk_48mhz),
        .voice_0_divider(voice_div_interconnect[0]),
        .voice_1_divider(voice_div_interconnect[1]),
        .voice_2_divider(voice_div_interconnect[2]),
        .voice_3_divider(voice_div_interconnect[3]),

        .TDM_ADDRESS_OUT(TDM_ADDRESS),
        .TDM_WAVEFORM_OUT(TDM_WAVE),
        .CURRENTLY_ADDRESSED_CHANNEL(TDM_CHANNEL),
        .SELECTED_CHANNEL_ENABLED(is_selected_channel_enabled_0)
    );


/*
    The BRAM interface marks the start of the time division multiplexed
    serial processing pipeline. The interface stages all control signals
    such that they are present on the outputs at the same time as the read
    data from the BRAM wavetables are valid on the output.

    This syncronizes the sample and its associated controls through the 
    processing pipeline such that accurate processing can occur.

    This also sets the pace of the pipeline, giving every pipeline stage a
    single clock cycle to be valid. No wait states in stages are permitted.

    The negative edge of the clock is used to syncronize the BRAM, and as
    shown in channel_ctrl. the potential maximum clock we can utilize for
    this task is approx. double the 48MHz clock we are using to drive the
    pipeline forward. 

    By using the negative edge we can prepare an address on RISING,
    trigger BRAM with new address on FALLING, then by next RISING the data
    is valid on the output. On this RISING new addresses are being loaded
    in the previous stage of the pipeline. This means there is a single
    cycle delay through the memory access stage of the pipeline, simplifying
    the pipeline such that only a single clock is required for all stages.

    In short:
        RISING N:   DATA READY[N-1], NEW ADDRESS LOADED[N]
*/
    wire is_selected_channel_enabled_1;
    wire [1:0]TDM_CHANNEL_SYNC_0;
    TDM_BRAM_Interface BRAM_INSTANCES
    (
        .sys_clk(clk_48mhz),
        .selected_wave(TDM_WAVE),
        .nco_addr_in(TDM_ADDRESS),
        .is_chan_en(is_selected_channel_enabled_0),
        .channel_num(TDM_CHANNEL),
        .sample_d_out(TDM_DATA),
        .is_chan_en_out(is_selected_channel_enabled_1),
        .ch_assoc_w_data(TDM_CHANNEL_SYNC_0)
    );

/*
    The sample processing pipeline contains a number
    of stages, each that process the multiplexed sample data
    in some unique way. Many stages may require a number of
    samples from a single channel, and these should accumulate
    samples in such a way that the pipeline never stops moving.

    At the end of this pipeline every NUM_VOICES RISING events
    the channel (voice) values will be summed and normalized
    to the number of active channels following this equation:

        V_o = (s[0] + s[1] + s[2] + s[3]) / (en[0] + en[1] + en[2] + en[3])

    This allows for unused channels to not change the normalization
    of the output after the summing proceduce. This prevents overflows
    and keeps the DAC input values bounded and constant.

    Data types should consist of the Fix15_u16 type until the DAC input,
    where the value should be scaled to the full uin16_6 range.
*/
    wire [(D_W - 1):0]final_u16_output;
    sample_pipeline SAMP_PROCESS_PIPELINE
    (
        .dsp_clk(clk_48mhz),
        .channel_in(TDM_CHANNEL_SYNC_0),
        .is_channel_enabled(is_selected_channel_enabled_1),
        .data_in_fix15_u16(TDM_DATA),
        .data_out_u16(final_u16_output)
    );

/*
    The fods_mod first order delta sigma modulator functions as a 1-bit
    DAC, when joined with a simple RC lowpass on the output pad.

    This module takes in a single 16 bit value and acts as an overflow
    detector utilizing the MSB of a 17 bit accumulator that is added to
    the input value on every clock RISING event.
*/

    fods_mod FIRST_ORDER_DEL_SIG_MODULATOR
    (
        .mod_clk(clk_48mhz),
        .mod_din(final_u16_output),                 // 16 bit unsigned in, mid @ 0x7FFF (32,767)
        .mod_dout(gpio_43)
    );


endmodule