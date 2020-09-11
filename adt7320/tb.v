`default_nettype none
`timescale 1ns/1ps

module tb;

    // The usual way to make a Verilog testbench is to define a 'reg'
    // for each input of the "device under test" and to define a
    // 'wire' for each output of the DUT, so that the testbench can
    // store values to be fed into the DUT's inputs and can observe
    // the DUT's outputs.
    reg         clk=0;
    reg         reset=0;
    reg  [2:0]  addr=0;
    reg         dout=0;
    wire [15:0] result;
    wire        cs, sclk, din;
    read_adt7320 ra
      (.clk(clk), .reset(reset), .addr(addr), .result(result),
       .cs(cs), .sclk(sclk), .din(din), .dout(dout));

    // This is here to let us look at a python variable from the
    // Verilog waveform viewer.
    reg [7:0] pycount = 0;

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
