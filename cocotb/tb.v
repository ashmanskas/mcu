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

    // These variables eventually will be part of the rocstar board
    // firmware; they are here for now so that we can use python code
    // to emulate several rocstar boards' communication with the mcu.
    reg [47:0] clkcnt_A1=0, clkcnt_A2=0, clkcnt_A3=0, clkcnt_A4=0;
    reg [47:0] clkcnt_B1=0, clkcnt_B2=0, clkcnt_B3=0, clkcnt_B4=0;
    reg [47:0] clksav_A1=0, clksav_A2=0, clksav_A3=0, clksav_A4=0;
    reg [47:0] clksav_B1=0, clksav_B2=0, clksav_B3=0, clksav_B4=0;

endmodule

`default_nettype wire
