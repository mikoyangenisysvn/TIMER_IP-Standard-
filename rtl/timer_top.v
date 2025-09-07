module timer_top(
	input wire sys_clk,
	input wire sys_rst_n,
	input wire tim_psel,
	input wire tim_pwrite,
	input wire tim_penable,
	input wire [11:0]tim_paddr,
	input wire [31:0]tim_pwdata,

	input wire [3:0] tim_pstrb,
	input wire dbg_mode,

	output wire [31:0] tim_prdata,
	output wire tim_pready,
	output wire tim_pslverr,
	output wire tim_int

);

wire wr_en, rd_en;
wire [63:0] cnt_value;
wire div_en, timer_en;
wire [3:0] div_val;
wire cnt_en;
wire [31:0] tdr0, tdr1;
wire [31:0] tcmp0, tcmp1;
wire int_st,int_en,int_st_set,int_st_clear;

wire [11:0] reg_addr;// = tim_paddr;
wire [31:0] reg_wdata;// = tim_pwdata;

assign tim_pslverr = 1'b0;

assign reg_addr = tim_paddr;
assign reg_wdata = tim_pwdata;



apb U0 (
	.clk(sys_clk),
//	.rst_n(sys_rst_n),
	.psel(tim_psel),
	.pwrite(tim_pwrite),
	.penable(tim_penable),
//	.paddr(tim_paddr),
//	.pwdata(tim_pwdata),
	.pready(tim_pready),
	.wr_en(wr_en),
	.rd_en(rd_en)
);


register U1 (
	.clk(sys_clk),
	.rst_n(sys_rst_n),
	.addr (tim_paddr),
	.wdata (tim_pwdata),
	.wr_en(wr_en),
	.rd_en(rd_en),
	.rdata(tim_prdata),
	.cnt_value(cnt_value),
	.div_en(div_en),
	.div_val(div_val),
	.timer_en(timer_en),
	.TDR0(tdr0),
	.TDR1(tdr1),
	.TCMP0(tcmp0),
	.TCMP1(tcmp1),
	.int_st(int_st),
	.int_en(int_en),
	.int_st_set(int_st_set),
	.int_st_clear(int_st_clear)
);

control_counter U2 (
	.clk(sys_clk),
	.rst_n(sys_rst_n),
	.div_en(div_en),
	.div_val(div_val),
	.timer_en(timer_en),
	.cnt_en(cnt_en)
);

counter U3 (
	.clk(sys_clk),
	.rst_n(sys_rst_n),
	.cnt_en(cnt_en),
	.wr_en(wr_en),
	.addr(reg_addr),
	.wdata(reg_wdata),
	.timer_en(timer_en),
	.cnt_value(cnt_value)
);

interrupt U4 (
	.clk(sys_clk),
	.rst_n(sys_rst_n),
	.int_st_set(int_st_set),
	.int_st_clear(int_st_clear),
	.int_en(int_en),
	.int_st(int_st),
	.tim_int(tim_int)
);


endmodule


