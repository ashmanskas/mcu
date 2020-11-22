`default_nettype none
`timescale 1ns/1ps

module tb;

   // regs and wires go here
   wire       go;
   reg        clk;
   wire       reset;
   
   wire       din;

   reg [63:0] result;

   wire       GND;
    
   wire       error;
   wire       done;

   wire       working;


   assign GND = 1'b0;
   assign reset = 1'b0;
   assign go = 1'b0;
   assign working = 1'b0;
   
   read_ds2411 rd2411
     (.go(go),
      .clk(clk),
      .reset(reset),
      .result(result),
      .din(din),
      .done(done),
      .GND(GND),
      .error(error),
      .working(working));

    initial begin
       clk <= 0;
       while (1) begin
          #5;  // delay 5 units (which we defined above to be ns)
          clk = !clk;
       end
    end
   
   initial begin
      $dumpfile("tb.lxt");
      $dumpvars(0, tb);
   end
endmodule
