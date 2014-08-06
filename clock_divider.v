`timescale 1ns / 1ps
module clock_divider(clk, clock_out, clock_out2);
   input clk;
   output clock_out, clock_out2;
   reg [9:0] clock_count = 0;

   always @(posedge clk) begin
      if (clock_count==511) clock_count <= 0;
      else clock_count <= clock_count + 1;
   end

   assign clock_out = clock_count[8];
   assign clock_out2 = clock_count[2];
endmodule
