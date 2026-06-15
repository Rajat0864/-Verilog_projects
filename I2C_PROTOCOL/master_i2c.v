module i2c_master(
  input        clk,
  input        reset,
  input        start,
  input  [7:0] ADDR,
  input  [7:0] data_in,
  output reg   scl_clk,
  output reg   sda_out
);

parameter [2:0] IDLE    = 3'd0,
                START   = 3'd1,
                LD_ADDR = 3'd2,
                ACK_1   = 3'd3,
                DATA    = 3'd4,
                ACK_2   = 3'd5,
                STOP    = 3'd6;

reg [2:0] state;
reg [2:0] bit_cnt;
reg [1:0] phase;

reg [1:0] clk_div;
reg       tick;

always @(posedge clk) begin
  if (reset) begin
    clk_div <= 2'd0;
    tick    <= 1'b0;
  end else begin
    clk_div <= clk_div + 1;
    tick    <= (clk_div == 2'd3);
  end
end

always @(posedge clk) begin
  if (reset)
    scl_clk <= 1'b1;
  else if (tick) begin
    case (state)
      IDLE    : scl_clk <= 1'b1;
      START   : scl_clk <= 1'b1;
      LD_ADDR : scl_clk <= ~scl_clk;
      ACK_1   : scl_clk <= ~scl_clk;
      DATA    : scl_clk <= ~scl_clk;
      ACK_2   : scl_clk <= ~scl_clk;
      STOP    : scl_clk <= (phase == 2'd2) ? 1'b0 : 1'b1;
      default : scl_clk <= 1'b1;
    endcase
  end
end

always @(posedge clk) begin
  if (reset) begin
    state   <= IDLE;
    sda_out <= 1'b1;
    bit_cnt <= 3'd7;
    phase   <= 2'd0;
  end
  else if (tick) begin
    case (state)


      IDLE : begin
        sda_out <= 1'b1;
        bit_cnt <= 3'd7;
        if (start) begin
          phase <= 2'd2;
          state <= START;
        end
      end






      START : begin
        case (phase)
          2'd2 : begin sda_out <= 1'b1; phase <= 2'd1; end
          2'd1 : begin sda_out <= 1'b0; phase <= 2'd0; end
          2'd0 : begin
            sda_out <= 1'b0;
            bit_cnt <= 3'd7;
            state   <= LD_ADDR;
          end
          default : state <= IDLE;
        endcase
      end


      LD_ADDR : begin
        if (scl_clk == 1'b1) begin

          sda_out <= ADDR[bit_cnt];
        end else begin

          if (bit_cnt == 3'd0) begin




            state <= ACK_1;
          end else begin
            bit_cnt <= bit_cnt - 1;
          end
        end
      end




      ACK_1 : begin
        if (scl_clk == 1'b1) begin

          sda_out <= data_in[7];
          bit_cnt <= 3'd7;
          state   <= DATA;
        end else begin

          sda_out <= 1'b1;
        end
      end


      DATA : begin
        if (scl_clk == 1'b1) begin

          sda_out <= data_in[bit_cnt];
        end else begin

          if (bit_cnt == 3'd0) begin




            state <= ACK_2;
          end else begin
            bit_cnt <= bit_cnt - 1;
          end
        end
      end


      ACK_2 : begin
        if (scl_clk == 1'b1) begin

          sda_out <= 1'b0;
          phase   <= 2'd2;
          state   <= STOP;
        end else begin

          sda_out <= 1'b1;
        end
      end






      STOP : begin
        case (phase)
          2'd2 : begin sda_out <= 1'b0; phase <= 2'd1; end
          2'd1 : begin sda_out <= 1'b0; phase <= 2'd0; end
          2'd0 : begin sda_out <= 1'b1; state <= IDLE;  end
          default : state <= IDLE;
        endcase
      end

      default : begin
        state   <= IDLE;
        sda_out <= 1'b1;
      end

    endcase
  end
end

endmodule
