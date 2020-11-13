`default_nettype none
`timescale 1ns/1ps

module tb;

   // regs and wires go here
   wire       go;
   wire       clk;
   wire       reset;
   
   wire       din;

   reg [63:0] result;
 
   wire       error;
   wire       done;


   read_ds2411 rd2411
     (.go(go),
      .clk(clk),
      .reset(reset),
      .result(result),
      .din(din),
      .done(done),
      .error(error))


    initial begin
       clk = 0;
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
