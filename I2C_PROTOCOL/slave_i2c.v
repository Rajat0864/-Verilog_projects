module i2c_slave(
  input            clk,
  input            reset,
  input            scl_in,
  input            sda_in,
  input      [7:0] MY_ADDR,
  output reg       sda_out,
  output reg       data_valid,
  output reg [7:0] rx_addr,
  output reg [7:0] rx_data
);

parameter [2:0] IDLE      = 3'd0,
                START_DET = 3'd1,
                RCV_ADDR  = 3'd2,
                ACK_1     = 3'd3,
                RCV_DATA  = 3'd4,
                ACK_2     = 3'd5,
                STOP_DET  = 3'd6;

reg [2:0] state;
reg [3:0] bit_cnt;
reg [7:0] addr_shift;
reg [7:0] data_shift;

reg scl_d1, scl_d2;
reg sda_d1, sda_d2;

wire scl_falling = ~scl_d1 &  scl_d2;
wire scl_rising  =  scl_d1 & ~scl_d2;

wire start_cond = scl_d1 &  sda_d2 & ~sda_d1;
wire stop_cond  = scl_d1 & ~sda_d2 &  sda_d1;

always @(posedge clk) begin
  if (reset) begin
    scl_d1 <= 1'b1; scl_d2 <= 1'b1;
    sda_d1 <= 1'b1; sda_d2 <= 1'b1;
  end else begin
    scl_d1 <= scl_in;  scl_d2 <= scl_d1;
    sda_d1 <= sda_in;  sda_d2 <= sda_d1;
  end
end

always @(posedge clk) begin
  if (reset) begin
    state      <= IDLE;
    bit_cnt    <= 4'd7;
    addr_shift <= 8'h00;
    data_shift <= 8'h00;
    rx_addr    <= 8'h00;
    rx_data    <= 8'h00;
    data_valid <= 1'b0;
    sda_out    <= 1'b1;
  end
  else begin
    data_valid <= 1'b0;

    case (state)


      IDLE : begin
        sda_out    <= 1'b1;
        bit_cnt    <= 4'd7;
        addr_shift <= 8'h00;
        data_shift <= 8'h00;
        if (start_cond)
          state <= START_DET;
      end



      START_DET : begin
        sda_out <= 1'b1;
        bit_cnt <= 4'd7;
        if (scl_falling)
          state <= RCV_ADDR;
        else if (stop_cond)
          state <= IDLE;
      end







      RCV_ADDR : begin
        sda_out <= 1'b1;
        if (scl_rising) begin
          addr_shift <= {addr_shift[6:0], sda_d1};
          if (bit_cnt == 4'd0)
            state <= ACK_1;
          else
            bit_cnt <= bit_cnt - 1;
        end
      end




      ACK_1 : begin
        if (addr_shift == MY_ADDR) begin
          sda_out <= 1'b0;
          rx_addr <= addr_shift;
          if (scl_falling) begin
            bit_cnt <= 4'd7;
            state   <= RCV_DATA;
          end
        end else begin
          sda_out <= 1'b1;
          if (scl_falling)
            state <= IDLE;
        end
      end



      RCV_DATA : begin
        sda_out <= 1'b1;
        if (scl_rising) begin
          data_shift <= {data_shift[6:0], sda_d1};
          if (bit_cnt == 4'd0)
            state <= ACK_2;
          else
            bit_cnt <= bit_cnt - 1;
        end
      end




      ACK_2 : begin
        sda_out    <= 1'b0;
        rx_data    <= data_shift;
        data_valid <= 1'b1;
        if (scl_falling)
          state <= STOP_DET;
      end




      STOP_DET : begin
        sda_out <= 1'b1;
        if (stop_cond)
          state <= IDLE;
        else if (start_cond)
          state <= START_DET;
      end

      default : begin
        state   <= IDLE;
        sda_out <= 1'b1;
      end

    endcase
  end
end

endmodule
