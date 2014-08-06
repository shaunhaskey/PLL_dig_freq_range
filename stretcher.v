`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:31:53 08/28/2013 
// Design Name: 
// Module Name:    stretcher 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module stretcher(clk, input_signal, output_signal
    );
input clk;
input input_signal;
output reg output_signal;

parameter [1:0] COUNTING = 2'b11;
parameter [1:0] IDLE = 2'b00;
reg [1:0] state =IDLE;
reg [7:0] count = 0;
	always @(posedge clk) begin
		case (state)
		IDLE: begin
			count<=0;
		   if (input_signal==1) state<=COUNTING;
		   else begin
			state <= IDLE;
			output_signal<=0;
			end
		end
		COUNTING: begin
			output_signal<=1;
			if (count==100) state<=IDLE;
			else begin
			count<= count + 1;
			end
		end
		endcase
	end
endmodule
