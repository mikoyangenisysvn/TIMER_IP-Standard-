module counter_64
(
	input clk,
	input rst_n,
	input timer_en,
	input div_en,
	input [3:0] div_val,
	output wire [63:0] cnt
);
reg r_cnt;
reg [7:0] div_cnt;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		r_cnt <= 64'd0;
		div_cnt <= 8'd0;end
	else if (timer_en) begin
		if (!div_en)
			r_cnt <= r_cnt + 1;
		else if (div_cnt == (1 << div_val) - 1) begin
			div_cnt <= 0;
			r_cnt <= r_cnt + 1;end
			else
				div_cnt <= div_cnt + 1;
		end
	end
	assign cnt = r_cnt;
endmodule

//timescale 1ns/1ps
module apb
(
	input wire PCLK,
	input wire PRESETn,
	input wire PSEL,
	input wire PENABLE,
	input wire PWRITE,
	input wire [11:0] PADDR,
	input wire [31:0] PWDATA,
	output reg [31:0] PRDATA,
	output reg PREADY,

	output reg wr_en,
	output reg rd_en,
	output reg [11:0] addr,
	output reg [31:0] wdata,
	input wire [31:0] rdata
);

always @(posedge PCLK or negedge PRESETn) begin
	if(!PRESETn) begin
		wr_en <= 0;
		rd_en <= 0;
		addr <= 12'd0;
		wdata <= 32'd0;
		PRDATA <= 32'd0;
		PREADY <= 0;end
	else begin
		wr_en <= 0;
		rd_en <= 0;
		PREADY <= 0;

		if(PSEL && PENABLE) begin
			addr <= PADDR;
			wdata <= PWDATA;
			if(PWRITE) begin
				wr_en <= 1;
			end else begin
				rd_en <= 1;
				PRDATA <= rdata;
			end
			PREADY <= 1;
		end
	end
end
endmodule


module register
(
	input clk,
	input rst_n,
	input reg_wr_en,
	input reg_rd_en,
	input [11:0] reg_addr,
	input [31:0] reg_wdata,
	output [31:0] reg_rdata,
	input [63:0] cnt,
	input int_set,
	input int_clr,
	output timer_en,
	output div_en,
	output [3:0] div_val,
	output int_en,
	output [63:0] compare_val,
	output int_st
);

reg [31:0] TCR, TIER, TISR;
reg [31:0] TCMP0, TCMP1;

reg [31:0] reg_rdata_internal;

wire [31:0] TDR0 = cnt[31:0];
wire [31:0] TDR1 = cnt [63:32];
wire [31:0] THCSR = 32'h0;

assign timer_en = TCR[0];
assign div_en = TCR[1];
assign div_val = TCR[11:8];
assign int_en = TIER[0];
assign int_st = TISR[0];
assign compare_val = {TCMP1, TCMP0};

always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		TCR <= 32'h00000100;
		TIER <= 32'h0;
		TCMP0 <= 32'h0;
		TCMP1 <= 32'h0; end
	else if (reg_wr_en) begin
		case (reg_addr)
			12'h000:begin
				TCR[0] <= reg_wdata[0];
				TCR[1] <= reg_wdata[1];
				if(reg_wdata[11:8] <= 4'd8)
				TCR[11:8] <= reg_wdata[11:8];
				end
				12'h00C: TCMP0 <= reg_wdata;
				12'h010: TCMP1 <= reg_wdata;
				12'h014: TIER <= reg_wdata;
			endcase
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if(!rst_n)
			TISR[0] <= 1'b0;
		else begin
			if(reg_wr_en && reg_addr == 12'h018 && reg_wdata[0])
				TISR[0] <= 1'b0;
			else if (int_set)
				TISR[0] <= 1'b1;
			else if (int_clr)
				TISR[0] <= 1'b0;
		end
	end
	always @(*) begin
		case (reg_addr)
			12'h000: reg_rdata_internal = TCR;
			12'h004: reg_rdata_internal = TDR0;
			12'h008: reg_rdata_internal = TDR1;
			12'h00C: reg_rdata_internal = TCMP0;
			12'h010: reg_rdata_internal = TCMP1;
			12'h014: reg_rdata_internal = TIER;
			12'h018: reg_rdata_internal = TISR;
			12'h01C: reg_rdata_internal = THCSR;
			default: reg_rdata_internal = 32'h0;
		endcase
	end
	//wire [31:0] reg_rdata_wire;
	assign reg_rdata_wire = reg_rdata_internal;
	endmodule

module interrupt
(
	input clk,
	input rst_n,
	input [63:0] cnt,
	input [63:0] compare_val,
	input int_en,
	input int_clr_reg,
	output tim_int,
	output reg int_set,
	output reg int_clr
);

	reg tim_int_r;
	assign tim_int = tim_int_r;

always @(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		tim_int_r <= 0;
		int_set <= 0 ;
		int_clr <= 0 ;end
	else begin
		if (int_en && (cnt == compare_val)) begin
			tim_int_r <= 1;
			int_set <= 1;end
		else begin
			int_set <= 0;end
		
		if (int_clr_reg) begin
			tim_int_r <= 0 ;
			int_clr <= 1;end
		else begin
			int_clr <= 0;end
		end
	end
	endmodule

module IP_TIMER
(
	input sys_clk,
	input sys_rst_n,
	input tim_psel,
	input tim_pwrite,
	input tim_penable,
	input [11:0] tim_paddr,
	input [31:0] tim_pwdata,
	output [31:0] tim_prdata,
	output tim_pready,
	output tim_pslverr,
	output tim_int
);
	wire reg_wr_en, reg_rd_en;
	wire [11:0] reg_addr;
	wire [31:0] reg_wdata;
	wire [31:0] reg_rdata;

	wire timer_en, div_en, int_en;
	wire [31:0] div_val;
	wire [63:0] compare_val;
	wire int_st_set,int_st_clr;
	wire [63:0] cnt;

	apb U0 (
		.PCLK (sys_clk),
		.PRESETn (sys_rst_n),
		.PSEL (time_psel),
		.PENABLE (tim_penable),
		.PWRITE (tim_pwrite),
		.PADDR (tim_paddr),
		.PWDATA (tim_pwdata),
		.PRDATA (tim_prdata),
		.PREADY (tim_pready),

		.wr_en (reg_wr_en),
		.rd_en (reg_rd_en),
		.addr (reg_addr),
		.wdata (reg_wdata),
		.rdata (reg_rdata)
	);
	register U1 (
		.clk (sys_clk),
		.rst_n (sys_rst_n),
		.reg_wr_en (reg_wr_en),
		.reg_rd_en (reg_rd_en),
		.reg_addr (reg_addr),
		.reg_wdata (reg_wdata),
		.reg_rdata (reg_rdata_wire),
		.cnt (cnt),
		.int_set (int_st_set),
		.int_clr (int_st_clr),
		.timer_en (timer_en),
		.div_en (div_en),
		.div_val (div_val),
		.int_en (int_en),
		.compare_val(compare_val)
	//	.int_st ()
	);
	
	counter_64 U2(
		.clk (sys_clk),
		.rst_n (sys_rst_n),
		.timer_en (timer_en),
		.div_en (div_en),
		.div_val (div_val),
		.cnt (cnt)
	);

	interrupt U3(
		.clk (sys_clk),
		.rst_n (sys_rst_n),
		.cnt (cnt),
		.compare_val (compare_val),
		.int_en (int_en),
		.int_clr_reg (int_st_clr),
		.tim_int (tim_int),
		.int_set (int_st_set),
		.int_clr (int_st_clr)
	);
	endmodule



