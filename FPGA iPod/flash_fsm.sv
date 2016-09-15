module flash_fsm (clk, pause, play_forward, sync_clk_edge, read, read_address, audio_data)
input clk, pause, play_forward, sync_clk_edge;
output reg read;
output reg [22:0] read_address;
output reg [7:0] audio_data;

parameter [4:0] ASSERT      = 5'b00001;
parameter [4:0] READ        = 5'b00010;
parameter [4:0] PLAY_LOWER  = 5'b00100;
parameter [4:0] PLAY_UPPER  = 5'b01000;
parameter [4:0] UPDATE_ADDR = 5'b10000;

parameter [22:0] max_address = 23'b00001111111111111111111;
parameter [22:0] min_address = 23'b0;

reg read;
reg [4:0] state;
reg [22:0] address_counter;
initial address_counter = 23'b0;
reg [31:0] song_data;
reg [31:0] count;

// assert address and read signal at clock cycle
// waitrequest -> wait for readdatavalid
// While waiting, address, read, write, and byteenable can't change
// look at readdata
always_ff @(posedge clk or posedge pause) begin
  if (pause)
    state <= ASSERT;
  else begin
  case(state)
    ASSERT:      begin
                  read <= 1'b1;
                  read_address <= address_counter;
                 if (pause || flash_mem_waitrequest) 
                  state <= ASSERT;
                 else
                  state <= READ;
                 end
    READ:        begin
                 if (flash_mem_readdatavalid) begin
                   song_data <= flash_mem_readdata;
                   read <= 1'b0;
                   state <= PLAY_LOWER;
                 end
                 else
                   state <= READ;
                 end
    PLAY_LOWER:  begin
                 if (sync_clk_edge) begin
                   audio_data <= song_data[15:8];
                   state <= PLAY_UPPER;
                 end
                 else
                   state <= PLAY_LOWER;
                 end
    PLAY_UPPER:  begin
                 if (sync_clk_edge) begin
                   audio_data <= song_data[31:24];
                   state <= UPDATE_ADDR;
                 end
                 else
                   state <= PLAY_UPPER;
                 end
    UPDATE_ADDR: begin
                 state <= ASSERT;
                 if (play_forward == 1'b1) begin
                   if (address_counter < max_address)
                     address_counter <= address_counter + 1;
                   else if (address_counter >= max_address)
                     address_counter <= min_address;
                 end
                 else if (play_forward == 1'b0) begin
                   if (address_counter > min_address)
                     address_counter <= address_counter - 1;
                   else if (address_counter == min_address)
                     address_counter <= max_address;
                 end
                 else
                   address_counter <= min_address;
                 end
    default:  state <= ASSERT;
  endcase
  end
end
