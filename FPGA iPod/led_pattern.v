module led_pattern (
	clk, 	//frequency that the led pattern will change at
	led	//the led's that you want to change 
	);
  parameter jump_per_cycle = 7;   //# of led jumps in each direction

	input clk;
	inout [9:0] led;

  reg [9:0] led;
  initial led = 10'b0000000001;
	
	reg left_or_right;		//direction for the led to travel (0 for left, 1 for right)
  reg [2:0] count;

  //counts up or reset count
  always @(posedge clk) begin
    if(count >= jump_per_cycle - 1)
      count <= 3'b0;
    else
      count <= count + 1;
  end

  //flip direction whenever count resets
  always @(posedge clk) begin
    if(count >= jump_per_cycle - 1)
      left_or_right <= ~left_or_right;
    else
      left_or_right <= left_or_right;
  end

  //perform left or right shift depending on the direction
	always @(posedge clk) begin
  		if(left_or_right == 1'b0)
    		led <= (led << 1);
  		else if(left_or_right == 1'b1)
  			led <= (led >> 1);
  		else 			//this should never happen if system is working properly
  			led <= led;
	end
endmodule