module counter
(

	input wire clk,
	input wire rst_n,
	input wire cnt_en,
	input wire timer_en,
	input wire [11:0] addr,
	input wire [31:0]wdata,
	input wire wr_en,
	output reg [63:0] cnt_value
);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		cnt_value <= 64'd0;
	end
	else if (wr_en && (addr == 12'h4 || addr == 12'h8)) begin
		case(/*{20'd0,addr}*/addr)
			12'h004: cnt_value[31:0] <= wdata;
			12'h008: cnt_value[63:32] <= wdata;
			default: ;
		endcase 
	end
	else if (cnt_en && timer_en) begin
		cnt_value <= cnt_value + 1;
	end
end
endmodule

