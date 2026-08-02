`timescale 1ns / 1ps

module Uart_T (
    input        reset,
    input        clk,
    input        tx_en,
    input        tx_start,
    input  [7:0] Data_in,
    output reg   Tx_out,
    output       busy
);

    reg [7:0] shift_reg;
    reg [7:0] tx_data_reg;
    reg [2:0] bit_count;
    reg [2:0] state;

    parameter IDLE         = 3'b000,
              START        = 3'b001,
              DATA         = 3'b010,
              PARITY_CHECK = 3'b011,
              STOP         = 3'b100;

    assign busy = (state != IDLE);

    always @(posedge clk) begin
        if (reset) begin
            Tx_out      <= 1'b1;
            shift_reg   <= 8'd0;
            tx_data_reg <= 8'd0;
            bit_count   <= 3'd7;
            state       <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    Tx_out <= 1'b1;
                    if (tx_start) begin
                        shift_reg   <= Data_in;
                        tx_data_reg <= Data_in;
                        bit_count   <= 3'd7;
                        state       <= START;
                    end
                end

                START: begin
                    if (tx_en) begin
                        Tx_out <= 1'b0;
                        state  <= DATA;
                    end
                end

                DATA: begin
                    if (tx_en) begin
                        Tx_out    <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        if (bit_count == 3'd0)
                            state <= PARITY_CHECK;
                        else begin
                            bit_count <= bit_count - 1'b1;
                            state <= DATA;
                        end
                    end
                end

                PARITY_CHECK: begin
                    if (tx_en) begin
                        Tx_out <= ^tx_data_reg;
                        state  <= STOP;
                    end
                end

                STOP: begin
                    if (tx_en) begin
                        Tx_out <= 1'b1;
                        state  <= IDLE;
                    end
                end

                default: begin
                    Tx_out <= 1'b1;
                    state  <= IDLE;
                end
            endcase
        end
    end
endmodule
