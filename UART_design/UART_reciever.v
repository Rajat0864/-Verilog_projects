`timescale 1ns / 1ps

module Uart_Rx (
    input            clk, reset, rx_start,
    input            clken,
    input            data_in,
    output reg [7:0] rx_out,
    output           busy
);

    parameter IDLE       = 3'b000,
              START      = 3'b001,
              DATA       = 3'b010,
              Parity_chk = 3'b011,
              STOP       = 3'b100;

    reg [2:0] state;
    reg [3:0] sample;
    reg [3:0] bit_index;
    reg [7:0] shift_rx;
    reg       parity_bit;

    always @(posedge clk) begin
        if (reset) begin
            state      <= IDLE;
            sample     <= 4'd0;
            bit_index  <= 4'd0;
            shift_rx   <= 8'd0;
            rx_out     <= 8'd0;
            parity_bit <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (rx_start) begin
                        state  <= START;
                        sample <= 4'd0;
                    end
                end

                START: begin
                    if (clken) begin
                        if (!data_in || sample != 4'd0)
                            sample <= sample + 4'd1;
                        if (sample == 4'd15) begin
                            state     <= DATA;
                            sample    <= 4'd0;
                            bit_index <= 4'd0;
                            shift_rx  <= 8'd0;
                        end
                    end
                end

                DATA: begin
                    if (clken) begin
                        sample <= sample + 4'd1;
                        if (sample == 4'h8) begin
                            shift_rx  <= {data_in, shift_rx[7:1]};
                            bit_index <= bit_index + 4'd1;
                        end
                        if (bit_index == 4'd8 && sample == 4'd15) begin
                            state  <= Parity_chk;
                            sample <= 4'd0;
                            rx_out <= shift_rx;
                        end
                    end
                end

                Parity_chk: begin
                    if (clken) begin
                        sample <= sample + 4'd1;
                        if (sample == 4'h8)
                            parity_bit <= data_in;
                        if (sample == 4'd15) begin
                            state  <= (parity_bit == ^shift_rx) ? STOP : START;
                            sample <= 4'd0;
                        end
                    end
                end

                STOP: begin
                    if (clken) begin
                        sample <= sample + 4'd1;
                        if (sample == 4'd15) begin
                            state <= IDLE;
                            if (data_in)
                                $display("Next-data");
                            else
                                $display("retransmit the data");
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

    assign busy = (state != IDLE);
endmodule
