module apb(
	input wire clk,
//	input wire rst_n,
	input wire psel,
	input wire pwrite,
	input wire penable,
//	input wire [11:0] paddr,
//	input wire [31:0] pwdata,
	output wire pready,
	output wire wr_en,
	output wire rd_en
);

//assign pready = penable;
assign pready = 1;

//always @(*) begin
assign	wr_en = (psel & penable & pwrite);
assign	rd_en = (psel & penable & !pwrite);
//end



/*
reg reg_of_pready;
always @(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		wr_en <= 0;
		rd_en <= 0;
		reg_of_pready <= 0;end
	else begin
		if(psel && penable) begin
		reg_of_pready <= 1;
		wr_en <= pwrite;
		rd_en <= !pwrite;end
		else begin
			reg_of_pready <= 0;
			wr_en <= 0;
			rd_en <= 0;end
		end
	end
	assign pready = reg_of_pready;*/

  /*     reg penable_d;
       always @(posedge clk or negedge rst_n) begin
	       if(!rst_n)begin
		       penable_d <= 1'b0;end
		else begin
			penable_d <= penable;
		end
	end
	assign pready = wr_en | rd_en;

	always @* begin
		if (!rst_n) begin
			wr_en = 1'b0;
			rd_en = 1'b0;end
		else begin
			if(penable_d && psel && penable) begin
				if(pwrite) begin
					wr_en = 1'b1;
					rd_en = 1'b0;end
				else begin
					wr_en = 1'b0;
					rd_en = 1'b1;
				end
			end
			else begin
				wr_en = 1'b0;
				rd_en = 1'b1;end
			end
			end
*/
endmodule



