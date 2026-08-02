`timescale 1ns / 1ps

module uart_top2(
    input        clk,
    input        reset,
    input        tx_start,
    input  [7:0] data_in,
    input        rx_start,
    output       tx_busy,
    output       rx_busy,
    output [7:0] rx_out
);

    wire tx_clk_en;
    wire rx_clk_en;
    wire tx_line;

    baud_rate_genrator bg (
        .clock(clk), .reset(reset),
        .enb_tx(tx_clk_en), .enb_rx(rx_clk_en)
    );

    Uart_T tx_inst (
        .reset(reset), .clk(clk), .tx_en(tx_clk_en),
        .tx_start(tx_start), .Data_in(data_in),
        .Tx_out(tx_line), .busy(tx_busy)
    );

    Uart_Rx rx_inst (
        .clk(clk), .reset(reset), .rx_start(rx_start),
        .clken(rx_clk_en), .data_in(tx_line),
        .rx_out(rx_out), .busy(rx_busy)
    );
endmodule
