`timescale 1ns / 1ps
module phase_controller(
	input 	     trigger_button,
	input 	     change_phase_button,
	input 	     rst_button,
	input 	     clk,
	input 	     armed,
	input [31:0] active_registers,
	output [4:0] phase_out,
	output 	     output_on,
	output [7:0] LEDs,
	input 	     trigger_pin,
	input 	     change_phase_pin,
	output [1:0] controller_state,	     
	output change_phase_out
    );


parameter [1:0] PRE_IDLE = 2'b11;
parameter [1:0] IDLE = 2'b00;
parameter [1:0] FIND_PHASE = 2'b01;
parameter [1:0] ON = 2'b10;
reg [1:0] state = PRE_IDLE;
reg [5:0] index = 6'b000000;
reg [4:0] phase_output_reg = 0;
reg on_off = 0;
reg [31:0] pre_idle_count;
//always_ff @(posedge clk or posedge reset or posedge change_phase or posedge trigger) begin
//always @(posedge clk, rst, change_phase, trigger) begin
//
reg change_phase_old_button = 0;
reg change_phase_old_pin = 0;
//always @(posedge change_phase) begin
//	change_phase_old = 1;
//end

//always_comb @(posedge trigger, posedge change_phase, posedge rst) begin
always @(posedge clk) begin
	case (state)
		PRE_IDLE: begin
		   on_off<=0;
		   if (pre_idle_count>=500000) begin 
		      pre_idle_count <= 0;
		      state <= IDLE;
		   end
		   else pre_idle_count <= pre_idle_count + 1;
		end
		IDLE: begin
			index <= 0;
			on_off <= 0;
			if (((trigger_button==1) || (trigger_pin==1)) && armed) state <= FIND_PHASE;
			else state <= IDLE;
		end
		FIND_PHASE: begin
			if ((rst_button==1) || (armed==0)) state <= PRE_IDLE;
			else if (index >= 32) state <= PRE_IDLE;
			else if (active_registers[index]==1) state <= ON;
			else index <= index + 1;
		end
		ON: begin
			phase_output_reg <= index[4:0];
			on_off <= 1;
			if ((rst_button==1) || (armed==0)) state <= PRE_IDLE;
			else if (((change_phase_button==1) && (change_phase_old_button==0)) || ((change_phase_pin==1) && (change_phase_old_pin==0))) begin
				index <= index + 1;
				state <= FIND_PHASE;
			end else state <= ON;
		end
	endcase
	change_phase_old_button <= change_phase_button;
   change_phase_old_pin <= change_phase_pin;
end

assign output_on = on_off;
assign phase_out = phase_output_reg;
assign LEDs[5:0] = index;
assign LEDs[7:6] = state;
assign controller_state = state;
assign change_phase_out = change_phase_pin;
endmodule
