/* ROCSTAR.v
 * top-level source for bPET digitizer firmware
 * much code shamelessly copied from mrb_s3a.v for LaPET MRB
 *   (written by Bill Ashmanskas)
 * authors: ben legeyt (blegeyt@mail.med.upenn.edu),
 * started: Jan 14, 2013
 Rev.  00	10/15/2018	Compile ROCSTAR.v with new dynode_trg.v 

*/

`include "bpet_defs.v"

module rocstar
  (
    input  wire          clk100_inp,     // main clock
    input  wire          clk100_inn,     // main clock

    input  wire          soft_reset,  // momentary-contact switch on board
    input  wire  [7:0]   dip,     // DIP switch bank for settings
    output wire  [7:0]   led,     // LEDs for status display

    output wire          rs232_tx1,        // RS232 debug transmit
    input  wire          rs232_rx1,        // RS232 debug receive

    output  wire         bus_rdatp, // serial busio from microzed
    output  wire         bus_rdatn,
    input wire           bus_wdatp,
    input wire           bus_wdatn,

    output wire [3:0]    ro_sdatp, // readout data link to microzed
    output wire [3:0]    ro_sdatn,
    input wire           ro_holdp, // readout backpressure / BUSY
    input wire           ro_holdn,

    input  wire          test_bench_takes_bus,
    input  wire          test_bench_wr_strobe,
    input  wire          test_bench_addr_strobe,
    input  wire [7:0] uzed_spare_out_p, // these signal names indicate
                                        // microzed data directions...
    input  wire [7:0] uzed_spare_out_n,
    output wire [7:0] uzed_spare_in_p,
    output wire [7:0] uzed_spare_in_n,

    /***********************************************/
    // clock chip
    output wire        clksel,      // SY89828L choose MCU vs. local clock

    /***********************************************/
    // PROM
    output wire        flash_cso_b,       // chip select*
     // change cclk from out to in: wja 2017-06-29
    input wire        flash_cclk,       // serial clock
    output wire        flash_mosi,         // serial data to flash
    input  wire        flash_din,         // serial data from flash

    /***********************************************/
    // Other FPGA config pins (declare here to avoid dual use)
    input wire         HSWAPEN,
    input wire         INIT_B,
    input wire   [1:0] config_mode,

    /***********************************************/
    // ethernet
    input  wire        e_tx_clk, e_rx_clk, e_crs,
    input  wire        e_rx_dv, e_col, e_rx_err,
    inout  wire        e_mdio,
    output wire        e_tx_en, e_nrst, e_mdc,
    input  wire  [3:0] e_rxd,
    output wire  [3:0] e_txd,
    input  wire  [7:0] mac_lsb, // dip switch for mac addr.

    /***********************************************/
    // ADC for DRS4 (AD9222)
    output wire  [1:0] ad9222_pdwn,
    input  wire  [7:0]  DRSA_dp,   // DRS4-A Serial Data from ADC -
                                   // LVDS-positive
    input  wire  [7:0]  DRSA_dn,   // DRS4-A Serial Data from ADC -
                                   // LVDS-negative
    input  wire         DRSA_fcop, // DRS4-A Frame Signal from ADC -
                                   // LVDS-positive
    input  wire         DRSA_fcon, // DRS4-A Frame Signal from ADC -
                                   // LVDS-negative
    input  wire         DRSA_dcop, // DRS4-A DDR Clock from ADC -
                                   // LVDS-positive
    input  wire         DRSA_dcon, // DRS4-A DDR Clock from ADC -
                                   // LVDS-negative
    input  wire  [7:0]  DRSB_dp,   // DRS4-B Serial Data from ADC -
                                   // LVDS-positive
    input  wire  [7:0]  DRSB_dn,   // DRS4-B Serial Data from ADC -
                                   // LVDS-negative
    input  wire         DRSB_fcop, // DRS4-B Frame Signal from ADC -
                                   // LVDS-positive
    input  wire         DRSB_fcon, // DRS4-B Frame Signal from ADC -
                                   // LVDS-negative
    input  wire         DRSB_dcop, // DRS4-B DDR Clock from ADC -
                                   // LVDS-positive
    input  wire         DRSB_dcon, // DRS4-B DDR Clock from ADC -
                                   // LVDS-negative

    /***********************************************/
    // DRS4
    input  wire  [1:0] drs4_plllck,      // PLL lock indicator
    input  wire  [1:0] drs4_dtap,        // domino wave cycle marker
    output wire  [1:0] drs4_wsrin,       // domino write shift register
    input  wire  [1:0] drs4_wsrout,      //   e.g. to sequence several channels
    output wire  [1:0] drs4_refclkp,     // 0.9765625 MHz DRS4 reference clock
    output wire  [1:0] drs4_refclkn,     //   LVDS, 2GHz (sample rate) / 2048
    output wire  [1:0] drs4_resetn,      // not used at present
    output wire  [1:0] dwrite, rsrload, srclk,
    output wire  [1:0] A0, A1, A2, A3, denable, srin,
    output wire  [1:0] clk9222p, clk9222n, // DDR clock for the two
                                           // AD9222s - LVDS
    input  wire  [1:0] srout,

    output wire  [1:0] drs4_cal,
    output wire  [1:0] drs4_ref_sine_ena,

    /***********************************************/
    // ADC for trigger (AD9287)
    input wire [3:0] trig_dp,
    input wire [3:0] trig_dn,
    input wire       trig_dcop,
    input wire       trig_dcon,
    input wire       trig_fcop,
    input wire       trig_fcon,
    // output wire    trig_csb,       // chip select* for serial config I/O
    // inout  wire    trig_sdio,      // serial data in/out
    // output wire    trig_sclk,      // serial data clock
    output wire      trig_pdwn,      //

    /***********************************************/
    // ADC for anodes (AD9633)
    input  wire  [3:0]  adc0_dhp,
    input  wire  [3:0]  adc0_dhn,
    input  wire  [3:0]  adc0_dlp,
    input  wire  [3:0]  adc0_dln,
    input  wire         adc0_fcop,
    input  wire         adc0_fcon,
    input  wire         adc0_dcop,
    input  wire         adc0_dcon,
    input  wire  [3:0]  adc1_dhp,
    input  wire  [3:0]  adc1_dhn,
    input  wire  [3:0]  adc1_dlp,
    input  wire  [3:0]  adc1_dln,
    input  wire         adc1_fcop,
    input  wire         adc1_fcon,
    input  wire         adc1_dcop,
    input  wire         adc1_dcon,
    input  wire  [3:0]  adc2_dhp,
    input  wire  [3:0]  adc2_dhn,
    input  wire  [3:0]  adc2_dlp,
    input  wire  [3:0]  adc2_dln,
    input  wire         adc2_fcop,
    input  wire         adc2_fcon,
    input  wire         adc2_dcop,
    input  wire         adc2_dcon,
    input  wire  [3:0]  adc3_dhp,
    input  wire  [3:0]  adc3_dhn,
    input  wire  [3:0]  adc3_dlp,
    input  wire  [3:0]  adc3_dln,
    input  wire         adc3_fcop,
    input  wire         adc3_fcon,
    input  wire         adc3_dcop,
    input  wire         adc3_dcon,
    output wire         adc0_pdwn,
    output wire         adc1_pdwn,
    output wire         adc2_pdwn,
    output wire         adc3_pdwn,

    /***********************************************/
    // SPI for DACs and ADCs
    output wire         sclk_ADC,
    inout  wire         sdio_ADC,
    output wire [7:0]   csb_ADC,
    output wire         sclk_DAC,
    output wire         din_DAC,
    output wire [7:0]   sync_DAC,
    output wire         sclk_VGA_DAC,
    output wire         din_VGA_DAC,
    output wire [7:0]   sync_VGA_DAC,

    /***********************************************/
    // MCU link.  need to copy MRB scheme if we want to use LaPET MCU as-is
    // output wire        mcu_returnclkp,   // mrb => MCU return clock for framing
    // output wire        mcu_returnclkn,   // will not come from FPGA and should be removed...
    output wire  [1:0] mcu_trigsinglep,  // mrb => MCU 400Mbps x 2 lanes singles triggers
    output wire  [1:0] mcu_trigsinglen,  //
    input  wire        mcu_trigcoincp,   // MCU => mrb coincidence (100-200Mbps)
    input  wire        mcu_trigcoincn,   //
    input  wire  [1:0] self_mcu_trigsinglep,
    input  wire  [1:0] self_mcu_trigsinglen,
    output wire        self_mcu_trigcoincp,
    output wire        self_mcu_trigcoincn,

    /***********************************************/
    // voltage and temp monitors - moved out to microzed

    /***********************************************/
    // trigger in/outs
    input  wire trig_in_prompt,
    input  wire trig_in_delay,
    output wire busy_out_NIM,
    output wire trig_out_NIM

    );

    // place holders for unimplemented logic
    assign trig_out_NIM = 0;
    assign flash_cso_b = 1;
  //  assign flash_cclk = 0;
    assign flash_mosi = 0;
    assign e_tx_en = 0;
    assign e_mdc = 0;
    assign e_txd = 0;
    assign e_nrst = -1;

    // main clock
    wire clk100_ibuf;
    wire clk100_in;
 //  IBUFGDS #(.DIFF_TERM("TRUE"))
//    clk100_input_buffer (.I(clk100_inp), .IB(clk100_inn), .O(clk100_ibuf));
//    BUFG clk100_buffer (.I(clk100_ibuf),.O(clk100_in));

    // soft_reset by bus
    reg soft_reset_bus;
    wire soft_reset_bus_dummy;

    // power-up reset logic.  separate (earlier) reset for clock so
    // DCM is stablilzed before rest of logic is reset.
    reg [11:0] powerup = 12'h000;
    reg [11:0] powerup_clk = 12'b0;
    reg       rst100 = 1'b1;
    reg         rst_clk = 1'b1;
    always @ (posedge clk100_in) begin
        powerup <= (soft_reset || soft_reset_bus)  ?   0 :
                   (powerup[6]==1'b1) ? 12'h040 : powerup+1;
        powerup_clk <= (soft_reset || soft_reset_bus)  ?   0 :
                       (powerup_clk[5]==1'b1) ? 12'h020 : powerup_clk+1;
        rst100 <= (powerup[6]!=1'b1);
        rst_clk <= (powerup_clk[5]!=1'b1);
    end


    // generate clocks.  100MHz for logic,, 400MHz clock for MCU IO,
    // 33.33MHz for AD9222, and 66.67MHz for drs control FSM.  phasing
    // between AD9222 sample clock and DRS4 SRCLK can be controlled
    // here.
    wire mcu_pll_clk_out, mcu_pll_clk_out_bufg,
      mcu_pll_fb_out, mcu_pll_lock, mcu_pll_rst;
    wire clk100_pll, clk, clk_AD9222, clk_AD9222_pll, clk_66, clk_66_pll;
    assign mcu_pll_rst = rst_clk;
    PLL_BASE #(.CLKFBOUT_MULT(4), .CLKOUT0_DIVIDE(4),
               .CLKOUT1_DIVIDE(1), .CLKOUT2_DIVIDE(12),
               .CLKOUT3_DIVIDE(6),.CLKIN_PERIOD(10))
    mcu_pll (.CLKIN(clk100_in), .CLKOUT0(clk100_pll),
             .CLKOUT1(mcu_pll_clk_out), .CLKOUT2(clk_AD9222_pll),
             .CLKOUT3(clk_66_pll), .CLKFBOUT(mcu_pll_fb_out),
             .CLKFBIN(mcu_pll_fb_out), .LOCKED(mcu_pll_lock),
             .RST( 1'b0 /* rst_clk */ ));
    // wja 2017-06-23: I had to comment out reset to get this PLL to work?!

    BUFG clk100_pll_buffer (.I(clk100_pll), .O(clk));
    // had to add this becuase synthesis messages said the PLL could
    // only drive loads along a certain horizontal zone.  could cut
    // out the BUFG if necessary with better pin placement.
    BUFG clk_AD9222_buffer (.I(clk_AD9222_pll),.O(clk_AD9222));
    BUFG clk_66_buffer (.I(clk_66_pll),.O(clk_66));

    // this is the xilinx-blessed way to output a clock signal for
    // spartan-6...
    wire [1:0] drsadcclk_ddr;
    // use a DDR output register in this way for some reason
    ODDR2 drsadcclk_oddr0 (.D0(1), .D1(0),
                           .C0(clk_AD9222), .C1(~clk_AD9222),
                           .Q(drsadcclk_ddr[0]));
    ODDR2 drsadcclk_oddr1 (.D0(1), .D1(0),
                           .C0(clk_AD9222), .C1(~clk_AD9222),
                           .Q(drsadcclk_ddr[1]));
    // then drive through a differential output buffer.
    OBUFDS drsadcclk_buf0 (.I(drsadcclk_ddr[0]),
                           .O(clk9222p[0]), .OB(clk9222n[0]));
    OBUFDS drsadcclk_buf1 (.I(drsadcclk_ddr[1]),
                           .O(clk9222p[1]),.OB(clk9222n[1]));

    // buffer clocks and generate serdesstrobe
    wire mcu_serdesstrobe;
    wire mcu_pll_clk;
    BUFPLL #(.DIVIDE(4),.ENABLE_SYNC("TRUE"))
    txbufp (.GCLK(clk), .IOCLK(mcu_pll_clk), .LOCK(),
            .LOCKED(mcu_pll_lock), .PLLIN(mcu_pll_clk_out),
            .SERDESSTROBE(mcu_serdesstrobe));

    // get the reset onto the main clock domain
    reg rst = 1'b1;
    always @ (posedge clk) rst <= rst100;

    // DRS4 utility & clock pins
    assign drs4_wsrin = drs4_wsrout;
    reg [6:0] refclk_cnt = 7'b0;
    wire refclk;
    wire clk_625;
    wire clk_fb_refclk;
    wire DRS4_clk_speed;


    // generate 62.5MHz clock to divide down for DRS4 refclk.  divide
    // by 64 for 0.97656MHz (2Gsps).  divide by 32 for 1.953MHz
    // (4Gsps).  could potentially get lower jitter here by replacing
    // the DCM with a PLL.  Clocking wizard reports ~200ps pk-pk
    // jitter for PLL and ~500ps pk-pk for DCM.  Bill is doing it this
    // way for the MRB and has gotten good results so far so I won't
    // worry for now.  The DRS4 will pass this through its own
    // internal PLL anyways so there will be some jitter filtering
    // there.

    DCM_SP #(.CLKIN_PERIOD(10.0), .CLK_FEEDBACK("1X"),
             .CLKFX_MULTIPLY(5), .CLKFX_DIVIDE(8))
    dcm_drsrefclk (.RST(rst_clk), .CLKIN(clk100_in),
                   .CLK0(clk_fb_refclk), .CLK180(),
                   .CLK2X(), .CLKFB(clk_fb_refclk), .CLKFX(clk_625));

    always @ (posedge clk_625) begin
        refclk_cnt <= refclk_cnt+1;
    end
    // DRS4_clk_speed=0 gives 2Gsps (divide by 64), =1 gives 4Gsps
    // (divide by 32)
    assign refclk = DRS4_clk_speed == 0 ? refclk_cnt[6] : refclk_cnt[5];
    olvds o_drs4_refclk_0 (refclk, drs4_refclkp[0], drs4_refclkn[0]);
    olvds o_drs4_refclk_1 (refclk, drs4_refclkp[1], drs4_refclkn[1]);

    // generate various counters
    wire tick_1Hz, tick_1kHz, tick_25MHz;
    wire [15:0] uptime;
    counters count123 (.clk(clk), .rst(rst), .counter_1Hz(tick_1Hz),
                       .counter_1kHz(tick_1kHz), .counter_25MHz(tick_25MHz),
                       .uptime(uptime));


    // wrapper for ethernet MAC plus rx, tx, and bus read/write FSMs
    wire [31:0] rofifo_q;
    wire rofifo_ne;
    wire rofifo_full;
    wire [1:0] rofifoflags = {rofifo_ne,rofifo_full};
    wire rofifo_ren;
    wire eth_takes_bus = 0;
    wire pseudotrigger = rofifo_ne;

    assign rs232_tx1 = 1'b0;

    // put together ibus and obus signals for internal BUSio interface
    wire [15:0] baddr, brddata, bwrdata;
    wire        bwr;
    localparam IBUSW = 1+1+16+16;
    wire [IBUSW-1:0] ibus = {clk, bwr, baddr, bwrdata};
    wand [15:0]      obus;
    assign brddata = obus;

    wire busin0, busout;
    reg busin=0, busin1=0, busin2=0, busin3=0, busin4=0;
    ilvds ibusin (busin0, bus_wdatp, bus_wdatn);
    always @ (posedge clk) busin1 <= busin0;
    always @ (posedge clk) busin2 <= busin1;
    always @ (posedge clk) busin3 <= busin2;
    always @ (posedge clk) busin4 <= busin3;
    always @ (posedge clk) busin  <= busin4;
    reg busout1=0, busout2=0;
    always @ (posedge clk) busout1 <= busout;
    always @ (posedge clk) busout2 <= busout1;
    wire [7:0] uzed_spare_in, uzed_spare_out;
    assign uzed_spare_in[0] = busout;  // hack: bus_rdat missing on PCB
    olvds obusout (1'b0, bus_rdatp, bus_rdatn);

    /*
     * Instantiate state machine to accept "bus" commands
     * via ad-hoc serial link from Spartan3AN chip.
     */
    wire [15:0] s3a_addr, s3a_wrdata;
    wire        s3a_wr;
    wire [15:0] rdcount, wrcount, bytecount;
    wire [11:0] busio_debug;
    wire [19:0] busio_debug1;
    busfsm busfsm (.clk(clk), .serialin(busin), .serialout(busout),
		   .wr(s3a_wr), .addr(s3a_addr), .wrdata(s3a_wrdata),
		   .rddata(brddata),
		   .rdcount(rdcount), .wrcount(wrcount),
		   .bytecount(bytecount),
		   .debug(busio_debug),
		   .debug1(busio_debug1));

    assign baddr = s3a_addr;
    assign bwrdata = s3a_wrdata;
    assign bwr = s3a_wr;

    bror #('h0210) r0210(ibus, obus, rdcount);
    bror #('h0211) r0211(ibus, obus, wrcount);
    bror #('h0212) r0212(ibus, obus, bytecount);

    wire ro_hold;
    ilvds ro_hold_lvds (ro_hold, ro_holdp, ro_holdn);

    wire [3:0] ro_sdat;
    olvds ro_sdat0_lvds (ro_sdat[0], ro_sdatp[0], ro_sdatn[0]);
    olvds ro_sdat1_lvds (ro_sdat[1], ro_sdatp[1], ro_sdatn[1]);
    olvds ro_sdat2_lvds (ro_sdat[2], ro_sdatp[2], ro_sdatn[2]);
    olvds ro_sdat3_lvds (ro_sdat[3], ro_sdatp[3], ro_sdatn[3]);

    genvar i;
    generate
        for(i=0; i<8; i=i+1) begin: tb_diff_pairs
            olvds tb_write (uzed_spare_in[i],
                            uzed_spare_in_p[i], uzed_spare_in_n[i]);
            ilvds tb_read (uzed_spare_out[i],
                           uzed_spare_out_p[i], uzed_spare_out_n[i]);
        end
    endgenerate

    bror #('h000e) r000e(ibus, obus, 16'h0000);  // for bus-driven soft resets
    reg fifo_reset = 0;
    always @ (posedge clk) begin
        // To reset data-path FIFOs and readout FSMs via bus, write
        // to address 000e with data bit 0 set.
        fifo_reset <= bwr && baddr==16'h000e && bwrdata[0];
    end

    assign uzed_spare_in[7:1] = 0;

    // Register BUS.
    // Default values for debug
    bror #('h0000) r0000(ibus, obus, 16'h0000); // always reads zero
    bror #('h0001) r0001(ibus, obus, 16'hbeef); // always reads funny message
    bror #('h0002) r0002(ibus, obus, uptime);   // reads seconds since reboot
    wire [15:0] q0003;
    breg #('h0003) r0003(ibus, obus, q0003);    // generic read/write register
    reg [15:0] status_word = 16'b0;
    reg [15:0] eb_error_count_ff = 16'b0;
    wire [15:0] global_config_reg;
    // register reset signal to reduce fanout
    reg rst_bus = 1'b0;
    wire trigger_data_fifo_ne;
    wire trigger_data_fifo_full;
    wire dynode_fifo_full;
    wire dynode_fifo_ne;
    wire anode_fifo_ne;
    wire anode_fifo_full;
    wire anode_busy; // use to throttle triggers
    wire DRS_busy;
    wire eb_active;
    reg [15:0] eb_error_count = 16'b0;

    always @ (posedge clk) rst_bus <= 1'b0; // rst;
    always @ (posedge clk) begin
        if (rst_bus) begin
            status_word <= 16'b0;
            eb_error_count_ff <= 16'b0;
        end else begin
            status_word <= {5'b0, rofifo_full, rofifo_ne,
                            dynode_fifo_full, dynode_fifo_ne,
                            anode_fifo_full, anode_fifo_ne,
                            trigger_data_fifo_full,
                            trigger_data_fifo_ne, anode_busy, DRS_busy,
                            eb_active}; // global status register
            eb_error_count_ff <= eb_error_count;
        end
    end

    // status LEDs
    // readout status
    wire readout_ena;
    // blink to show single and coincident triggers
    reg trig_single_persist = 1'b0;
    reg trig_coinc_persist = 1'b0;
    wire [7:0] MCU_trigger_out;
    wire trigger;

    always @ (posedge clk) begin
        if (rst_bus) begin
            trig_single_persist = 1'b0;
            trig_coinc_persist = 1'b0;
        end else begin
            trig_single_persist = MCU_trigger_out ?
                                  1'b1 : trig_single_persist & ~tick_1kHz;
            trig_coinc_persist = trigger ?
                                  1'b1 : trig_coinc_persist & ~tick_1kHz;
        end
    end

    reg [27:0] foobar = 0;
    always @ (posedge clk) foobar <= foobar + 1;
    assign led[7:4] = foobar[27:24];
    assign led[3:0] = 4'b0101;

    bror #('h0004) r0004(ibus, obus, status_word);
    // event builder error count
    bror #('h0005) r0005(ibus, obus, eb_error_count_ff);
    // global config register
    breg #('h0006) r0006(ibus, obus, global_config_reg);
    // AD9633 PDWN register
    wire [3:0] ad9633_pdwn_reg;
    breg #('h0007,4,'b1111) r0007(ibus, obus, ad9633_pdwn_reg);
    assign adc0_pdwn = ad9633_pdwn_reg[0];
    assign adc1_pdwn = ad9633_pdwn_reg[1];
    assign adc2_pdwn = ad9633_pdwn_reg[2];
    assign adc3_pdwn = ad9633_pdwn_reg[3];
    assign clksel = global_config_reg[0]; // clock select (r0006, bit 0)
    assign readout_ena = global_config_reg[1];
    assign drs4_cal[0] = global_config_reg[2];  // r0006, bit 2
    assign drs4_cal[1] = global_config_reg[3];  // r0006, bit 3
    assign drs4_ref_sine_ena[0] = global_config_reg[4];  // r0006, bit 4
    assign drs4_ref_sine_ena[1] = global_config_reg[5];  // r0006, bit 5

    wire [1:0] ad9222_pdwn_reg;
    breg #('h000A, 2,'b11) r000A(ibus, obus, ad9222_pdwn_reg);
    assign ad9222_pdwn = ad9222_pdwn_reg;

    wire trig_pdwn_reg;
    breg #('h000B, 1,'b1) r000B(ibus, obus, trig_pdwn_reg);
    assign trig_pdwn = trig_pdwn_reg;

    wire [1:0] drs4_pdwn_reg;
    breg #('h000C, 2,'b11) r000C(ibus, obus, drs4_pdwn_reg);
    assign drs4_resetn = drs4_pdwn_reg;

    wire [1:0] drs4_denable_reg;
    breg #('h000D, 2,'b11) r000D(ibus, obus, drs4_denable_reg);
    assign denable = drs4_denable_reg;

    // USED FOR SOFT_RESET
    breg #('h0008,1,'b0) r0008(ibus, obus, soft_reset_bus_dummy);
    always @ (posedge clk) begin
        if (rst_bus) soft_reset_bus <= 1'b0;
        else soft_reset_bus <= bwr & (baddr == 'h0008);
    end

    // values reserved for anode:
    // Integration Pipeline Length: 0A1X
    // Data Pipeline Length: 0A2X
    // Baseline Offset Value: 0A3X
    // Anode Gain Adjust Value: 0A4X
    // ADC Data IO Delay: 0A6X-007X
    // Channel Enable Bit-Mask: 0A80
    // Readout Mode (Off, Normal, Scope): 0A90
    // Baseline Subtraction Mode (Fixed, Tracking): 0AA0

    // values reserved for dynode
    // 0D00: general config register
    // 15: drs select mode: 0=auto, 1=manual
    // 14: drs manual select: 0=DRSA, 1=DRSB.
    // only valid if bit 15 set to 1 (drs select mode manual)
    // 13: channel cascading: 0=disabled, 1=enabled
    // 12: use pedestal correction table: 0=disabled, 1=enabled
    // 11: use gain correction table: 0=disabled, 1=enabled
    // 10-8: code to indicate what to include in readout (to be determined)
    // 7-0: DRS4 channel enable mask for full/scope-mode readout
    // 0D01: readout ncells
    // 0D02: dynode integration window
    // 0D03: rough leading-edge pickoff
    // 0D04: zero-crossing level for clock timing pickoff
    // 8000 - FFFF: DRS4 calibration tables

    // dynode registers for trigger path data
    wire [3:0] dynode_integration_pipeline_len;
    wire [4:0] dynode_data_pipeline_len;
    wire [7:0] dyn_iod [15:0];
    wire [7:0] dyn_iod_frameA, dyn_iod_frameB;
    // dynode pipeline lengths (for energy integration of trigger path)
    breg #('h0D07) r0D07(ibus, obus, dynode_integration_pipeline_len);
    breg #('h0D08) r0D08(ibus, obus, dynode_data_pipeline_len);
    // DRS4 clock speed - for 2 or 4Gsps
    breg #('h0D09) r0D09(ibus, obus, DRS4_clk_speed);

    breg #('h0D10) r0D10(ibus, obus, dyn_iod[0]);
    breg #('h0D11) r0D11(ibus, obus, dyn_iod[1]);
    breg #('h0D12) r0D12(ibus, obus, dyn_iod[2]);
    breg #('h0D13) r0D13(ibus, obus, dyn_iod[3]);
    breg #('h0D14) r0D14(ibus, obus, dyn_iod[4]);
    breg #('h0D15) r0D15(ibus, obus, dyn_iod[5]);
    breg #('h0D16) r0D16(ibus, obus, dyn_iod[6]);
    breg #('h0D17) r0D17(ibus, obus, dyn_iod[7]);
    breg #('h0D18) r0D18(ibus, obus, dyn_iod[8]);
    breg #('h0D19) r0D19(ibus, obus, dyn_iod[9]);
    breg #('h0D1A) r0D1A(ibus, obus, dyn_iod[10]);
    breg #('h0D1B) r0D1B(ibus, obus, dyn_iod[11]);
    breg #('h0D1C) r0D1C(ibus, obus, dyn_iod[12]);
    breg #('h0D1D) r0D1D(ibus, obus, dyn_iod[13]);
    breg #('h0D1E) r0D1E(ibus, obus, dyn_iod[14]);
    breg #('h0D1F) r0D1F(ibus, obus, dyn_iod[15]);

    breg #('h0D20) r0D20(ibus, obus, dyn_iod_frameA);
    breg #('h0D21) r0D21(ibus, obus, dyn_iod_frameB);

    wire [15:0] bitslip_cycles_DRSA, bitslip_cycles_DRSB;
    breg #('h0D22) r0D22(ibus, obus, bitslip_cycles_DRSA);
    breg #('h0D23) r0D23(ibus, obus, bitslip_cycles_DRSB);


    // registers for trigger control.
    wire [1:0] trigger_data_mode; // 0 = normal, 1 = spy, 2 = off
    wire [1:0] trigger_channel_select;
    wire [15:0] trigger_source; // 0 = MCU, 1 = NIM, 2 = software, 3 = timer;
    wire [1:0] trigger_soft;
    reg  [15:0] trigger_soft_count;
    wire [5:0] trigger_data_trigger_delay;
    wire       ignore_trigger_data;
    wire MCU_source; // internal/external
    wire [7:0] trig_iod [3:0];
    wire [7:0] trig_iod_frame;
    wire [7:0] MCU_RX_iod;
    wire [15:0] bitslip_cycles_mcu_rx;
    wire [7:0] self_MCU_RX_iod;
    wire [15:0] bitslip_cycles_self_mcu_rx;
    wire [15:0] self_mcu_offset_remote, self_mcu_offset_local,
                self_mcu_trigger_window;
    breg #('h0100) r0100(ibus, obus, trigger_source);
    breg #('h0E02) r0E02(ibus, obus, trigger_data_mode);
    breg #('h0E03) r0E03(ibus, obus, trigger_channel_select);
    breg #('h0E04) r0E04(ibus, obus, trigger_data_trigger_delay);
    breg #('h0E05) r0E05(ibus, obus, MCU_source);
    breg #('h0E06) r0E06(ibus, obus, MCU_RX_iod);
    bror #('h0E07) r0E07(ibus, obus, bitslip_cycles_mcu_rx);
    breg #('h0E08) r0E08(ibus, obus, self_MCU_RX_iod);
    bror #('h0E09) r0E09(ibus, obus, bitslip_cycles_self_mcu_rx);
    breg #('h0E10) r0E10(ibus, obus, trig_iod[0]);
    breg #('h0E11) r0E11(ibus, obus, trig_iod[1]);
    breg #('h0E12) r0E12(ibus, obus, trig_iod[2]);
    breg #('h0E13) r0E13(ibus, obus, trig_iod[3]);
    breg #('h0E14) r0E14(ibus, obus, trig_iod_frame);

    wire [15:0] bitslip_cycles_trig;
    bror #('h0E15) r0E15(ibus, obus, bitslip_cycles_trig);

    breg #('h0E16) r0E16(ibus, obus, self_mcu_offset_remote);
    breg #('h0E17) r0E17(ibus, obus, self_mcu_offset_local);
    breg #('h0E18) r0E18(ibus, obus, self_mcu_trigger_window);

    breg #('h0E20, 2,'b0) r0E20(ibus, obus, trigger_soft); // software trigger
    bror #('h0E21) r0E21(ibus, obus, trigger_soft_count);
    breg #('h0E22, 1) r0E22(ibus, obus, ignore_trigger_data);

    reg [15:0] latest_trigger_word = 16'b0;
    always @ (posedge clk)
      latest_trigger_word <= MCU_trigger_out == 8'hFF ?
                             latest_trigger_word : {8'b0,MCU_trigger_out};
    bror #('h0E19) r0E19(ibus, obus, latest_trigger_word);

    // spy buffer is controlled by global event builder
    // spy buffer input mux
    wire [1:0] spybuf_input_select;
    // localparam SPYBUF_SELECT_DYNODE=1, SPYBUF_SELECT_ANODE=2,
    // SPYBUF_SELECT_TRIGGER=3, SPYBUF_SELECT_NONE=0;
    reg spybuf_fifo_ren;
    wire spybuf_fifo_ne;
    wire[15:0] spybuf_fifo_q;
    wire [15:0] spybuf_dummy_ren;
    reg spybuf_fifo_ne_ff = 1'b0;
    reg [15:0] spybuf_fifo_q_ff = 16'b0;
    always @ (posedge clk) begin
        if (rst_bus) begin
            spybuf_fifo_ne_ff <= 1'b0;
            spybuf_fifo_q_ff <= 16'b0;
        end else begin
            spybuf_fifo_ne_ff <= spybuf_fifo_ne;
            spybuf_fifo_q_ff <= spybuf_fifo_q;
        end
    end

    breg #('h0201) r0201(ibus, obus, spybuf_input_select);
    bror #('h0202) r0202(ibus, obus, {15'b0,spybuf_fifo_ne_ff});
    breg #('h0203) r0203(ibus, obus, spybuf_dummy_ren);
    always @ (posedge clk) begin
        if (rst_bus) spybuf_fifo_ren <= 1'b0;
        else spybuf_fifo_ren <= bwr & (baddr == 'h0203);
    end
    bror #('h0204) r0204(ibus, obus, spybuf_fifo_q_ff);


    // data reduction settings
    // readout mode (scope, full, data reduction)
    // position mode (global, local, gaussian, etc)
    // timing mode (regression, others?)
    // timing pick-off level
    // channel enables (full and scope modes)
    // clock source (local, MCU)
    // trigger latency
    // trigger source (local, MCU, NIM)

    /*************************************************************************/
    // SPI controls for VGA DACs
    wire [15:0] SPI_VGA_DAC_select_mask; // which DAC to select
    breg #('h0101) r0101(ibus, obus, SPI_VGA_DAC_select_mask);
    wire [15:0] SPI_VGA_DAC_data; // data to write to DAC.
    // format is {ctrl bit,DAC channel[2:0],DAC setting[7:0],dont care[3:0]}
    localparam SPI_VGA_DAC_WRITE_REGISTER='h0102;
    breg #(SPI_VGA_DAC_WRITE_REGISTER) r0102(ibus, obus, SPI_VGA_DAC_data);

    // check that bus address is the DAC address
    wire SPI_VGA_DAC_addr_ok = baddr == SPI_VGA_DAC_WRITE_REGISTER;

    wire vga_load, vga_go;
    AD53x8_serial_ctrl
      SPI_VGA_DAC (
                   .clk(clk),
                   .reset(rst),
                   .load(bwr & SPI_VGA_DAC_addr_ok),
                   .data_in(SPI_VGA_DAC_data),
                   .chip_select_mask(SPI_VGA_DAC_select_mask[7:0]),
                   .SCLK(sclk_VGA_DAC),
                   .DIN(din_VGA_DAC),
                   .SYNC(sync_VGA_DAC),
                   .dbg_load(vga_load), .dbg_go(vga_go));

    // SPI controls for other DACs
    wire [15:0] SPI_DAC_select_mask; // which DAC to select
    breg #('h0103) r0103(ibus, obus, SPI_DAC_select_mask);
    wire [15:0] SPI_DAC_data; // data to write to DAC.
    // format is {ctrl bit,DAC channel[2:0],DAC setting[7:0],dont care[3:0]}
    localparam SPI_DAC_WRITE_REGISTER='h0104;
    breg #(SPI_DAC_WRITE_REGISTER) r0104(ibus, obus, SPI_DAC_data);

    // check that bus address is the DAC address
    wire SPI_DAC_addr_ok = baddr == SPI_DAC_WRITE_REGISTER;

    AD53x8_serial_ctrl
      SPI_DAC (
               .clk(clk),
               .reset(rst),
               .load(bwr & SPI_DAC_addr_ok),
               .data_in(SPI_DAC_data),
               .chip_select_mask(SPI_DAC_select_mask[7:0]),
               .SCLK(sclk_DAC),
               .DIN(din_DAC),
               .SYNC(sync_DAC));

    // SPI controls for ADCs and clock chip
    wire [15:0] SPI_ADC_select_mask; // which ADC to select
    breg #('h0105) r0105(ibus, obus, SPI_ADC_select_mask);
    wire [15:0] SPI_ADC_write_data;  // data to write to ADC. format is
                                     //{addr[7:0], data[7:0]}
    localparam SPI_ADC_WRITE_REGISTER='h0106, SPI_ADC_READ_REGISTER='h0107;
    breg #(SPI_ADC_WRITE_REGISTER) r0106(ibus, obus, SPI_ADC_write_data);
    wire [15:0] SPI_ADC_read_addr; // address to read from ADC.  format
                                   // is {addr[7:0] dont care[7:0]}
    breg #(SPI_ADC_READ_REGISTER) r0107(ibus, obus, SPI_ADC_read_addr);
    wire [7:0] SPI_ADC_read_data; // data read back from ADC.
    reg [7:0] SPI_ADC_read_data_ff = 8'b0;
    always @ (posedge clk) begin
        if (rst_bus) SPI_ADC_read_data_ff <= 8'b0;
        else SPI_ADC_read_data_ff <= SPI_ADC_read_data;
    end
    bror #('h0108) r0108(ibus, obus, {8'b0,SPI_ADC_read_data_ff});

    // check that bus address is one of the ADC SPI addresses
    wire SPI_ADC_addr_ok =
         baddr == SPI_ADC_WRITE_REGISTER ||
         baddr == SPI_ADC_READ_REGISTER;
    // multiplex read/write commands
    wire SPI_ADC_RW = baddr == SPI_ADC_READ_REGISTER;
    wire [15:0] SPI_ADC_command = SPI_ADC_RW ?
                SPI_ADC_read_addr : SPI_ADC_write_data;
    wire dbg_sdio_in_ADC;  // so that chipscope can see whether SDIO
                           // is an input vs. an output
    ad92xx_serial_ctrl_v2 SPI_ADC
      (
       .clk(clk),
       .reset(rst),
       .load(bwr & SPI_ADC_addr_ok),
       .chip_select_mask(SPI_ADC_select_mask[7:0]),
       .read_writebar(baddr == SPI_ADC_READ_REGISTER),
       .data_in(SPI_ADC_command),
       .data_out(SPI_ADC_read_data),
       .sclk(sclk_ADC),
       .sdio(sdio_ADC),
       .dbg_sdio_in(dbg_sdio_in_ADC),
       .csb(csb_ADC));

    /*************************************************************************/

    // Dynode trigger
    wire [7:0] trig_chA, trig_chB, trig_chC, trig_chD;
    wire trig_align, trig_data_valid, trig_clk;

    ad9287_s6
      trigadc0 (.din_p(trig_dp), .din_n(trig_dn),
                .clk100(clk), .reset(rst),
                .fco_p(trig_fcop), .fco_n(trig_fcon),
                .dco_p(trig_dcop), .dco_n(trig_dcon),
                .iodelay0(trig_iod[0]), .iodelay1(trig_iod[1]),
                .iodelay2(trig_iod[2]), .iodelay3(trig_iod[3]),
                .iodelayF(trig_iod_frame),
                .qout0(trig_chA), .qout1(trig_chB),
                .qout2(trig_chC), .qout3(trig_chD),
                .channel_align(trig_align), .channel_valid(trig_data_valid),
                .bitslip_cycles(bitslip_cycles_trig), .channel_clk(trig_clk));

    wire [7:0] trig_data_all [3:0];
    assign trig_data_all[0] = trig_chA;
    assign trig_data_all[1] = trig_chB;
    assign trig_data_all[2] = trig_chC;
    assign trig_data_all[3] = trig_chD;

    genvar kk;
    generate
    for (kk=0; kk<4; kk=kk+1) begin: genadc_trig
        // Make a register copy of ADC data q[ii], because a
        // separate registered copy should impact the overall
        // chip timing less than directly probing q[ii].
        reg [7:0] ff_adc_trig_q = 0;
        always @ (posedge clk) ff_adc_trig_q <= trig_data_all[kk];
        bror #('h0AF1+kk,8) r0AF1(ibus, obus, ff_adc_trig_q);
    end
    endgenerate
    bror #('h0AF5, 4) r0AF5(ibus, obus, {trig_data_valid, trig_align});


    // multiplex the 4 possible trigger input channels
    reg [7:0] trigger_channel_mux = 8'b0;
    always @ * begin
        case(trigger_channel_select)
            2'b00: trigger_channel_mux = trig_chA;
            2'b01: trigger_channel_mux = trig_chB;
            2'b10: trigger_channel_mux = trig_chC;
            2'b11: trigger_channel_mux = trig_chD;
        endcase
    end

    // dynode trigger for MCU.
    wire MCU_frame = 1'b0;
    wire trigger_veto;
    
    // trigger pipeline provides variable trigger latency in order to
    // readout the right data
    wire trigger_data_trigger;
    pipeline_64x1 trig_pipeA(.clk(clk), .select(trigger_data_trigger_delay),
                             .input_val(trigger),
                             .output_val(trigger_data_trigger));

    // separate data path for trigger data for both energy integration
    // and also for data spy.
    wire trigger_data_fifo_ren; // controlled by global event builder
    wire [15:0] trigger_data_fifo_q;
    
   assign trigger_veto = 1'b1;
   
   // coincident counter sync to trig_in_prompt
   reg  timsync ;				//time counter   
   reg [7:0] timcnt ;				//time counter   
    always @ (posedge clk) begin
    timsync <= trig_in_prompt ;
        if (trig_in_prompt & !timsync) timcnt <= 8'b0;
        else timcnt <= timcnt + 8'b00000001;
    end

//   wire [7:0] timcnt ;				//time counter   
//    breg #('h1D01, 8) r1D01(ibus, obus, timcnt);    // write register
   wire [3:0] dynadcdly ;		// sets number of clk cyc delays to integrations and baseline 
     breg #('h1D02, 4) r1D02(ibus, obus, dynadcdly);    // write register
  wire [1:0] selecttime ;	// 0 = time from SD, 1 = time from cfd enetot 4 point, 2 = 1 pt
     breg #('h1D03, 2) r1D93(ibus, obus, selecttime);    // write register
  wire [3:0] smoothpmt ;			// set number of points in smooth 1, 2, 3, or 4 
     breg #('h1D04, 4) r1D04(ibus, obus, smoothpmt);    // write register
  wire [11:0] integcntl ;  			// Controls filter on sample count and phase of events passed
     breg #('h1D06, 12) r1D05(ibus, obus, integcntl);    // write register
  
dynode_trg dyntrg
(
	.clk(clk ) ,	// input  clk_sig
	.reset(rst) ,	// input  reset_sig
	.ibus(ibus) ,	// input [33:0] ibus_sig
	.obus(obus) ,	// output [15:0] obus_sig
	.data_in(trigger_channel_mux) ,	// input [7:0] data_in_sig
	.MCU_trigger_out(MCU_trigger_out) ,	// output [7:0] MCU_trigger_out_sig
	//.event_trigger_out(event_trigger_out_sig) ,	// output  event_trigger_out_sig
	//.event_time_out(event_time_out_sig) ,	// output [23:0] event_time_out_sig
	//.enecor_load(enecor_load_sig) ,	// output  enecor_load_sig to bypass FIFO
	//.dyn_evntim(dyn_evntim_sig) ,	// output [23:0] dyn_evntim_sig
	//.pulookup(pulookup_sig) ,	// output [7:0] pulookup_sig
	//.dyn_enecor(dyn_enecor_sig) ,	// output [11:0] dyn_enecor_sig
	.timcnt(timcnt ) ,	// input [7:0] timcnt_sig
	.dynadcdly(dynadcdly) ,	// input [3:0] dynadcdly_sig
	.selecttime(selecttime) ,	// input [1:0] selecttime_sig
	.smoothpmt(smoothpmt) ,	// input [3:0] smoothpmt_sig
	.integcntl(integcntl) ,	// input [11:0] integcntl_sig
//	.adc_delay(adc_delay_sig) ,	// output [7:0] adc_delay_sig
//	.sum_integ(sum_integ_sig) ,	// output [11:0] sum_integ_sig
	.trigger_data_mode(trigger_data_mode) ,	// input [1:0] trigger_data_mode_sig
	.integration_pipeline_len(dynode_integration_pipeline_len) ,	// input [3:0] integration_pipeline_len_sig
	.data_pipeline_len(dynode_data_pipeline_len) ,	// input [4:0] data_pipeline_len_sig
	.trigger_channel_select(trigger_channel_select) ,	// input [1:0] trigger_channel_select_sig
//	.trigger(trigger_data_trigger) ,	// input  trigger_sig
	.trigger_data_fifo_ren(trigger_data_fifo_ren) ,	// input  trigger_data_fifo_ren_sig
	.trigger_data_fifo_q(trigger_data_fifo_q) ,	// output [15:0] trigger_data_fifo_q_sig
	.trigger_data_fifo_ne(trigger_data_fifo_ne) ,	// output  trigger_data_fifo_ne_sig
	.trigger_data_fifo_full(trigger_data_fifo_full) 	// output  trigger_data_fifo_full_sig
);

    // MCU TX
    wire [1:0] trigger_serial;

    MCU_trigger_tx mtx(.clk(clk), .clk_4x(mcu_pll_clk),
                   .serdesstrobe(mcu_serdesstrobe), .rst(rst),
                       .mcu_trigger_data({MCU_frame, trigger_veto,
                                          MCU_trigger_out[7:2]}),
                       .trigger_serial(trigger_serial));

    // generate the LVDS output
    olvds mcu_tx_lvds_lane1 (trigger_serial[0],
                             mcu_trigsinglep[0], mcu_trigsinglen[0]);
    olvds mcu_tx_lvds_lane2 (trigger_serial[1],
                             mcu_trigsinglep[1], mcu_trigsinglen[1]);

    // MCU RX
    wire [3:0] MCU_coincidence;
    wire [3:0] mrx_output;
    wire mrx_valid;
    wire [3:0] trigger_MCU_extern = mrx_valid ?
               mrx_output : 4'h8; // bits are frame, sync, delay,
                                  // prompt
    wire [3:0] trigger_MCU = MCU_source ? MCU_coincidence : trigger_MCU_extern;

    MCU_trigger_rx mrx(.clk(clk), .clk_4x(mcu_pll_clk),
                        .serdesstrobe(mcu_serdesstrobe), .rst(rst),
                        .mcu_trigger_inp(mcu_trigcoincp),
                        .mcu_trigger_inn(mcu_trigcoincn),
                        .data_delay(MCU_RX_iod),
                        .trigger_MCU(mrx_output),
                        .out_valid(mrx_valid),
                        .bitslip_cycles(bitslip_cycles_mcu_rx));

    // self-MCU
    wire coinc_out_wire;
    olvds self_mcu_coinc_out (coinc_out_wire,
                              self_mcu_trigcoincp, self_mcu_trigcoincn);

    wire [7:0] MCU_singles_trigger_time = {MCU_frame,trigger_veto,
                                           MCU_trigger_out[7:2]};

    bpet_self_mcu self_mcu
      (
       .clk(clk),
       .clk_4x(mcu_pll_clk),
       .serdesstrobe(mcu_serdesstrobe),
       .rst(rst),
       .trigger_in_lane1p(self_mcu_trigsinglep[0]),
       .trigger_in_lane1n(self_mcu_trigsinglen[0]),
       .trigger_in_lane2p(self_mcu_trigsinglep[1]),
       .trigger_in_lane2n(self_mcu_trigsinglen[1]),
       .iodelay_trigger_in(self_MCU_RX_iod),
       .bitslip_cycles(bitslip_cycles_self_mcu_rx),
       .timing_offset_remote(self_mcu_offset_remote),
       .timing_offset_local(self_mcu_offset_local),
       .trigger_window(self_mcu_trigger_window),
       .singles_time(MCU_singles_trigger_time),
       .coincidence_out_local(MCU_coincidence),
       .coincidence_out_wire(coinc_out_wire)
       );


    // asynchronous (NIM) trigger RX/synchronizer
    reg [3:0] trigger_synchronizer_prompt = 4'b0;
    reg [3:0] trigger_synchronizer_delay = 4'b0;
    reg NIM_prompt_tick = 1'b0;
    reg NIM_delay_tick = 1'b0;
    wire [1:0] trigger_NIM = {NIM_delay_tick,NIM_prompt_tick};
    // register reset signal to reduce fanout
    reg rst_misc0 = 1'b0;
    always @ (posedge clk) rst_misc0 <= 1'b0; // rst;
    always @ (posedge clk) begin
        if (rst_misc0) begin
            trigger_synchronizer_prompt <= 3'b0;
            trigger_synchronizer_delay <= 3'b0;
            NIM_prompt_tick <= 1'b0;
            NIM_delay_tick <= 1'b0;
        end else begin
            trigger_synchronizer_prompt <=
              {trigger_synchronizer_prompt[2:0],trig_in_prompt};
            NIM_prompt_tick <= trigger_synchronizer_prompt[3:2] == 2'b01;
            trigger_synchronizer_delay <=
              {trigger_synchronizer_delay[2:0],trig_in_delay};
            NIM_delay_tick <= trigger_synchronizer_delay[3:2] == 2'b01;
        end
    end


    // multiplex the various trigger sources onto a single trigger word.
    // trigger word is 2 bits: {delay,prompt}
    wire [1:0] trigger_timer;
    reg [1:0] trigger_2 = 2'b0;
    assign trigger = trigger_2[0] | trigger_2[1];
    wire[1:0]  trigger_soft_ff;
    reg [1:0]  trigger_soft_reg;
    wire prompt_delay = trigger_2[1]; // 1 = delayed trigger, 0 =

    wire busy_override = trigger_source[4];

                                      // prompt (or no trigger)
    reg busy_global = 1'b0;
    always @ (posedge clk) begin
      if (busy_override) begin
          busy_global <= 0;
      end else begin
          busy_global <= DRS_busy || anode_busy || (trigger_data_fifo_full &&
                                                    !ignore_trigger_data);
      end
    end

    assign trigger_soft_ff = trigger_soft_reg;
    always @ (posedge clk) begin
        if (rst_bus) trigger_soft_reg <= 1'b0;
        else trigger_soft_reg <= bwr & (baddr == 'h0E20);
    end

    assign busy_out_NIM = busy_global;
    always @ (posedge clk) begin
        case(trigger_source[1:0])
            2'b00: trigger_2 <= busy_global ? 2'b0 : trigger_MCU[1:0];
            2'b01: trigger_2 <= busy_global ? 2'b0 : trigger_NIM;
            2'b10: trigger_2 <= busy_global ? 2'b0 : trigger_soft_ff;
            2'b11: trigger_2 <= busy_global ? 2'b0 : trigger_timer;
        endcase
    end


    /*************************************************************************/
    // AD9222 - used to read out DRS4
    wire oclk66A, oclk66B;
    wire [95:0] DRS_qA, DRS_qB;
    wire [1:0] qvalid, aligned;
    wire [11:0] q9222 [0:15];

    ad9222_s6
      #(.DA(0), .DB(0), .DC(0), .DD(0), .DE(0),
        .DF(0), .DG(0), .DH(0), .DFr(0))
    ADC_DRSA
      (.din_p(DRSA_dp),
       .din_n(DRSA_dn), .reset(rst), .clk66(clk_66), .fco_p(DRSA_fcop),
       .fco_n(DRSA_fcon), .dco_p(DRSA_dcop), .dco_n(DRSA_dcon),
       .iodelay0(dyn_iod[0]), .iodelay1(dyn_iod[1]),
       .iodelay2(dyn_iod[2]), .iodelay3(dyn_iod[3]),
       .iodelay4(dyn_iod[4]), .iodelay5(dyn_iod[5]),
       .iodelay6(dyn_iod[6]), .iodelay7(dyn_iod[7]),
       .iodelayF(dyn_iod_frameA), .qout(DRS_qA), .dataA(q9222[0]),
       .dataB(q9222[1]), .dataC(q9222[2]), .dataD(q9222[3]),
       .dataE(q9222[4]), .dataF(q9222[5]), .dataG(q9222[6]),
       .dataH(q9222[7]), .qvalid(qvalid[0]),
       .channel_align(aligned[0]),.bitslip_cycles(bitslip_cycles_DRSA));

    ad9222_s6
      #(.DA(0), .DB(0), .DC(0), .DD(0),
        .DE(0), .DF(0), .DG(0), .DH(0), .DFr(8))
    ADC_DRSB
      (.din_p(DRSB_dp), .din_n(DRSB_dn), .reset(rst), .clk66(clk_66),
       .fco_p(DRSB_fcop), .fco_n(DRSB_fcon), .dco_p(DRSB_dcop),
       .dco_n(DRSB_dcon), .iodelay0(dyn_iod[8]),
       .iodelay1(dyn_iod[9]), .iodelay2(dyn_iod[10]),
       .iodelay3(dyn_iod[11]), .iodelay4(dyn_iod[12]),
       .iodelay5(dyn_iod[13]), .iodelay6(dyn_iod[14]),
       .iodelay7(dyn_iod[15]), .iodelayF(dyn_iod_frameB),
       .qout(DRS_qB), .dataA(q9222[8]), .dataB(q9222[9]),
       .dataC(q9222[10]), .dataD(q9222[11]), .dataE(q9222[12]),
       .dataF(q9222[13]), .dataG(q9222[14]), .dataH(q9222[15]),
       .qvalid(qvalid[1]), .channel_align(aligned[1]),
       .bitslip_cycles(bitslip_cycles_DRSB));

    genvar jj;
    generate
	for (jj=0; jj<16; jj=jj+1) begin: genadc
	    // Make a register copy of ADC data q[ii], because a
	    // separate registered copy should impact the overall
	    // chip timing less than directly probing q[ii].
	    reg [11:0] ff_adcq = 0;
	    always @ (posedge clk) ff_adcq <= q9222[jj];
	    bror #('h0AE0+jj,12) r0AE0(ibus, obus, ff_adcq);
	end
    endgenerate
    bror #('h0AF0, 4) r0AF0(ibus, obus, {qvalid,aligned});

    // DRS4 readout and dynode signal processing path
    wire data_strobe;
    wire [9:0] drs4_cell_id;
    wire dynode_fifo_ren;
    wire [15:0] dynode_fifo_q;
    wire dynode_eb_ready;

    dynode_path dyn0
      (
       .clk(clk),
       .reset(rst),
       .ibus(ibus),
       .obus(obus),
       .oclk66A(clk_66),
       .oclk66B(clk_66),
       .DRS_qA(DRS_qA),
       .DRS_qB(DRS_qB),
       .qvalid(qvalid),
       .aligned(aligned),
       .dwrite(dwrite),
       .rsrload(rsrload),
       .srclk(srclk),
       .srout(srout),
       .srin(srin),
       .wsrout(drs4_wsrout),
       .A0(A0),
       .A1(A1),
       .A2(A2),
       .A3(A3),
       .trigger(trigger),
       .prompt_delay(prompt_delay),
       .data_strobe(data_strobe),
       .drs4_cell_id(drs4_cell_id),
       .data_fifo_ne(dynode_fifo_ne),
       .data_fifo_full(dynode_fifo_full),
       .data_fifo_q(dynode_fifo_q),
       .data_fifo_ren(dynode_fifo_ren),
       .event_builder_ready(dynode_eb_ready),
       .DRS_busy(DRS_busy));

    /*************************************************************************/
    // Anode deserialization, integration, baseline,
    // gain, pipeline, data reduction, and event builder
    wire [15:0] anode_fifo_q;
    wire anode_ready = anode_fifo_ne; // maybe make this smarter later on...
    wire anode_fifo_ren;

    anode_path AP
      (
       .clk(clk),
       .rst(rst),
       .fifo_reset(fifo_reset),
       .trigger(trigger),
       .ibus(ibus),
       .obus(obus),
       .adc0_dhp(adc0_dhp),
       .adc0_dhn(adc0_dhn),
       .adc0_dlp(adc0_dlp),
       .adc0_dln(adc0_dln),
       .adc0_fcop(adc0_fcop),
       .adc0_fcon(adc0_fcon),
       .adc0_dcop(adc0_dcop),
       .adc0_dcon(adc0_dcon),
       .adc1_dhp(adc1_dhp),
       .adc1_dhn(adc1_dhn),
       .adc1_dlp(adc1_dlp),
       .adc1_dln(adc1_dln),
       .adc1_fcop(adc1_fcop),
       .adc1_fcon(adc1_fcon),
       .adc1_dcop(adc1_dcop),
       .adc1_dcon(adc1_dcon),
       .adc2_dhp(adc2_dhp),
       .adc2_dhn(adc2_dhn),
       .adc2_dlp(adc2_dlp),
       .adc2_dln(adc2_dln),
       .adc2_fcop(adc2_fcop),
       .adc2_fcon(adc2_fcon),
       .adc2_dcop(adc2_dcop),
       .adc2_dcon(adc2_dcon),
       .adc3_dhp(adc3_dhp),
       .adc3_dhn(adc3_dhn),
       .adc3_dlp(adc3_dlp),
       .adc3_dln(adc3_dln),
       .adc3_fcop(adc3_fcop),
       .adc3_fcon(adc3_fcon),
       .adc3_dcop(adc3_dcop),
       .adc3_dcon(adc3_dcon),
       .busy(anode_busy),
       .fifo_q(anode_fifo_q),
       .fifo_ne(anode_fifo_ne),
       .fifo_full(anode_fifo_full),
       .fifo_ren(anode_fifo_ren));

    /*************************************************************************/
    // Readout fifo.  filled by global event builder, emptied by the
    // ethernet block
    wire [31:0] rofifo_d;
    wire rofifo_wen;

    fifo33  #(.W(32)) rofifo
    (
     .clk(clk),
     .rst(rst),
     .d(rofifo_d),
     .wen(rofifo_wen & readout_ena),
     .ren(rofifo_ren),
     .q(rofifo_q),
     .nempty(rofifo_ne),
     .nearlyfull(rofifo_full)
     );

    /*************************************************************************/
    // global event builder.  pulls data from dynode, anode, and
    // trigger_data fifos and stuffs it into the readout fifo.  also
    // makes data available to spy buffer.

    wire eb_error;
    // register reset signal to reduce fanout
    reg rst_misc1 = 1'b0;
    always @ (posedge clk) rst_misc1 <= 1'b0; // rst;
    always @ (posedge clk) begin
        if (rst_misc1) eb_error_count <= 16'b0;
        else eb_error_count <= eb_error ? eb_error_count + 1 : eb_error_count;
    end

    ROCSTAR_event_builder reb (
        .clk(clk),
        .rst(rst),
        .dynode_fifo_q(dynode_fifo_q),
        .dynode_fifo_ne(dynode_fifo_ne),
        .dynode_fifo_ren(dynode_fifo_ren),
        .anode_fifo_q(anode_fifo_q),
        .anode_fifo_ne(anode_fifo_ne),
        .anode_fifo_ren(anode_fifo_ren),
        .trigger_fifo_q(trigger_data_fifo_q),
        .trigger_fifo_ne(trigger_data_fifo_ne),
        .trigger_fifo_ren(trigger_data_fifo_ren),
        .rofifo_d(rofifo_d),
        .rofifo_full(rofifo_full),
        .rofifo_wen(rofifo_wen),
        .pseudotrigger(),
        .spybuf_input_select(spybuf_input_select),
        .spybuf_fifo_ren(spybuf_fifo_ren),
        .spybuf_fifo_ne(spybuf_fifo_ne),
        .spybuf_fifo_q(spybuf_fifo_q),
        .eb_active(eb_active),
        .eb_error(eb_error)
    );

    reg [15:0] ff_baddr = 0;
    reg [15:0] ff_bwrdata = 0;
    reg        ff_bwr = 0;
    always @ (posedge clk) begin
	ff_baddr <= baddr;
	ff_bwrdata <= bwrdata;
	ff_bwr <= bwr;
    end


    reg [1:0] half_drs4_refclkp = 0;
    reg [1:0] half_drs4_refclkn = 0;
    reg [1:0] half_clk9222p = 0;
    reg [1:0] half_clk9222n = 0;
    reg half_clk625 = 0;
    always @ (posedge clk_625) half_clk625 <= ~ half_clk625;

    // Chipscope integrated logic analyzer & controller
    // Begin Chipscope
    wire [35:0] ila_control;
    wire [63:0]  ila_trig0;
    chipscope_ila ila(.CONTROL(ila_control), .CLK(clk), .TRIG0(ila_trig0));
    chipscope_icon icon(.CONTROL0(ila_control));
    assign ila_trig0[1:0] = A0;
    assign ila_trig0[3:2] = A1;
    assign ila_trig0[5:4] = A2;
    assign ila_trig0[7:6] = A3;
    assign ila_trig0[9:8] = denable;
    assign ila_trig0[11:10] = srin;
    assign ila_trig0[13:12] = drs4_dtap;
    assign ila_trig0[15:14] = drs4_wsrin;
    assign ila_trig0[17:16] = drs4_wsrout;
    assign ila_trig0[18] = refclk;// half_drs4_refclkp;
    assign ila_trig0[19] = half_clk625;
    assign ila_trig0[21:20] = 0;// half_drs4_refclkn;
    assign ila_trig0[23:22] = drs4_plllck;
    assign ila_trig0[25:24] = drs4_resetn;
    assign ila_trig0[27:26] = dwrite;
    assign ila_trig0[29:28] = rsrload;
    assign ila_trig0[31:30] = srclk;
    assign ila_trig0[33:32] = srout;
    assign ila_trig0[35:34] = half_clk9222p;
    assign ila_trig0[37:36] = half_clk9222n;
    assign ila_trig0[39:38] = drs4_cal;
    assign ila_trig0[41:40] = drs4_ref_sine_ena;
    assign ila_trig0[63:42] = 0;
    // End Chipscope

endmodule // ROCSTAR top level

/*---------------------------------------------------------------------------*/


module counters
  (
   input wire clk,
   input wire rst,
   output wire counter_1Hz,
   output wire counter_1kHz,
   output wire counter_25MHz,
   output wire [15:0] uptime);

    // Divide down clk to count milliseconds and seconds
    reg [16:0] countto1ms = 0;  // wraps around once per millisecond
    reg [9:0]  countto1s = 0;   // wraps around once per second
    reg        earlytick_1kHz = 0, tick_1kHz = 0, tick_1Hz = 0;
    always @ (posedge clk) begin
        // 'earlytick' exists so that tick_1Hz and tick_1kHz coincide
        countto1ms <= (countto1ms==99999 ? 0 : countto1ms+1);
        earlytick_1kHz <= (countto1ms==99999);
        tick_1kHz <= earlytick_1kHz;
        if (earlytick_1kHz) countto1s <= (countto1s==999 ? 0 : countto1s+1);
        tick_1Hz <= earlytick_1kHz && countto1s==999;
    end

    // Divide down clk to tick once per 25 MHz period
    reg [1:0] countto40ns = 0;
    reg       tick_25MHz = 0;
    reg       bitclk_25MHz = 0;
    always @ (posedge clk) begin
        // phase tick_25MHz to coincide with tick_1kHz
        countto40ns <= earlytick_1kHz ? 0 : countto40ns+1;
        tick_25MHz <= countto40ns==0;
        bitclk_25MHz <= (countto40ns==3 || countto40ns==0);
    end

    // Count seconds since FPGA configuration
    reg [15:0]  uptime_reg = 0;
    always @ (posedge clk)
      if (tick_1Hz) uptime_reg <= uptime_reg+1;
    assign uptime = uptime_reg;
endmodule


module chipscope_ila
  (CONTROL, CLK, TRIG0) /* synthesis syn_black_box syn_noprune=1 */;
    inout wire [35 : 0] CONTROL;
    input wire CLK;
    input wire [63 : 0] TRIG0;
endmodule

module chipscope_icon(CONTROL0) /* synthesis syn_black_box syn_noprune=1 */;
    inout wire [35 : 0] CONTROL0;
endmodule
