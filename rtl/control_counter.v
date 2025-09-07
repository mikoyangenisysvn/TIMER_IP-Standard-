module control_counter(
	input wire clk,
	input wire rst_n,
	input wire div_en,
	input wire [3:0] div_val,
	input wire timer_en,
	output wire cnt_en
);

reg [8:0] int_cnt;
wire [8:0] div_factor;

//reg reg_of_cnt_en;
//assign cnt_en = reg_of_cnt_en;

assign div_factor = (div_val == 4'd0) ? 9'd1 :
		    (div_val == 4'd1) ? 9'd2 :
		    (div_val == 4'd2) ? 9'd4 :
		    (div_val == 4'd3) ? 9'd8 :
		    (div_val == 4'd4) ? 9'd16:
		    (div_val == 4'd5) ? 9'd32:
		    (div_val == 4'd6) ? 9'd64:
		    (div_val == 4'd7) ? 9'd128:
		    (div_val == 4'd8) ? 9'd256: 9'd1;
//assign cnt_en = (timer_en && (!div_en || (int_cnt == div_factor - 1)));

assign cnt_en = timer_en ?  div_en ?  (int_cnt == div_factor - 1)  : 1 : 0;

always @(posedge clk or negedge rst_n) begin
/*	if(!rst_n || !timer_en || !div_en || (int_cnt == div_factor - 1))
		int_cnt <= 0;
	else if (div_en && timer_en)
		int_cnt <= int_cnt + 1;
end*/
	if(!rst_n) begin
		int_cnt <= 9'd0;

		end
	else if(!timer_en || !div_en || (int_cnt == div_factor - 1)) begin
		int_cnt <= 9'd0;end
	else begin
		int_cnt <= int_cnt + 1;end
	end

/*	if(!rst_n) begin
	 	int_cnt <= 9'd0;
 	 	reg_of_cnt_en <= 1'b0;end
	 else if (!timer_en || !div_en) begin
		int_cnt <= 9'd0;
		reg_of_cnt_en <= timer_en;end
	else begin
		if (int_cnt == div_factor - 1) begin
			int_cnt <= 9'd0;
			reg_of_cnt_en <= 1'b1;end
		else begin
			int_cnt <= int_cnt + 1;
			reg_of_cnt_en <= 1'b0;end
		end
	end
	 */

endmodule



