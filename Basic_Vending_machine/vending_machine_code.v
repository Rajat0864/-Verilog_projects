module top_module(
  input clk , 
  input [1:0] in, // 00 = 0rs , 01 = 5rs , 10 = 10rs
  input reset ,
  output reg [1:0] Return_change,
  output reg product_dispatched
);
  parameter S1 = 0, S2 = 1, S3 = 2;
  reg [1:0] state, next_state;

  always @(*) begin
    Return_change = 0;
    product_dispatched = 0;
    next_state = state; // Prevent latch

    case (state)
      S1: begin
        if (in == 2'b00)
          next_state = S1;
        else if (in == 2'b01)
          next_state = S2;
        else if (in == 2'b10)
          next_state = S3;
        else
          next_state = S1;
      end

      S2: begin
        if (in == 2'b00) begin
          next_state = S1;
          Return_change = 2'b01;
        end else if (in == 2'b01) begin
          next_state = S3;
        end else if (in == 2'b10) begin
          next_state = S1;
          product_dispatched = 1;
        end else begin
          next_state = S1;
        end
      end

      S3: begin
        if (in == 2'b00) begin
          next_state = S1;
          Return_change = 2'b10;
        end else if (in == 2'b01) begin
          next_state = S3;
          product_dispatched = 1;
        end else if (in == 2'b10) begin
          next_state = S1;
          product_dispatched = 1;
        end else begin
          next_state = S1;
        end
      end
    endcase
  end

  always @ (posedge clk) begin
    if (reset) begin
      state <= S1;
    end else begin
      state <= next_state;
    end
  end
endmodule
