module clk_div32 (
  clk_50,    // default clock frequency
  div_factor,    // division factor
  clk_out    // divided clock frequency
);
  input clk_50;
  input [31:0] div_factor;
  output reg clk_out;

  reg [31:0] count;

  //counts up or reset count when div_factor reached
  always @(posedge clk_50) begin
    if(count >= div_factor - 1)
      count <= 32'b0;
    else
      count <= count + 1;
  end

  //flip clock whenever count resets
  always @(posedge clk_50) begin
    if(count >= div_factor - 1)
      clk_out <= ~clk_out;
    else
      clk_out <= clk_out;
  end
endmodule