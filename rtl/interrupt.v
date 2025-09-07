module interrupt(
	input wire clk,
	input wire rst_n,
	input wire int_st_set,
	input wire int_st_clear,
	input wire int_en,
	input wire int_st,
	output wire tim_int
);

//always @(*)begin
//	if(!rst_n)
//		tim_int = 0;
//	else if (!int_en)
//		tim_int = 0;
//	else if (int_st_clear)
//		tim_int = 0;
//	else if (int_st_set)
//		tim_int = 1;
//end
//
assign tim_int = int_st & int_en;
endmodule
