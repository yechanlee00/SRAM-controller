module sync_sram_ctrl #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16
)(
  input wire clk,
  input wire rst_n,
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [DATA_WIDTH-1:0] data_in,
  output wire [DATA_WIDTH-1:0] data_out,
  input wire rd_req,
  input wire wr_req,
  output reg ready,

  output reg [ADDR_WIDTH-1:0] sram_addr,
  output reg [DATA_WIDTH-1:0] sram_data_out,
  input 
