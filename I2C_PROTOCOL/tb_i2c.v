`timescale 1ns/1ps

module tb_i2c_top;


  reg        clk;
  reg        reset;
  reg        start;
  reg  [7:0] ADDR;
  reg  [7:0] data_in;
  reg  [7:0] MY_ADDR;


  wire       scl_bus;
  wire       sda_bus;
  wire       data_valid;
  wire [7:0] rx_addr;
  wire [7:0] rx_data;


  i2c_top dut (
    .clk        (clk),
    .reset      (reset),
    .start      (start),
    .ADDR       (ADDR),
    .data_in    (data_in),
    .MY_ADDR    (MY_ADDR),
    .scl_bus    (scl_bus),
    .sda_bus    (sda_bus),
    .data_valid (data_valid),
    .rx_addr    (rx_addr),
    .rx_data    (rx_data)
  );


  initial clk = 0;
  always  #5 clk = ~clk;


  reg captured_valid;
  always @(posedge clk) begin
    if (reset)
      captured_valid <= 1'b0;
    else if (data_valid)
      captured_valid <= 1'b1;
  end


  initial begin
    $dumpfile("i2c_top.vcd");
    $dumpvars(0, tb_i2c_top);
  end


  initial begin
    $monitor("T=%0t  scl=%b sda=%b  M_st=%0d S_st=%0d  rx_addr=%h rx_data=%h  valid=%b",
             $time,
             scl_bus, sda_bus,
             dut.u_master.state,
             dut.u_slave.state,
             rx_addr, rx_data, data_valid);
  end


  initial begin

    reset = 1; start = 0;
    ADDR = 8'h00; data_in = 8'h00; MY_ADDR = 8'hA5;
    #80;
    reset = 0;
    #40;


    captured_valid = 0;
    ADDR = 8'hA5; data_in = 8'h3C;
    start = 1; #50; start = 0;
    #5000;
    $display("T1: rx_addr=%h  rx_data=%h  captured_valid=%b  (expect A5 3C 1)",
             rx_addr, rx_data, captured_valid);


    captured_valid = 0;
    ADDR = 8'h72; data_in = 8'hFF;
    start = 1; #50; start = 0;
    #5000;
    $display("T2: rx_addr=%h  rx_data=%h  captured_valid=%b  (expect no change, valid=0)",
             rx_addr, rx_data, captured_valid);


    captured_valid = 0;
    ADDR = 8'hA5; data_in = 8'h55;
    start = 1; #50; start = 0;
    #5000;
    $display("T3: rx_addr=%h  rx_data=%h  captured_valid=%b  (expect A5 55 1)",
             rx_addr, rx_data, captured_valid);

    $finish;
  end

endmodule
