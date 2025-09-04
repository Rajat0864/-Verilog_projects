module top_module( 
  input clk , rst ,
  input w_e , r_e ,  
  output reg buf_empty, buf_full,  
  input [7:0] buf_in ,
  output reg [7:0] buf_out ,
  output reg [7:0] fifo_counter , 
  output reg [7:0] wr_ptr, rd_ptr 
);
  reg [7:0] buf_mem [0:63]; 

  //Flags
  always @ (fifo_counter) begin
    buf_empty = (fifo_counter == 0);
    buf_full = (fifo_counter == 64);
  end

  //FIFO counter
  always @(posedge clk or posedge rst) begin
    if (rst) 
      fifo_counter <= 0;
    else if(w_e && !buf_full)
      fifo_counter <= fifo_counter + 1 ;
    else if (r_e && !buf_empty) 
      fifo_counter <= fifo_counter - 1;
    else 
      fifo_counter <= fifo_counter ;  
  end

  //Memory
  always @(posedge clk) begin
    if (w_e && !buf_full)
      buf_mem[wr_ptr] <= buf_in ;  
    else
      buf_mem[wr_ptr] <= buf_mem[wr_ptr] ;
  end
  always @(posedge clk or posedge rst) begin
    if(rst) 
      buf_out <= 0;  
    else if (r_e && !buf_empty)  
      buf_out <= buf_mem[rd_ptr] ;  
    else
      buf_out <= buf_out; 
  end

//Read and Write pointer
  always @(posedge clk or posedge rst) begin 
  if (rst) begin
    rd_ptr <= 0;
    wr_ptr <= 0;
  end
  else begin
    if (w_e && !buf_full)
      wr_ptr <= (wr_ptr == 63) ? 0 : wr_ptr + 1;
    else
      wr_ptr <= wr_ptr;
    if (r_e && !buf_empty)
      rd_ptr <= (rd_ptr == 63) ? 0 : rd_ptr + 1;
    else
      rd_ptr <= rd_ptr;
  end
end
endmodule
