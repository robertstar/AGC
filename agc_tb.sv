`timescale 1ns/1ns
 
module sqrt32(clk, rdy, reset, x, .y(acc));
   input  clk;
   output rdy;
   input  reset;

   input [31:0] x;
   output [15:0] acc;


   // acc holds the accumulated result, and acc2 is the accumulated
   // square of the accumulated result.
   reg [15:0] acc;
   reg [31:0] acc2;

   // Keep track of which bit I'm working on.
   reg [4:0]  bitl;
   wire [15:0] bit = 1 << bitl;
   wire [31:0] bit2 = 1 << (bitl << 1);

   // The output is ready when the bitl counter underflows.
   wire rdy = bitl[4];

   // guess holds the potential next values for acc, and guess2 holds
   // the square of that guess. The guess2 calculation is a little bit
   // subtle. The idea is that:
   //
   //      guess2 = (acc + bit) * (acc + bit)
   //             = (acc * acc) + 2*acc*bit + bit*bit
   //             = acc2 + 2*acc*bit + bit2
   //             = acc2 + 2 * (acc<<bitl) + bit
   //
   // This works out using shifts because bit and bit2 are known to
   // have only a single bit in them.
   wire [15:0] guess  = acc | bit;
   wire [31:0] guess2 = acc2 + bit2 + ((acc << bitl) << 1);

   task clear;
      begin
	 acc = 0;
	 acc2 = 0;
	 bitl = 15;
      end
   endtask

   initial clear;

   always @(reset or posedge clk)
      if (reset)
       clear;
      else begin
	 if (guess2 <= x) begin
	    acc  <= guess;
	    acc2 <= guess2;
	 end
	 bitl <= bitl - 1;
      end

endmodule


module agc_tb;
 
	reg clk;
	reg rst;
	wire signed [15:0] x_in;
	wire signed [15:0] y_out;	
	reg [15:0] ref;
	reg [7:0] addr;	
	reg signed [7:0] sh;	
	wire [7:0] data;	
	reg [7:0] a_coef;
 
	reg [15:0] ref_lvl;
	
	reg signed [15:0] x_t;
 
	always #20 clk = ~clk;
 
 
	always @(posedge clk or negedge rst)
		if(!rst) addr <= 'h0;
		else addr <= addr + 'h1;	
 
	//always @(posedge clk or negedge rst)
	//	if(!rst) ref_lvl <= 'h0;
	//	else if (&addr) ref_lvl <= ref_lvl + 'hf;	
 
	//assign x_in = {$signed(data - 8'h80) , 8'h0} >>> sh;
	//assign x_in = {$signed(data - 8'h80) , 8'h0};
	
	assign x_in = x_t >>> sh;
	
	
	reg signed [31:0] val;
	reg signed [31:0] sum;
	reg [31:0] cnt;
	initial begin
		val<=32'd0;
		sum<=32'd0;
		cnt<=32'd0;
		x_t<=16'd0;
	end
	
	wire rdy;
	wire [15:0] result;
	
	
	sqrt32 root(.clk(clk), .rdy(rdy), .reset(~rst), .x(val), .y(result));
	
	always @(posedge clk) begin
		
		
		x_t <= {$signed(data - 8'h80) , 8'h0};
		
		sum<=sum + ($signed(data - 8'h80) * $signed(data - 8'h80));
		cnt<=cnt+1'b1;
		if(cnt==32'd4096) begin
			cnt<=32'd0;
			val<=sum * 0.000244141;// 1/4096
			sum<=32'd0;
		end
	end
		
	
	
	
	
	
	
 
	//assign ref = ref_lvl;
 
	sine_rom SINE(
		.addr(addr),
		.data(data)
	);
 
	agc UUT(
		.clk(clk),
		.rst(rst),
		//.x_in(x_in >>> sh),
		.x_in(x_in),
		.a_coef(a_coef),
		.reference(ref),
		.y_out(y_out)
	);
 
 
	initial begin
		clk = 'b0;
		rst = 'b0;
		sh = 'h1;	
		//ref = 'h3fff;
		ref = 'h3fff;
		a_coef = 'h3f;
		#20 rst = 'b1;
 
		#1000000     
		sh = 'h2;	
		#2000000    
		sh = 'h1;	 
		#1000000     
		sh = 'h0;  
		#1000000     
		sh = 'h2;	
		#2500000 
		sh = 'h3;	
		#2500000 
		sh = 'h0;  
		#2500000 
		sh = 'h2;	
		#10000000                                         
		$write("Simulation has finished");
		$finish;
	end
 
	initial begin
		$dumpfile("agc_tb.vcd");
		$dumpvars(0,agc_tb);
	end
 
endmodule
 
 
module sine_rom(
    input   [7:0] addr,
    output  [7:0] data
);
 
reg [7:0] mem [0:255];
 
initial
  $readmemh("sine.txt", mem);
 
assign data = mem[addr]; 
 
endmodule