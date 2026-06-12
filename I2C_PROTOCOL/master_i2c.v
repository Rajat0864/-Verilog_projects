module iic_controller (
    input  wire        clk,        
    input  wire        rst,
    input  wire        start,      
    input  wire [6:0]  slave_addr,
    input  wire [7:0]  data,
    inout  wire        sda,
    output reg         scl,
    output reg         busy,
    output reg         done,
    output reg         ack_error
);
    localparam DIVIDER = 250; 
    reg [15:0] clk_cnt;
    reg        scl_en;     
    reg        scl_clk;    
    localparam IDLE            = 4'd0;
    localparam START_COND      = 4'd1;
    localparam SEND_ADDR       = 4'd2;
    localparam ADDR_ACK        = 4'd3;
    localparam SEND_DATA       = 4'd4;
    localparam DATA_ACK        = 4'd5;
    localparam STOP_COND       = 4'd6;
    localparam DONE_ST         = 4'd7;
    reg [3:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_cnt;
    reg       sda_drive;
    reg       sda_out;
    reg [1:0] phase;
    assign sda = sda_drive ? sda_out : 1'bz;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 16'd0;
            phase   <= 2'd0;
            scl     <= 1'b1;
        end else if (state == IDLE && !start) begin
            clk_cnt <= 16'd0;
            phase   <= 2'd0;
            scl     <= 1'b1;
        end else begin
            if (clk_cnt == DIVIDER - 1) begin
                clk_cnt <= 16'd0;
                phase   <= phase + 1'b1;
                if (phase == 2'd1) scl <= 1'b1;
                if (phase == 2'd3) scl <= 1'b0;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end
    end
    wire phase_tick = (clk_cnt == DIVIDER - 1);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            sda_drive  <= 1'b1;
            sda_out    <= 1'b1;
            shift_reg  <= 8'd0;
            bit_cnt    <= 4'd0;
            busy       <= 1'b0;
            done       <= 1'b0;
            ack_error  <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    sda_drive <= 1'b1;
                    sda_out   <= 1'b1; 
                    busy      <= 1'b0;
                    if (start) begin
                        busy      <= 1'b1;
                        ack_error <= 1'b0;
                        shift_reg <= {slave_addr, 1'b0}; 
                        bit_cnt   <= 4'd7;
                        state     <= START_COND;
                    end
                end
                START_COND: begin
                    sda_drive <= 1'b1;
                    sda_out   <= 1'b1;
                    if (phase_tick && phase == 2'd1) begin
                        sda_out <= 1'b0; 
                    end
                    if (phase_tick && phase == 2'd3) begin
                        state <= SEND_ADDR;
                    end
                end
                SEND_ADDR: begin
                    sda_drive <= 1'b1;
                    if (phase_tick && phase == 2'd0) begin
                        sda_out <= shift_reg[bit_cnt];
                    end
                    if (phase_tick && phase == 2'd3) begin
                        if (bit_cnt == 0) begin
                            state <= ADDR_ACK;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
                ADDR_ACK: begin
                    if (phase_tick && phase == 2'd0) sda_drive <= 1'b0;
                    if (phase_tick && phase == 2'd2) begin
                        ack_error <= sda; 
                    end
                    if (phase_tick && phase == 2'd3) begin
                        shift_reg <= data;
                        bit_cnt   <= 4'd7;
                        state     <= SEND_DATA;
                    end
                end
                SEND_DATA: begin
                    if (phase_tick && phase == 2'd0) begin
                        sda_drive <= 1'b1;
                        sda_out   <= shift_reg[bit_cnt];
                    end
                    if (phase_tick && phase == 2'd3) begin
                        if (bit_cnt == 0) begin
                            state <= DATA_ACK;
                        end else begin
                            bit_cnt <= bit_cnt - 1'b1;
                        end
                    end
                end
                DATA_ACK: begin
                    if (phase_tick && phase == 2'd0) sda_drive <= 1'b0;
                    if (phase_tick && phase == 2'd2) begin
                        ack_error <= sda;
                    end
                    if (phase_tick && phase == 2'd3) begin
                        state <= STOP_COND;
                    end
                end
                STOP_COND: begin
                    if (phase_tick && phase == 2'd0) begin
                        sda_drive <= 1'b1;
                        sda_out   <= 1'b0;
                    end
                    if (phase_tick && phase == 2'd1) begin
                        sda_out <= 1'b0; 
                    end
                    if (phase_tick && phase == 2'd2) begin
                        sda_out <= 1'b1; 
                    end
                    if (phase_tick && phase == 2'd3) begin
                        state <= DONE_ST;
                    end
                end
                DONE_ST: begin
                    sda_drive <= 1'b1;
                    sda_out   <= 1'b1;
                    busy      <= 1'b0;
                    done      <= 1'b1;
                    state     <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
