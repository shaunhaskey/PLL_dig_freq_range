`timescale 1ns / 1ps
module pll(VCO_clock, clock_out, PLL_out, SW, on_off, armed, PLL_out2);
	input VCO_clock, armed;
	input [4:0] SW;
	output clock_out, PLL_out, PLL_out2;
   reg [4:0] clock_count;
	reg PLL_status;
	input [7:0] on_off;
	initial begin
		clock_count = 0;
		PLL_status = 0;
	end

   always @(posedge VCO_clock) begin
		if ((on_off==1) && (armed==1)) begin
			if (clock_count==5'b11111)
				clock_count <= 5'b00000;
			else clock_count <= clock_count + 1;
			if (clock_count==SW)
				PLL_status <=1'b1;
			else PLL_status <= 1'b0;
		end else begin
			clock_count <= 0;
			PLL_status <= 0;
		end
	end

	assign clock_out = clock_count[4];
	assign PLL_out = PLL_status;
	assign PLL_out2 = PLL_status;
endmodule

