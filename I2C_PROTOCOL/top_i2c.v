module i2c_top (

  input        clk,
  input        reset,


  input        start,
  input  [7:0] ADDR,
  input  [7:0] data_in,
  input  [7:0] MY_ADDR,


  output       scl_bus,
  output       sda_bus,


  output       data_valid,
  output [7:0] rx_addr,
  output [7:0] rx_data
);


  wire sda_master;
  wire sda_slave;


  assign sda_bus = sda_master & sda_slave;


  i2c_master u_master (
    .clk     (clk),
    .reset   (reset),
    .start   (start),
    .ADDR    (ADDR),
    .data_in (data_in),
    .scl_clk (scl_bus),
    .sda_out (sda_master)
  );


  i2c_slave u_slave (
    .clk        (clk),
    .reset      (reset),
    .scl_in     (scl_bus),
    .sda_in     (sda_bus),
    .MY_ADDR    (MY_ADDR),
    .sda_out    (sda_slave),
    .data_valid (data_valid),
    .rx_addr    (rx_addr),
    .rx_data    (rx_data)
  );

endmodule
