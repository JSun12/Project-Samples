module rising_edge_detect (async_sig, clk, rising_edge);
	input async_sig, clk;
	output rising_edge;

	reg async_sig_d1;
	initial async_sig_d1 = 1'b0;
	reg async_sig_d2;
	initial async_sig_d2 = 1'b0;

	always @(posedge clk) begin
			async_sig_d1 <= async_sig;
	end

	always @(posedge clk) begin
			async_sig_d2 <= async_sig_d1;
	end

	assign rising_edge = async_sig & (~async_sig_d2);
endmodule