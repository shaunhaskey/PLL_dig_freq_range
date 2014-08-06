`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:53:43 08/13/2013 
// Design Name: 
// Module Name:    top_level 
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
module top_level(
	input 	     clk,
	input 	     RxD,
	output 	     TxD,
	output [7:0] LEDs,
	input 	     VCO_clock,
	output 	     clock_out,
	output 	     PLL_out,
	input 	     rst_button,
	input 	     trigger_button,
	input 	     change_phase_button,
	input 	     trigger_pin,
	input 	     change_phase_pin,
	output			PLL_out2,
	output			change_phase_out,
	output [3:0]		PLL_cap,
	input camera_monitor_in,
	output camera_monitor_out
);

   //wire       armed;
   //wire       on_off;
   wire        clock_100kHz;
   //wire        clock_12_5MHz;

   //wire [31:0] active_registers;
   wire        change_phase_debounced;
   //wire [1:0]  controller_state;
   //wire [4:0]  phase_setting;
   wire        PLL_stretch_input;
//This debounces the change phase switch
   debouncer deb(.clk(clk), .PB(change_phase_button),
   .PB_state(change_phase_debounced), .PB_down(), .PB_up());

   clock_divider clock_divider1(.clk(clk), .clock_out(clock_100kHz),
   .clock_out2());

   stretcher stretch_PLL(.clk(clk), .input_signal(PLL_stretch_input),
   .output_signal(PLL_out2));

   stretcher stretch_monitor(.clk(clk),
   .input_signal(camera_monitor_in),
   .output_signal(camera_monitor_out));
	
   serialGPIO serial_part(.clk(clk), .RxD(RxD), .TxD(TxD),
			  .clock_reduced(clock_100kHz),
			  .trigger_button(trigger_button),
			  .change_phase_button(change_phase_debounced),
			  .rst_button(rst_button),
			  .VCO_clock(VCO_clock),
			  .clock_out(clock_out), .PLL_out(PLL_out),
			  .PLL_out2(PLL_stretch_input), .LEDs(LEDs),
			  .trigger_pin(trigger_pin),
			  .change_phase_pin(change_phase_pin),
			  .change_phase_out(change_phase_out), .PLL_cap(PLL_cap));

   // phase_controller cont(.trigger_button(trigger_button),
   // 	.change_phase_button(change_phase_debounced),
   // 	.rst_button(rst_button),
   // 	.clk(clock_100kHz),.armed(armed),.active_registers(active_registers),
   // 	.phase_out(phase_setting), .output_on(on_off), .LEDs(LEDs),
   // 	.trigger_pin(trigger_pin),
   // 	.change_phase_pin(change_phase_pin),.controller_state(controller_state), .change_phase_out(change_phase_out));


   // pll pll_one(.VCO_clock(VCO_clock), .clock_out(clock_out),
   // .PLL_out(PLL_out), .SW(phase_setting), .on_off(on_off),
   // .armed(armed), .PLL_out2(PLL_stretch_input));

	 
//memory mem(.data_out(data_out), .address(address), .data_in(data_in), .write_enable(write_enable), .clk(clk), .phase_setting(phase_setting), .phase_address(phase_address), .on_off(on_off),.current_mode(current_mode));

endmodule
