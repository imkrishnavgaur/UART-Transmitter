/*
PROJECT:     UART Transmitter in SystemVerilog
AUTHOR:      Krishnav Gaur

DESCRIPTION: This is a simple UART Transmitter implementation on
             a 100MHz internal clock FPGA using SystemVerilog.
		     The user has an option to choose from 5 baud rates.
			 
			 Any Controller would have to set the baud mode and
			 the parity mode first, then the data can be set in 
			 tx_data after 10*clk_val for that baud rate.
			 The controller would also have to ensure that the
			 data and mode inputs are not driven during the
			 transmission of the data.
			 
			 An additional project idea could be the design and
			 implementation of a controller that would drive the
			 inputs of this UART Transmitter.					 
*/
module uart_tx (
  clk,
  reset_n,
  baude_mode,     // used to set the baud rate for transmission
  parity_mode,    // used to transmit the parity bit when enabled
  tx_start,       // needs to be set to start the transmission
  tx_data,        // load data. data sent serially LSB first
  tx_line,
  tx_done
  );

input logic        clk;
input logic        reset_n;
input logic  [2:0] baude_mode;
input logic        parity_mode;
input logic        tx_start;
input logic  [7:0] tx_data;
output logic       tx_line;
output logic       tx_done;
logic              tx_line_next;
logic              tx_done_next;

typedef enum logic [2:0] {
  IDLE       = 3'd0,
  START      = 3'd1,
  DATA       = 3'd2,
  ADD_PARITY = 3'd3,
  STOP       = 3'd4,
  CLEANUP    = 3'd5
} uart_tx_states;

uart_tx_states current_state;
uart_tx_states next_state;

typedef enum logic [13:0] {
  BAUD_9600   = 14'd10417,
  BAUD_19200  = 14'd5208,
  BAUD_38400  = 14'd2604,
  BAUD_115200 = 14'd868,
  BAUD_921600 = 14'd109
} baud_rate;

baud_rate clk_val;
baud_rate clk_val_next;

logic [13:0] clk_cnt;
logic [13:0] clk_cnt_next;
logic [2:0]  bit_idx;
logic [2:0]  bit_idx_next;
logic [7:0]  tx_buf;
logic [7:0]  tx_buf_next;
logic        parity_bit;

assign parity_bit = ^tx_buf;  // reduction xor - creates an even parity

always_comb begin:BAUD_RATE_LOGIC
  clk_val_next = clk_val;
  case(baude_mode)
    3'd0: clk_val_next = BAUD_9600;
	3'd1: clk_val_next = BAUD_19200;
	3'd2: clk_val_next = BAUD_38400;
	3'd3: clk_val_next = BAUD_115200;
	3'd4: clk_val_next = BAUD_921600;
	default: clk_val_next = BAUD_115200;
  endcase
end

always_ff @(posedge clk or negedge reset_n) begin: BAUD_RATE_UPDATER
  if(!reset_n)
    clk_val <= BAUD_115200;
  else
    clk_val <= clk_val_next;
end

always_comb begin:FSM_COMB_LOGIC
  tx_line_next = tx_line;
  tx_done_next = tx_done;
  tx_buf_next  = tx_buf;
  clk_cnt_next = clk_cnt;
  bit_idx_next = bit_idx;
  next_state   = current_state;

  case (current_state)
    
	IDLE:begin
	  tx_line_next = 1'b1;
	  tx_done_next = 1'b0;
	  clk_cnt_next = 0;
	  bit_idx_next = 3'b000;
	  if (tx_start) begin
	    tx_buf_next = tx_data;
		next_state  = START;
	  end
	end
	
	START:begin
	  tx_line_next = 1'b0;
	  if (clk_cnt < clk_val - 1)
	    clk_cnt_next = clk_cnt + 1;
	  else begin
	    clk_cnt_next = 0;
		next_state   = DATA;
	  end
	end

	DATA:begin
	  tx_line_next = tx_buf[bit_idx];
      if (clk_cnt < clk_val - 1)
        clk_cnt_next = clk_cnt + 1;
      else begin
	    clk_cnt_next = 0;
		if (bit_idx < 7)
		  bit_idx_next = bit_idx + 3'b001;
		else begin
		  bit_idx_next = 3'b000;
		  if (parity_mode)
		    next_state = ADD_PARITY;
	      else
		    next_state = STOP;
		end
	end

    ADD_PARITY:begin
	  tx_line_next = parity_bit;
	  if (clk_cnt < clk_val - 1)
	    clk_cnt_next = clk_cnt + 1;
      else begin
	    clk_cnt_next = 0;
		next_state   = STOP;
	  end
	end

	STOP:begin
	  tx_line_next = 1'b1;
	  if (clk_cnt < clk_val - 1)
	    clk_cnt_next = clk_cnt + 1;
      else begin
        clk_cnt_next = 0;
        tx_done_next = 1'b1;
        next_state   = CLEANUP;
      end
    end

    CLEANUP:begin
      tx_done_next = 1'b0;
	  next_state   = IDLE;
	end
	
	default: next_state = IDLE;
	
  endcase
end

always_ff @(posedge clk or negedge reset_n) begin:STATE_AND_LOGIC_UPDATER
  if (!reset_n) begin
    clk_cnt       <= 0;
	tx_line       <= 1'b1;
	tx_done       <= 1'b0;
	tx_buf        <= 8'b0000_0000;
	bit_idx       <= 3'b000;
	current_state <= IDLE;
  end else begin
    clk_cnt       <= clk_cnt_next;
	tx_line       <= tx_line_next;
	tx_done       <= tx_done_next;
	tx_buf        <= tx_buf_next;
	bit_idx       <= bit_idx_next;
	current_state <= next_state;
  end
end

endmodule
