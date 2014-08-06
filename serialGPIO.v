`timescale 1ns / 1ps

module serialGPIO(clk, RxD, TxD, clock_reduced, trigger_button, change_phase_button, rst_button, VCO_clock, clock_out, PLL_out, PLL_out2, LEDs, trigger_pin, change_phase_pin, change_phase_out, PLL_cap);
   //clocks
   input clk, clock_reduced;

   //LEDs
   output [7:0] LEDs;

   //input signals and buttons
   input 	trigger_button, change_phase_button, rst_button, change_phase_pin, trigger_pin, VCO_clock;

   //output signals
   output 	change_phase_out, clock_out, PLL_out, PLL_out2;

   //Cap selector for the PLL
   output reg [3:0] PLL_cap;
   
   //RS232
   input 	RxD;
   output 	TxD;
   wire 	 RxD_data_ready;
   wire [7:0] 	 RxD_data;
   reg 		 TxD_data_ready;
   reg [7:0] 	 GPout;  // general purpose outputs
   wire 	 TxD_busy;
   
   reg 		 armed = 0;
   parameter max_address = 50;
   reg [7:0] 	 active_phase_list[0:max_address+10];
   reg [31:0] 	 n_phases;
   reg [31:0]	 address = 0;

   //Input signal buffers to make the synchronous
   reg 		 VCO_buffer;
   reg 		 clock_reduced_buffer;
   reg [0:0] change_phase_pin_buffer;
   reg [0:0] remote_trigger;
   //reg [0:0] change_phase_pin_reg;
   reg trigger_pin_buffer;

   //State codes
   parameter [1:0] IDLE = 2'b00;
   parameter [1:0] PRE_IDLE = 2'b11;
   parameter [1:0] PLL_CAP = 2'b01;
   parameter [1:0] WRITE_DATA = 2'b10;
   parameter [1:0] READ_DATA = 2'b11;
   parameter [1:0] ON = 2'b10;

   //state machine setup
   reg [1:0] 	 state_io = IDLE;
   reg [1:0] 	 state = IDLE;
   reg [2:0] 	 tmp_set = 5;
   reg 	     on_off = 0;
   reg change_phase_old_button = 0;
   reg change_phase_old_pin = 0;
   reg [4:0] phase_output_reg = 0;
   reg [31:0] pre_idle_count;
   reg [31:0]  phase_index;
   reg [4:0]   VCO_clock_count;
   //reg 	       PLL_status;

   //communication codes
   parameter [7:0] return_status_code = 63;
   parameter [7:0] disarm_code = 64;
   parameter [7:0] arm_code = 65;
   parameter [7:0] write_to_memory_code = 66;
   parameter [7:0] read_from_memory_code = 67;
   parameter [7:0] finish_data_to_memory = 68;
   parameter [7:0] PLL_cap_update_code = 69;
   parameter [7:0] remote_trigger_code = 70;
   parameter [7:0] reset_code = 255;
   
   async_receiver RX(.clk(clk), .RxD(RxD), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
   async_transmitter TX(.clk(clk), .TxD(TxD), .TxD_start(TxD_data_ready), .TxD_data(GPout), .TxD_busy(TxD_busy));

   //Understanding the data that is read in from the serial port
   always @(posedge clk) begin
      case (state_io)
	IDLE: begin
	   if(RxD_data_ready) begin 
	      if (RxD_data==reset_code) begin 
		 state_io <= IDLE;
		 GPout <= RxD_data;
	      end else if (RxD_data==disarm_code) begin
		 armed <=0;
		 state_io <= IDLE;
		 GPout <= RxD_data;
	      end else if (RxD_data==arm_code) begin
		 armed<=1;
		 state_io <= IDLE;
		 GPout <= RxD_data;
	      end else if (RxD_data==return_status_code) begin
		 GPout <= state;
		 state_io <= IDLE;
	      end else if (RxD_data==write_to_memory_code) begin
		 GPout <= RxD_data;
		 state_io <= WRITE_DATA;
		 tmp_set <= 5;
		 address <= 0;
	      end else if (RxD_data==read_from_memory_code) begin
		 GPout <= RxD_data;
		 state_io <= READ_DATA;
		 address <= 0;
	      end else if (RxD_data==PLL_cap_update_code) begin
		 GPout <= RxD_data;
		 state_io <= PLL_CAP;
		 address <= 0;
	      end else if (RxD_data==remote_trigger_code) begin
		 GPout <= RxD_data;
		 remote_trigger<=1;
		 state_io <= IDLE;
	      end else begin
		 GPout <= RxD_data;
		 state_io <= IDLE;
	      end
	      TxD_data_ready <= 1;
	   end else begin 
	      state_io <= IDLE;
	      TxD_data_ready <= 0;
	      remote_trigger<=0;

	   end // else: !if(RxD_data_ready)
	end // case: IDLE
	PLL_CAP: begin
	   if(RxD_data_ready) begin 
	      if (RxD_data==reset_code) begin
		 state_io <= IDLE;
		 GPout <= RxD_data;
	      end else begin 
		 state_io <= IDLE;
		 PLL_cap <= RxD_data[3:0];
		 GPout <= RxD_data;
		 TxD_data_ready <= 1;
	      end
	   end else begin
	      TxD_data_ready <= 0;
	      state_io <= PLL_CAP;
	   end // else: !if(RxD_data_ready)
	end // case: PLL_CAP
	WRITE_DATA: begin
	   if(RxD_data_ready) begin 
	      if (RxD_data==reset_code) begin
		 state_io <= IDLE;
		 GPout <= RxD_data;
	      end else if (RxD_data==finish_data_to_memory) begin
		 state_io <= IDLE;
		 GPout <= RxD_data;
		 n_phases <= address - 1;
	      end else begin 
		 state_io <= WRITE_DATA;
		 active_phase_list[address]<=RxD_data;
		 GPout <= RxD_data;
		 address <= address + 1;
	      end
	      TxD_data_ready <= 1;
	   end else begin
	      TxD_data_ready <= 0;
	      state_io <= WRITE_DATA;
	   end // else: !if(RxD_data_ready)
	end // case: WRITE_DATA
	READ_DATA: begin
	   if (tmp_set!=0) begin
	      tmp_set <= tmp_set-1;
	      state_io <= READ_DATA;
	      TxD_data_ready<=0;
	      state_io <= READ_DATA;
	   end else if (TxD_busy) begin
	      TxD_data_ready<=0;
	      state_io <= READ_DATA;
	      tmp_set <= 0;
	   end else if (address==n_phases+1) begin
	      //GPout <= active_phase_list[address];
	      state_io <= IDLE;
	      address <= 0;
	      TxD_data_ready <= 0;
	      tmp_set <= 0;
	   end else begin
	      GPout <= active_phase_list[address];
	      TxD_data_ready <= 1;
	      state_io <= READ_DATA;
	      address <= address + 1;
	      tmp_set <= 5;
	   end // else: !if(address==31)
	end // case: READ_DATA
	endcase // case (state_io)
   end // always @ (posedge clk)

   reg [0:0] change_phase_pin_buffer1 = 0;
   reg [0:0] trigger_pin_buffer1 = 0;
   reg [0:0] VCO_pin_buffer1 = 0;
   reg [0:0] clock_reduced_buffer1 = 0;

   ////////////////////////////////////////////
   ////////// Buffer change_phase_pin and VCO /////////
   always @(posedge clk) begin
      //VCO_buffer<=VCO_clock;
      if (change_phase_pin) begin
	 change_phase_pin_buffer1 <= 1;
      end else begin
	 change_phase_pin_buffer1 <= 0;
      end
      if (trigger_pin) begin
	 trigger_pin_buffer1 <=1;
      end else begin
	 trigger_pin_buffer1 <= 0;
      end
      if (VCO_clock) begin
	 VCO_pin_buffer1 <= 1;
      end else begin
	 VCO_pin_buffer1 <= 0;
      end

      if (clock_reduced) begin
	 clock_reduced_buffer1 <= 1;
      end else begin
	 clock_reduced_buffer1 <= 0;
      end
      
   end

   always @(posedge clk) begin
      //VCO_buffer<=VCO_clock;
      if (change_phase_pin_buffer1) begin
	 change_phase_pin_buffer<=1;
      end else begin
	 change_phase_pin_buffer<=0;
      end
      if (trigger_pin_buffer1) begin
	 trigger_pin_buffer<=1;
      end else begin
	 trigger_pin_buffer<=0;
      end
      if (VCO_pin_buffer1) begin
	 VCO_buffer <= 1;
      end else begin
	 VCO_buffer <= 0;
      end
      if (clock_reduced_buffer1) begin
	 clock_reduced_buffer <= 1;
      end else begin
	 clock_reduced_buffer <= 0;
      end
   end

   
   reg [7:0] change_phase_counter=0;
   parameter [1:0] LOW = 2'b00;
   parameter [1:0] HIGH = 2'b11;
   reg [1:0] 	 state_change_phase = LOW;
   reg [0:0] 	 change_phase_tick = 0;
   parameter n_cycles_change_phase = 50;
   always @(posedge clk) begin
      case (state_change_phase)
	LOW: begin
	   if (change_phase_counter==n_cycles_change_phase) begin
	      change_phase_tick <= 1;
	      change_phase_counter<=0;
	      state_change_phase<=HIGH;
	   end else if (change_phase_pin_buffer) begin
	      change_phase_counter<= change_phase_counter + 1;
	      change_phase_tick <= 0;
	   end else begin
	      change_phase_counter <= 0;
	      change_phase_tick <= 0;
	   end
	end
	HIGH: begin
	   change_phase_tick <= 0;
	   if (change_phase_counter==n_cycles_change_phase) begin
	      change_phase_counter<=0;
	      state_change_phase <= LOW;
	   end else if (change_phase_pin_buffer==0) begin
	      change_phase_counter<= change_phase_counter + 1;
	   end else begin
	      change_phase_counter <= 0;
	   end
	end // case: HIGH
      endcase // case (state_change_phase)
   end // always @ (posedge clk)
   

   ////////////////////////////////////////////
   ////////// change phase logic /////////////
   //always @(posedge clock_reduced_buffer) begin
   always @(posedge clk) begin
      case (state)
	PRE_IDLE: begin
	   on_off<=0;
	   //if (pre_idle_count==50000) begin 
	   if (pre_idle_count==50000000) begin 
	      pre_idle_count <= 0;
	      state <= IDLE;
	   end
	   else pre_idle_count <= pre_idle_count + 1;
	end
	IDLE: begin
	   phase_index <= 0;
	   on_off <= 0;
	   if ((trigger_button || trigger_pin_buffer || remote_trigger) && armed) begin
	      state <= ON;
	      phase_output_reg <= active_phase_list[phase_index];
	   end else begin 
	      state <= IDLE;
	   end
	end
	ON: begin
	   phase_output_reg <= active_phase_list[phase_index];
	   on_off <= 1;
	   if ((rst_button==1) || (armed==0)) begin
	      state <= PRE_IDLE;
	   //end else if (((change_phase_button==1) && (change_phase_old_button==0)) || ((change_phase_pin_buffer==1) && (change_phase_old_pin==0))) begin
	   end else if (((change_phase_button==1) && (change_phase_old_button==0)) || (change_phase_tick)) begin
	      phase_index <= phase_index + 1;
	      if (phase_index == (n_phases)) state <= PRE_IDLE;
	   end else state <= ON;
	end
      endcase
      change_phase_old_button <= change_phase_button;
      change_phase_old_pin <= change_phase_pin_buffer;
   end

   ////////////////////////////////////////////
   ////////// VCO counter /////////////////////
   always @(posedge VCO_buffer) VCO_clock_count <= VCO_clock_count + 1;
   
   
   // always @(posedge VCO_buffer) begin
   //    if ((on_off==1) && (armed==1)) begin
   // 	 if (VCO_clock_count==5'b11111) begin
   // 	   VCO_clock_count <= 0;
   // 	 //end else if (VCO_buffer) begin
   // 	 end else begin
   // 	   VCO_clock_count <= VCO_clock_count + 1;
   // 	 end
   // 	 //end else begin VCO_clock_count <= 0; end
   //    end else begin
   // 	 VCO_clock_count <= 0;
   //    end
   // end // always @ (VCO_buffer)

   assign PLL_out = ((VCO_clock_count==phase_output_reg) && (on_off) && (armed)) ? 1 : 0;
   assign PLL_out2 = ((VCO_clock_count==phase_output_reg) && (on_off) && (armed)) ? 1 : 0;
   //assign PLL_out2 = change_phase_pin;
   ////((VCO_clock_count==phase_output_reg) && (on_off) && (armed)) ? 1 : 0;
   //assign PLL_out2 = (VCO_clock_count==phase_output_reg) ? 1 : 0;
   //assign change_phase_pin_reg = change_phase_pin;
   assign clock_out = VCO_clock_count[4];
   //assign change_phase_out = change_phase_tick;
   //assign change_phase_out = clock_reduced_buffer;
   assign change_phase_out = change_phase_pin_buffer;
   assign LEDs[4:0] = (on_off && armed) ? phase_output_reg[4:0] : 0;
   assign LEDs[7:6] = state;
endmodule
