`default_nettype none
`timescale 1ns/1ps

module tb;

    // The usual way to make a Verilog testbench is to define a 'reg'
    // for each input of the "device under test" and to define a
    // 'wire' for each output of the DUT, so that the testbench can
    // store values to be fed into the DUT's inputs and can observe
    // the DUT's outputs.
    reg         clk=0;
    reg  [15:0] baddr=0, bwrdata=0;
    wire [15:0] brddata;
    reg         bwr=0, bstrobe=0;
    reg  [7:0]  A1in=0, A2in=0, A3in=0, A4in=0;
    reg  [7:0]  B1in=0, B2in=0, B3in=0, B4in=0;
    wire [3:0]  A1out, A2out, A3out, A4out;
    wire [3:0]  B1out, B2out, B3out, B4out;
    mcu_logic ml
      (.clk(clk), .baddr(baddr), .bwrdata(bwrdata),
       .brddata(brddata), .bwr(bwr), .bstrobe(bstrobe),
       .A1in(A1in), .A2in(A2in), .A3in(A3in), .A4in(A4in),
       .B1in(B1in), .B2in(B2in), .B3in(B3in), .B4in(B4in),
       .A1out(A1out), .A2out(A2out), .A3out(A3out), .A4out(A4out),
       .B1out(B1out), .B2out(B2out), .B3out(B3out), .B4out(B4out));

    // These variables eventually will be part of the rocstar board
    // firmware; they are here for now so that we can use python code
    // to emulate several rocstar boards' communication with the mcu.
    reg [47:0] clkcnt_A1=0, clkcnt_A2=0, clkcnt_A3=0, clkcnt_A4=0;
    reg [47:0] clkcnt_B1=0, clkcnt_B2=0, clkcnt_B3=0, clkcnt_B4=0;
    reg [47:0] clksav_A1=0, clksav_A2=0, clksav_A3=0, clksav_A4=0;
    reg [47:0] clksav_B1=0, clksav_B2=0, clksav_B3=0, clksav_B4=0;

    // Instantiate just one instance (corresponding to just one
    // rocstar board for now) of 'rocstar_mcu_link' logic that we will
    // soon embed into the rocstar board's firmware.
    wire [7:0] A1in2, B1in2;  // This will go away soon
    reg single_A1 = 0, single_A2 = 0, single_A3 = 0, single_A4 = 0;
    reg single_B1 = 0, single_B2 = 0, single_B3 = 0, single_B4 = 0;
    wire [15:0] spword_A1, spword_B1;
    wire runmode_A1, sync_clk_A1, save_clk_A1;
    wire pcoinc_A1, dcoinc_A1, ncoinc_A1;
    wire runmode_B1, sync_clk_B1, save_clk_B1;
    wire pcoinc_B1, dcoinc_B1, ncoinc_B1;
    wire rst = ml.rst;  // We can do this in test bench code!
    rocstar_mcu_link rmA1
      (.clk(clk), .rst(rst), .from_mcu(A1out), .to_mcu(A1in2),
       .clk_ctr(clkcnt_A1[15:0]),
       .single(single_A1), .spword(spword_A1), .runmode(runmode_A1),
       .sync_clk(sync_clk_A1), .save_clk(save_clk_A1),
       .pcoinc(pcoinc_A1), .dcoinc(dcoinc_A1), .ncoinc(ncoinc_A1));
    rocstar_mcu_link rmB1
      (.clk(clk), .rst(rst), .from_mcu(B1out), .to_mcu(B1in2),
       .clk_ctr(clkcnt_B1[15:0]),
       .single(single_B1), .spword(spword_B1), .runmode(runmode_B1),
       .sync_clk(sync_clk_B1), .save_clk(save_clk_B1),
       .pcoinc(pcoinc_B1), .dcoinc(dcoinc_B1), .ncoinc(ncoinc_B1));

    // Create a 100 MHz clock on the 'clk' net, since I've always
    // suspected (but never actually verified) that it was faster to
    // do it in Verilog than to do it in the cocotb Python code.
    initial begin
        clk = 0;
        while (1) begin
            #5;  // delay 5 units (which we defined above to be ns)
            clk = !clk;
        end
    end

    // This is needed to create a (compressed) Value Change Dump file
    // in Icarus Verilog, so that we can view the simulation results
    // with gtkwave.  In commercial simulators, this is not necessary.
    initial begin
        $dumpfile("tb.lxt");
        $dumpvars(0, tb);
    end
endmodule

`default_nettype wire
