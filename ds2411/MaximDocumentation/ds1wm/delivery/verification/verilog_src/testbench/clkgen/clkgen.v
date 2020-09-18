module clkgen(CLK,SEL);

   output CLK;
   input [7:0] SEL;


   reg CLK;
   
   reg clk_1mhz;
   reg clk_4mhz;
   reg clk_5mhz;
   reg clk_6mhz;
   reg clk_7mhz;
   reg clk_8mhz;
   reg clk_10mhz; 
   reg clk_12mhz; 
   reg clk_14mhz; 
   reg clk_16mhz; 
   reg clk_20mhz; 
   reg clk_24mhz; 
   reg clk_28mhz; 
   reg clk_32mhz; 
   reg clk_40mhz; 
   reg clk_48mhz; 
   reg clk_56mhz; 
   reg clk_64mhz; 
   reg clk_80mhz; 
   reg clk_96mhz; 
   reg clk_112mhz;   
   
   initial begin
      clk_1mhz = 0;
      clk_4mhz = 0;
      clk_5mhz = 0;
      clk_6mhz = 0;
      clk_7mhz = 0;
      clk_8mhz = 0;
      clk_10mhz = 0;
      clk_12mhz = 0;
      clk_14mhz = 0;
      clk_16mhz = 0;
      clk_20mhz = 0;
      clk_24mhz = 0;
      clk_28mhz = 0;
      clk_32mhz = 0;
      clk_40mhz = 0;
      clk_48mhz = 0;
      clk_56mhz = 0;
      clk_64mhz = 0;
      clk_80mhz = 0;
      clk_96mhz = 0;
      clk_112mhz = 0;
      
      fork
   	 forever #500    clk_1mhz   = !clk_1mhz;  
   	 forever #125    clk_4mhz   = !clk_4mhz;  
   	 forever #100    clk_5mhz   = !clk_5mhz;  
   	 forever #83.333 clk_6mhz   = !clk_6mhz;  
   	 forever #71.429 clk_7mhz   = !clk_7mhz;  
   	 forever #62.5   clk_8mhz   = !clk_8mhz;  
   	 forever #50     clk_10mhz  = !clk_10mhz; 
   	 forever #41.667 clk_12mhz  = !clk_12mhz; 
   	 forever #35.714 clk_14mhz  = !clk_14mhz; 
   	 forever #31.25  clk_16mhz  = !clk_16mhz; 
   	 forever #25     clk_20mhz  = !clk_20mhz; 
   	 forever #20.833 clk_24mhz  = !clk_24mhz; 
   	 forever #17.857 clk_28mhz  = !clk_28mhz; 
   	 forever #15.625 clk_32mhz  = !clk_32mhz; 
   	 forever #12.5   clk_40mhz  = !clk_40mhz; 
   	 forever #10     clk_48mhz  = !clk_48mhz; 
   	 forever #8.929  clk_56mhz  = !clk_56mhz; 
   	 forever #7.813  clk_64mhz  = !clk_64mhz; 
   	 forever #6.25   clk_80mhz  = !clk_80mhz; 
   	 forever #5.208  clk_96mhz  = !clk_96mhz; 
   	 forever #4.464  clk_112mhz = !clk_112mhz;
     join   
   end  
    
    
   always @(SEL or clk_4mhz 
   		or clk_5mhz    
   		or clk_6mhz    
   		or clk_7mhz    
   		or clk_8mhz    
   		or clk_10mhz  
   		or clk_12mhz  
   		or clk_14mhz  
   		or clk_16mhz  
   		or clk_20mhz  
   		or clk_24mhz  
   		or clk_28mhz  
   		or clk_32mhz  
   		or clk_40mhz  
   		or clk_48mhz  
   		or clk_56mhz  
   		or clk_64mhz  
   		or clk_80mhz  
   		or clk_96mhz  
   		or clk_112mhz) 
      begin 
   		
   		
         case (SEL)			
         				
             4:    CLK = clk_4mhz;	
             5:    CLK = clk_5mhz;	
             6:    CLK = clk_6mhz;	
             7:    CLK = clk_7mhz;	
             8:    CLK = clk_8mhz;	
             10:   CLK = clk_10mhz;	
             12:   CLK = clk_12mhz;	
             14:   CLK = clk_14mhz;	
             16:   CLK = clk_16mhz;	
             20:   CLK = clk_20mhz;	
             24:   CLK = clk_24mhz;	
             28:   CLK = clk_28mhz;	
             32:   CLK = clk_32mhz;	
             40:   CLK = clk_40mhz;	
             48:   CLK = clk_48mhz;	
             56:   CLK = clk_56mhz;	
             64:   CLK = clk_64mhz;	
             80:   CLK = clk_80mhz;	
             96:   CLK = clk_96mhz;	
             112:  CLK = clk_112mhz;
	     default:  CLK = clk_1mhz;	
         				
         endcase			
      end      
endmodule	    
