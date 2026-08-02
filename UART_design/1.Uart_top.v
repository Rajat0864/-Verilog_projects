`timescale 1ns / 1ps
//====================================================================
// uart_top2
// Wires together: baud_rate_genrator + Uart_T (transmitter, with parity)
//                  + Uart_Rx (receiver, with parity check)
// TX output is looped back into RX input internally (loopback test wiring),
// same pattern as your original uart_top.
//====================================================================
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
    wire tx_clk_en;   // 1x baud tick, drives Uart_T
    wire rx_clk_en;   // 16x baud tick, drives Uart_Rx (now uses real oversampling)
    wire tx_line;     // Uart_T's Tx_out looped into Uart_Rx's data_in

    baud_rate_genrator bg (
        .clock(clk), .reset(reset),
        .enb_tx(tx_clk_en), .enb_rx(rx_clk_en)
    );

    Uart_T tx_inst (
        .reset(reset), .clk(clk), .tx_en(tx_clk_en),
        .tx_start(tx_start), .Data_in(data_in),
        .Tx_out(tx_line), .busy(tx_busy)
    );

    // Uart_Rx now has proper 16x oversampling (sample counter, mid-bit
    // sampling at sample==8), matching the reference uart_reciever design.
    // It is therefore driven by rx_clk_en, the 16x tick - not the 1x tick.
    Uart_Rx rx_inst (
        .clk(clk), .reset(reset), .rx_start(rx_start),
        .clken(rx_clk_en), .data_in(tx_line),
        .rx_out(rx_out), .busy(rx_busy)
    );
endmodule
