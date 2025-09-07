module register(
	input wire clk,
	input wire rst_n,
	input wire [11:0] addr,
	input wire [31:0] wdata,
	input wire wr_en,
	input wire rd_en,
	output reg [31:0] rdata,
	input wire [63:0] cnt_value,
	output reg div_en,
	output reg timer_en,
	output reg [3:0] div_val,
	output reg [31:0] TDR0,
	output reg [31:0] TDR1,
	output reg [31:0] TCMP0,
	output reg [31:0] TCMP1,
	output reg int_st,
	output reg int_en,
	output wire int_st_set,
	output wire int_st_clear
);

parameter TCR_ADDR = 12'h000;
parameter TDR0_ADDR = 12'h004;
parameter TDR1_ADDR = 12'h008;
parameter TCMP0_ADDR = 12'h00C;
parameter TCMP1_ADDR = 12'h010;
parameter TIER_ADDR = 12'h014;
parameter TISR_ADDR = 12'h018;

parameter THCSR_ADDR = 12'h01C;

reg halt_req;

assign int_st_set = ({TDR1, TDR0} == {TCMP1, TCMP0});
assign int_st_clear = (addr == TISR_ADDR && wr_en && wdata[0]);

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		div_en <= 0;
		timer_en <= 0;
		div_val <= 4'd1;
		TDR0 = 32'd0;
		TDR1 = 32'd0;
		TCMP0 <= 32'hFFFF_FFFF;
		TCMP1 <= 32'hFFFF_FFFF;
		int_en <= 0;
		int_st <= 0;
       		halt_req <= 0;	end
	else begin
		if(wr_en) begin
			case(addr)
				TCR_ADDR: begin
//					if(timer_en && (div_en != wdata[1] || div_val != wdata [11:8])) ;
//					else begin
						timer_en <= wdata[0];
						div_en <= wdata[1];
						if (wdata [11:8] <= 4'd8) div_val <= wdata [11:8];
						else div_val <= div_val; end
//					end
				//	div_val <= wdata [11:8]; end
			//	TDR0_ADDR: TDR0 <= wdata;
				TDR1_ADDR: TDR1 = wdata;
				TCMP0_ADDR: TCMP0 <= wdata;
				TCMP1_ADDR: TCMP1 <= wdata;
				TIER_ADDR: int_en <= wdata[0];
//				TISR_ADDR: begin
//					if (wdata[0])
//						int_st <= 1'b0; end
				THCSR_ADDR: halt_req <= wdata[0];
				default:;
				endcase
			end
//			if(int_st_set)
//				int_st <= 1;
				int_st <= (int_st) ? (int_st_clear) ? 0 : int_st  : int_st_set;
		end
	end
	
	always @(*) begin
		if(!rst_n) begin
			TDR0 = 32'd0;
			TDR1 = 32'd0; end
		else begin
			TDR0 = cnt_value[31:0];
			TDR1 = cnt_value[63:32];end
		end

	always @(*) begin
		if(rd_en) begin
			case(addr)
				TCR_ADDR: rdata = {20'b0,div_val,6'b0,div_en,timer_en};
				TDR0_ADDR: rdata = TDR0;
				TDR1_ADDR: rdata = TDR1;
				TCMP0_ADDR: rdata = TCMP0;
				TCMP1_ADDR: rdata = TCMP1;
				TIER_ADDR: rdata = {31'b0, int_en};
				TISR_ADDR: rdata = {31'b0,int_st};
				THCSR_ADDR: rdata = {30'b0,1'b0, halt_req};
				default: rdata = 32'b0;
			endcase
		end
		else begin
			rdata = 32'b0;
		end
	end
	endmodule



