
`default_nettype none
 `define USE_PACOBLAZE
module 
picoblaze_template
#(
parameter clk_freq_in_hz = 25000000
) (
				output reg[9:0] led,
        output interrupt_ack,
				input clk,
        input interrupt_event,
				input [7:0] input_data
			     );


  
//--
//------------------------------------------------------------------------------------
//--
//-- Signals used to connect KCPSM3 to program ROM and I/O logic
//--

wire[9:0]  address;
wire[17:0]  instruction;
wire[7:0]  port_id;
wire[7:0]  out_port;
reg[7:0]  in_port;
wire  write_strobe;
wire  read_strobe;
reg  interrupt;
//wire  interrupt_ack;
wire  kcpsm3_reset;

pacoblaze3 led_8seg_kcpsm
(
                  .address(address),
               .instruction(instruction),
                   .port_id(port_id),
              .write_strobe(write_strobe),
                  .out_port(out_port),
               .read_strobe(read_strobe),
                   .in_port(in_port),
                 .interrupt(interrupt),
             .interrupt_ack(interrupt_ack),
                     .reset(kcpsm3_reset),
                       .clk(clk));

 wire [19:0] raw_instruction;
	
	pacoblaze_instruction_memory 
	pacoblaze_instruction_memory_inst(
     	.addr(address),
	    .outdata(raw_instruction)
	);
	
	always @ (posedge clk)
	begin
	      instruction <= raw_instruction[17:0];
	end

    assign kcpsm3_reset = 0;                       
  
//  ----------------------------------------------------------------------------------------------------------------------------------
//  -- Interrupt 
//  ----------------------------------------------------------------------------------------------------------------------------------
//  --
//  --
//  -- Interrupt is used to provide a 1 second time reference.
//  --
//  --
//  -- A simple binary counter is used to divide the 50MHz system clock and provide interrupt pulses.
//  --
reg[26:0] int_count;
reg event_1hz;
always @ (posedge clk)
  begin
      //--divide 50MHz by 50,000,000 to form 1Hz pulses
      if (int_count==(25000000-1)) //clock enable
    begin
         int_count <= 0;
         event_1hz <= 1;
      end else
    begin
         int_count <= int_count + 1;
         event_1hz <= 0;
      end
 end

 always @ (posedge clk or posedge interrupt_ack)  //FF with clock "clk" and reset "interrupt_ack"
 begin
      led[1] <= interrupt;
      if (interrupt_ack) //if we get reset, reset interrupt in order to wait for next clock.
            interrupt <= 0;
      else
    begin 
          if (event_1hz)   //clock enable
                interrupt <= 1;
              else
                interrupt <= interrupt;
      end
 end
/*
 always @ (posedge clk or posedge interrupt_ack)  //FF with clock "clk" and reset "interrupt_ack"
 begin
      led[1] <= interrupt;
      if (interrupt_ack) //if we get reset, reset interrupt in order to wait for next clock.
            interrupt <= 0;
      else
		  begin 
		      if (interrupt_event)   //clock enable
      		      interrupt <= 1;
          else
		            interrupt <= interrupt;
      end
 end
 */
//  --
//  ----------------------------------------------------------------------------------------------------------------------------------
//  -- KCPSM3 input ports 
//  ----------------------------------------------------------------------------------------------------------------------------------
//  --
//  --
//  -- The inputs connect via a pipelined multiplexer
//  --

 always @ (posedge clk)
 begin
    case (port_id[7:0])
        8'h0:    in_port <= input_data;
        default: in_port <= 8'bx;
    endcase
end
   
//
//  --
//  ----------------------------------------------------------------------------------------------------------------------------------
//  -- KCPSM3 output ports 
//  ----------------------------------------------------------------------------------------------------------------------------------
//  --
//  -- adding the output registers to the processor
//  --
//   
  always @ (posedge clk)
  begin

        //LED is port 80 hex 
        if (write_strobe & port_id[7])  //clock enable 
          //led[9:2] <= out_port;
          led[9:2] <= {out_port[0], out_port[1], out_port[2], out_port[3], out_port[4], out_port[5], out_port[6], out_port[7]};
//        -- 8-bit LCD data output address 40 hex.
        if (write_strobe & port_id[6])  //clock enable
          led[0] <= out_port[0];

  end

//  --
//  ----------------------------------------------------------------------------------------------------------------------------------
//  -- LCD interface  
//  ----------------------------------------------------------------------------------------------------------------------------------
//  --
//  -- The LCD will be accessed using the 8-bit mode.  
//  -- lcd_rw is '1' for read and '0' for write 
//  --
//  -- Control of read and write signal


endmodule