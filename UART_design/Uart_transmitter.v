module uart_tx #(
    parameter CLK_FREQ  = 50_000_000,  // 50 MHz default
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
parameter  IDLE = 2'b00, START_BIT = 2'b01, DATA_BITS = 2'b10, STOP_BIT  = 2'b11;

// ─────────────────────────────────────────
// Internal Registers
// ─────────────────────────────────────────
reg [1:0]               state , next_state;
reg [COUNTER_WIDTH-1:0] counter   = 0;
reg [7:0]               shift_reg = 0;
reg [2:0]               bit_cnt   = 0;  // counts 0 to 7

// ─────────────────────────────────────────
// Control Signals (FSM → Datapath)
// ─────────────────────────────────────────
reg load_data;
reg clr_counter;
reg inc_counter;
reg clr_bit_cnt;
reg inc_bit_cnt;
reg set_tx_high;
reg set_tx_low;
reg tx_from_shift;

// ─────────────────────────────────────────
// Status Signals (Datapath → FSM)
// ─────────────────────────────────────────
wire bit_time_done = (counter == BIT_TIME - 1);
wire last_bit      = (bit_cnt == 7);

// ─────────────────────────────────────────
// Datapath
// ─────────────────────────────────────────
always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter   <= 0;
        bit_cnt   <= 0;
        shift_reg <= 0;
        tx_out    <= 1;       // idle line is HIGH
    end else begin
        if      (clr_counter) counter <= 0;
        else if (inc_counter) counter <= counter + 1;

        if      (clr_bit_cnt) bit_cnt <= 0;
        else if (inc_bit_cnt) bit_cnt <= bit_cnt + 1;

        if (load_data) shift_reg <= data;

        if      (set_tx_high)   tx_out <= 1;
        else if (set_tx_low)    tx_out <= 0;
        else if (tx_from_shift) tx_out <= shift_reg[bit_cnt];
    end
end

// ─────────────────────────────────────────
// Main FSM
// ─────────────────────────────────────────
always @ ( posedge clk or posedge rst) begin
if ( rst) begin
state <= IDLE ;
end
else begin
state <= next_state;
end
end
always @(*) begin
    if (rst) begin
        state <= IDLE;
    end else begin
        case (state)
            IDLE:      if (tx_start) state <= START_BIT;
            START_BIT: if (bit_time_done)  state <= DATA_BITS;
            DATA_BITS: if (bit_time_done && last_bit) state <= STOP_BIT;
            STOP_BIT:  if (bit_time_done)  state <= IDLE;
            default: state <= IDLE;
        endcase
    end
end

// ─────────────────────────────────────────
// Control Signal Generation (combinational)
// ─────────────────────────────────────────
always @(*) begin
    // defaults
    load_data     = 0;
    clr_counter   = 0;
    inc_counter   = 0;
    clr_bit_cnt   = 0;
    inc_bit_cnt   = 0;
    set_tx_high   = 0;
    set_tx_low    = 0;
    tx_from_shift = 0;

    case (state)

        // ── IDLE ──────────────────────────────
        IDLE: begin
            set_tx_high = 1;          // keep line HIGH
            clr_counter = 1;
            clr_bit_cnt = 1;
            if (tx_start) load_data = 1; // latch data
        end

        // ── START BIT ─────────────────────────
        START_BIT: begin
            set_tx_low = 1;           // pull line LOW
            if (bit_time_done) clr_counter = 1;
            else               inc_counter = 1;
        end

        // ── DATA BITS (LSB first) ─────────────
        DATA_BITS: begin
            tx_from_shift = 1;        // send current bit
            if (bit_time_done) begin
                clr_counter = 1;
                if (!last_bit) inc_bit_cnt = 1; // next bit
            end else begin
                inc_counter = 1;
            end
        end

        // ── STOP BIT ──────────────────────────
        STOP_BIT: begin
            set_tx_high = 1;          // pull line HIGH
            if (bit_time_done) begin
                clr_counter = 1;
                clr_bit_cnt = 1;      // reset bit counter before returning to IDLE
            end else begin
                inc_counter = 1;
            end
        end

        // ── DEFAULT (safety net) ───────────────
        default: begin
            set_tx_high = 1;
            clr_counter = 1;
            clr_bit_cnt = 1;
        end

    endcase
end

// ─────────────────────────────────────────
// tx_done - HIGH when idle
// ─────────────────────────────────────────
assign tx_done = (state == IDLE);

endmodule
