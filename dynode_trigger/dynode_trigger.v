`default_nettype none

// This code was written in 2013 by Ben Legeyt and has not yet been
// tried. It is likely that we will need to make extensive
// modifications to turn it into what we want.

module dynode_trigger 
  (
   input  wire        clk,
   input  wire        reset,
   input  wire [33:0] ibus,
   output wire [15:0] obus,
   input  wire [7:0]  data_in,
   output reg         single,
   output reg  [5:0]  offset
   );

    initial begin
        // initialize all 'reg' outputs at simulation power-up
        single = 0;
        offset = 0;
    end

    // register reset signal to reduce fanout
    reg rst_local = 1'b0;
    always @ (posedge clk) rst_local <= reset;

    // register BUS
    wire [7:0] energy_thresh_low;
    wire [7:0] energy_thresh_high;
    wire [7:0] timing_pickoff_level;
    bregpl #('h0E00,8) r0E00(ibus, obus, energy_thresh_low);
    bregpl #('h0E01,8) r0E01(ibus, obus, energy_thresh_high);

    // watch for values over thresh_low then pick off maximum value
    reg found_max_tick = 1'b0;
    reg [7:0] max_val = 8'b0;
    reg [7:0] data_in_d = 8'b0;
    reg [7:0] data_in_dd = 8'b0;
    reg over_thresh = 1'b0;
    reg over_thresh_d = 1'b0;
    reg increasing = 1'b0;
    reg increasing_d = 1'b0;
    wire over_thresh_tick = 
         (data_in > energy_thresh_low) && (over_thresh == 1'b0);
    always @ (posedge clk) begin
	over_thresh_d <= over_thresh;
	data_in_d <= data_in;
	data_in_dd <= data_in_d;
	increasing_d <= increasing;
	over_thresh <= (data_in > energy_thresh_low) ? 1'b1 : 1'b0;
	increasing <= (data_in >= data_in_d) ? 1'b1 : 1'b0;
	// find local max and check that it is above threshold
	// could squeeze one clock of latency out of this if necessary.
	if ((increasing == 1'b0) && (increasing_d == 1'b1) && over_thresh_d) 
        begin
	    max_val <= data_in_dd;
	    found_max_tick <= 1'b1;
	end else begin
	    max_val <= max_val;
	    found_max_tick <= 1'b0;
	end
    end

    // timing pickoff is half of maximum value
    assign timing_pickoff_level = {1'b0,max_val[7:1]};

    // we have to know the max_val in order to get the timing pickoff
    // for the timing calculation, so generate delayed copies of the
    // data for the timing calculation
    reg [7:0] data_delay [9:0];
    always @ (posedge clk) begin
	data_delay[0] <= data_in;
	data_delay[1] <= data_delay[0];
	data_delay[2] <= data_delay[1];
	data_delay[3] <= data_delay[2];
	data_delay[4] <= data_delay[3];
	data_delay[5] <= data_delay[4];
	data_delay[6] <= data_delay[5];
	data_delay[7] <= data_delay[6];
	data_delay[8] <= data_delay[7];
	data_delay[9] <= data_delay[8];
    end

    wire [7:0] timing_data = data_delay[6];
    wire [7:0] timing_data_d = data_delay[7];
    reg [7:0] value_above = 8'b0;
    reg [7:0] value_below = 8'b0;
    reg found_timing_value = 1'b0;
    reg [23:0] timing_value_large = 24'b0; // assumed decimal point
                                           // between 16th and 17th
                                           // bits
    
    // Pick off the 8 bits just below the decimal point.  This will be
    // pared further to 6 bits.  6'b111111 is a special code that
    // denotes no trigger, so do not allow this value to propagate
    // through.
    wire [7:0] timing_value = 
               timing_value_large[15:10] == 6'b111111 ? 
               8'hF8 : timing_value_large[15:8];
    reg [7:0] diff0 = 8'b0;
    reg [15:0] diff0_inverse = 16'b0;
    wire [15:0] diff0_inverse_w;
    inverse_lookup il1(diff0,diff0_inverse_w);
    reg [7:0] diff1 = 8'b0;
    reg [3:0] timeout_counter = 4'b0;
    reg [7:0] timing_latch_counter = 8'b0;

    // case where pickoff level is between our 2 data points
    wire timing_latch = 
         (timing_data > timing_pickoff_level) && 
         (timing_data_d <= timing_pickoff_level);
    always @ (posedge clk) begin
	timing_latch_counter <= {timing_latch_counter[6:0],timing_latch};
	if (found_max_tick) begin // set the process in motion
	    found_timing_value <= 1'b0;
	    timeout_counter <= 4'hA; // timeout after 10 ticks if
                                     // value is not found.
	end else begin
	    if (found_timing_value == 1'b0) begin
		timeout_counter <= 
                  timeout_counter == 4'b0 ? 4'b0 : timeout_counter - 1'd1;
		// latch values above and below pickoff
		value_above <= timing_latch ? timing_data : value_above;
		value_below <= timing_latch ? timing_data_d : value_below;
		diff0 <= value_above - value_below; 
                // difference betwen above and below points

		diff1 <= timing_pickoff_level - value_below; 
                // difference between pickoff and below point

		diff0_inverse <= diff0_inverse_w; // register diff0_inverse
		timing_value_large <= diff1 * diff0_inverse; 
                // diff1 divided by diff0 - time pickoff in units of 10ns
                
		// allow 4 clocks for all this to settle (or bail out
		// if timeout hits).
		found_timing_value <= timing_latch_counter[4] | 
                                       (timeout_counter == 4'b0);
	    end else begin 
                // found_timing_value == 1.  hold state here until
                // next cycle.
		timeout_counter <= 4'b0;
		value_above <= value_above;
		value_below <= value_below;
		diff0 <= diff0;
		diff1 <= diff1;
		diff0_inverse <= diff0_inverse;
		timing_value_large <= timing_value_large;
		found_timing_value <= 1'b1;
	    end
	end
    end

    // send out the MCU trigger word only on a single tick, timed to the
    // timing pickoff.
    always @ (posedge clk) begin
	if (rst_local) begin
	    single <= 0;
            offset <= 0;
        end else if (timing_latch_counter[5]) begin
            // Ben's shift-register tells us that we got a trigger
            single <= 1;
            // To my surprise, it looks as if Ben's algorithm does not
            // produce a signed value, so I will keep the sign bit at
            // zero for now
            offset <= {1'b0,timing_value[7:2]};
	end else begin
	    single <= 0;  // fill in value here
            offset <= 0;  // fill in value here
	end
    end
endmodule


module inverse_lookup
  (input  wire [7:0] value,
   output wire [15:0] inverse
   );
    reg [15:0] i;
    assign inverse = i;
    always @ (*) begin
	case(value)
	    0: i='hFFFF; 1: i='hFFFF; 2: i='h8000; 3: i='h5555;
	    4: i='h4000; 5: i='h3333; 6: i='h2AAA; 7: i='h2492;
	    8: i='h2000; 9: i='h1C71; 10: i='h1999; 11: i='h1745;
	    12: i='h1555; 13: i='h13B1; 14: i='h1249; 15: i='h1111;
	    16: i='h1000; 17: i='h0F0F; 18: i='h0E38; 19: i='h0D79;
	    20: i='h0CCC; 21: i='h0C30; 22: i='h0BA2; 23: i='h0B21;
	    24: i='h0AAA; 25: i='h0A3D; 26: i='h09D8; 27: i='h097B;
	    28: i='h0924; 29: i='h08D3; 30: i='h0888; 31: i='h0842;
	    32: i='h0800; 33: i='h07C1; 34: i='h0787; 35: i='h0750;
	    36: i='h071C; 37: i='h06EB; 38: i='h06BC; 39: i='h0690;
	    40: i='h0666; 41: i='h063E; 42: i='h0618; 43: i='h05F4;
	    44: i='h05D1; 45: i='h05B0; 46: i='h0590; 47: i='h0572;
	    48: i='h0555; 49: i='h0539; 50: i='h051E; 51: i='h0505;
	    52: i='h04EC; 53: i='h04D4; 54: i='h04BD; 55: i='h04A7;
	    56: i='h0492; 57: i='h047D; 58: i='h0469; 59: i='h0456;
	    60: i='h0444; 61: i='h0432; 62: i='h0421; 63: i='h0410;
	    64: i='h0400; 65: i='h03F0; 66: i='h03E0; 67: i='h03D2;
	    68: i='h03C3; 69: i='h03B5; 70: i='h03A8; 71: i='h039B;
	    72: i='h038E; 73: i='h0381; 74: i='h0375; 75: i='h0369;
	    76: i='h035E; 77: i='h0353; 78: i='h0348; 79: i='h033D;
	    80: i='h0333; 81: i='h0329; 82: i='h031F; 83: i='h0315;
	    84: i='h030C; 85: i='h0303; 86: i='h02FA; 87: i='h02F1;
	    88: i='h02E8; 89: i='h02E0; 90: i='h02D8; 91: i='h02D0;
	    92: i='h02C8; 93: i='h02C0; 94: i='h02B9; 95: i='h02B1;
	    96: i='h02AA; 97: i='h02A3; 98: i='h029C; 99: i='h0295;
	    100: i='h028F; 101: i='h0288; 102: i='h0282; 103: i='h027C;
	    104: i='h0276; 105: i='h0270; 106: i='h026A; 107: i='h0264;
	    108: i='h025E; 109: i='h0259; 110: i='h0253; 111: i='h024E;
	    112: i='h0249; 113: i='h0243; 114: i='h023E; 115: i='h0239;
	    116: i='h0234; 117: i='h0230; 118: i='h022B; 119: i='h0226;
	    120: i='h0222; 121: i='h021D; 122: i='h0219; 123: i='h0214;
	    124: i='h0210; 125: i='h020C; 126: i='h0208; 127: i='h0204;
	    128: i='h0200; 129: i='h01FC; 130: i='h01F8; 131: i='h01F4;
	    132: i='h01F0; 133: i='h01EC; 134: i='h01E9; 135: i='h01E5;
	    136: i='h01E1; 137: i='h01DE; 138: i='h01DA; 139: i='h01D7;
	    140: i='h01D4; 141: i='h01D0; 142: i='h01CD; 143: i='h01CA;
	    144: i='h01C7; 145: i='h01C3; 146: i='h01C0; 147: i='h01BD;
	    148: i='h01BA; 149: i='h01B7; 150: i='h01B4; 151: i='h01B2;
	    152: i='h01AF; 153: i='h01AC; 154: i='h01A9; 155: i='h01A6;
	    156: i='h01A4; 157: i='h01A1; 158: i='h019E; 159: i='h019C;
	    160: i='h0199; 161: i='h0197; 162: i='h0194; 163: i='h0192;
	    164: i='h018F; 165: i='h018D; 166: i='h018A; 167: i='h0188;
	    168: i='h0186; 169: i='h0183; 170: i='h0181; 171: i='h017F;
	    172: i='h017D; 173: i='h017A; 174: i='h0178; 175: i='h0176;
	    176: i='h0174; 177: i='h0172; 178: i='h0170; 179: i='h016E;
	    180: i='h016C; 181: i='h016A; 182: i='h0168; 183: i='h0166;
	    184: i='h0164; 185: i='h0162; 186: i='h0160; 187: i='h015E;
	    188: i='h015C; 189: i='h015A; 190: i='h0158; 191: i='h0157;
	    192: i='h0155; 193: i='h0153; 194: i='h0151; 195: i='h0150;
	    196: i='h014E; 197: i='h014C; 198: i='h014A; 199: i='h0149;
	    200: i='h0147; 201: i='h0146; 202: i='h0144; 203: i='h0142;
	    204: i='h0141; 205: i='h013F; 206: i='h013E; 207: i='h013C;
	    208: i='h013B; 209: i='h0139; 210: i='h0138; 211: i='h0136;
	    212: i='h0135; 213: i='h0133; 214: i='h0132; 215: i='h0130;
	    216: i='h012F; 217: i='h012E; 218: i='h012C; 219: i='h012B;
	    220: i='h0129; 221: i='h0128; 222: i='h0127; 223: i='h0125;
	    224: i='h0124; 225: i='h0123; 226: i='h0121; 227: i='h0120;
	    228: i='h011F; 229: i='h011E; 230: i='h011C; 231: i='h011B;
	    232: i='h011A; 233: i='h0119; 234: i='h0118; 235: i='h0116;
	    236: i='h0115; 237: i='h0114; 238: i='h0113; 239: i='h0112;
	    240: i='h0111; 241: i='h010F; 242: i='h010E; 243: i='h010D;
	    244: i='h010C; 245: i='h010B; 246: i='h010A; 247: i='h0109;
	    248: i='h0108; 249: i='h0107; 250: i='h0106; 251: i='h0105;
	    252: i='h0104; 253: i='h0103; 254: i='h0102; 255: i='h0101;
	endcase
    end
endmodule


module kludge_integrator_trigger
  (
   input  wire        clk,
   input  wire [7:0]  data,       // sequence of unsigned 8-bit samples
   input  wire [15:0] threshold,  // trigger threshold
   output wire        trig,       // we are currently above threshold
   output wire        trig_wide   // trig or (trig delayed 1 tick)
   );
    reg [7:0] d1=0, d2=0, d3=0, d4=0;
    reg [15:0] sum=0;
    reg trig1, trig2;
    always @ (posedge clk) begin
        d1    <= data;
        d2    <= d1;
        d3    <= d2;
        d4    <= d3;
        sum   <= d1+d2+d3+d4;
        trig1 <= (sum > threshold);
        trig2 <= trig1;
    end
    assign trig = trig1;
    assign trig_wide = (trig1 || trig2);
endmodule

`default_nettype wire

