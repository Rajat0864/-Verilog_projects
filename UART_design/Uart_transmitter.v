module uart_tx #(
    parameter CLK_FREQ  = 10_000_000,  // 10 MHz default
    parameter BAUD_RATE = 115200        // 115200 baud default
)(
    input            clk,        // FPGA clock
    input            rst,        // Active high reset
    input      [7:0] data,       // 8-bit parallel data
    input            tx_start,   // Pulse HIGH to start
    output reg       tx_out,     // Serial output line
    output           tx_done     // HIGH when idle/done
);

// ─────────────────────────────────────────
// Local Parameters
// ─────────────────────────────────────────
localparam BIT_TIME      = CLK_FREQ / BAUD_RATE;  // 434 cycles @ 50MHz/115200
localparam COUNTER_WIDTH = $clog2(BIT_TIME);       // 9 bits for 434

// State encoding
localparam IDLE      = 2'b00;
localparam START_BIT = 2'b01;
localparam DATA_BITS = 2'b10;
localparam STOP_BIT  = 2'b11;

// ─────────────────────────────────────────
// Internal Registers
// ─────────────────────────────────────────
reg [1:0]               state     = IDLE;
reg [COUNTER_WIDTH-1:0] counter   = 0;
reg [7:0]               shift_reg = 0;
reg [2:0]               bit_cnt   = 0;  // counts 0 to 7

// ─────────────────────────────────────────
// Edge Detection for tx_start
// ─────────────────────────────────────────
reg tx_start_prev = 0;

always @(posedge clk or posedge rst) begin
    if (rst) tx_start_prev <= 0;
    else     tx_start_prev <= tx_start;
end

wire tx_start_pulse = tx_start & ~tx_start_prev;  // 1-cycle pulse on rising edge

// ─────────────────────────────────────────
// Main FSM
// ─────────────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        state     <= IDLE;
        tx_out    <= 1;       // idle line is HIGH
        counter   <= 0;
        bit_cnt   <= 0;
        shift_reg <= 0;
    end else begin
        case (state)

            // ── IDLE ──────────────────────────────
            IDLE: begin
                tx_out  <= 1;          // keep line HIGH
                counter <= 0;
                bit_cnt <= 0;
                if (tx_start_pulse) begin
                    shift_reg <= data; // latch data
                    state     <= START_BIT;
                end
            end

            // ── START BIT ─────────────────────────
            START_BIT: begin
                tx_out <= 0;           // pull line LOW
                if (counter == BIT_TIME - 1) begin
                    counter <= 0;
                    state   <= DATA_BITS;
                end else begin
                    counter <= counter + 1;
                end
            end

            // ── DATA BITS (LSB first) ─────────────
            DATA_BITS: begin
                tx_out <= shift_reg[bit_cnt];   // send current bit
                if (counter == BIT_TIME - 1) begin
                    counter <= 0;
                    if (bit_cnt == 7) begin
                        state <= STOP_BIT;      // all 8 bits sent
                    end else begin
                        bit_cnt <= bit_cnt + 1; // next bit
                    end
                end else begin
                    counter <= counter + 1;
                end
            end

            // ── STOP BIT ──────────────────────────
            STOP_BIT: begin
                tx_out <= 1;           // pull line HIGH
                if (counter == BIT_TIME - 1) begin
                    counter <= 0;
                    state   <= IDLE;
                end else begin
                    counter <= counter + 1;
                end
            end

            // ── DEFAULT (safety net) ───────────────
            default: begin
                state   <= IDLE;
                tx_out  <= 1;
                counter <= 0;
                bit_cnt <= 0;
            end

        endcase
    end
end

assign tx_done = (state == IDLE);

endmodule
