`timescale 1ns/1ps
module test_bench;
	reg sys_clk;
	reg sys_rst_n;

	reg tim_psel;
	reg tim_pwrite;
	reg tim_penable;
	reg [11:0] tim_paddr;
	reg [31:0] tim_pwdata;
	wire [31:0] tim_prdata;
	wire tim_pready;
	wire tim_pslverr;
	wire tim_int;
	reg [3:0] tim_pstrb;

	reg dbg_mode;
	
//	reg [31:0]reg_of_data;
/*	//for counter.v
	wire cnt_en;
	wire timer_en;
	wire [11:0] addr;
	wire [31:0] wdata;
	wire wr_en;
	wire [63:0] cnt_value;
*/
initial begin
	sys_clk = 0;
	forever #5 sys_clk = ~sys_clk;
end
/*
initial begin
	sys_rst_n = 0;
	#20;
	sys_rst_n = 1;
end*/

initial begin
	sys_rst_n = 0;
	tim_psel = 0;
	tim_pwrite = 0;
	tim_penable = 0;
	tim_paddr = 0;
	tim_pwdata = 32'hFFFF_FFFF;
	tim_pstrb = 4'b1111;
	dbg_mode = 0;
	repeat(2) @(posedge sys_clk);
	sys_rst_n = 1;
end
timer_top uut (
	.sys_clk(sys_clk),
	.sys_rst_n (sys_rst_n),
	.tim_psel (tim_psel),
	.tim_pwrite(tim_pwrite),
	.tim_penable (tim_penable),
	.tim_paddr (tim_paddr),
	.tim_pwdata (tim_pwdata),
	.tim_pstrb (tim_pstrb),
	.dbg_mode (dbg_mode),
	.tim_prdata (tim_prdata),
	.tim_pready (tim_pready),
	.tim_pslverr (tim_pslverr),
	.tim_int (tim_int)
);
/*
counter uut_counter(
	.clk(sys_clk),
	.rst_n(sys_rst_n),
	.cnt_en(cnt_en),
	.timer_en(timer_en),
	.addr(addr),
	.wdata(wdata),
	.wr_en(wr_en),
	.cnt_value(cnt_value)
);*/

task apb_write;
	input [11:0] addr;
	input [31:0] data;
//	integer timeout;
	begin
		$display ("t=%10d [TB_WRITE]: addr=%x || data=%x",$time,addr, data);

		@(posedge sys_clk);
		#1;
		tim_paddr <= addr;
		tim_pwdata <= data;
		tim_pwrite <= 1;
		tim_psel <= 1;
		tim_penable <= 0;

		@(posedge sys_clk);
		#1;
		tim_penable <= 1;
		wait(tim_pready == 1);

	//	while (!tim_pready && timeout < 1000) begin
	//		@(posedge sys_clk);
	//		timeout = timeout + 1;
	//	end

		@(posedge sys_clk);
		#1;
//		$display ("t=%10d [TB_WRITE]: addr=%x data=%x",$time,addr, data);
		tim_psel <= 0;
		tim_penable <= 0;
		tim_pwrite <= 0;
		tim_paddr <= 0;
		tim_pwdata <= 0;
	end
endtask

task apb_read;
	input [11:0] addr;
	input [31:0] data;
//	integer timeout;
	begin
		@(posedge sys_clk);
		#1;
		tim_paddr <= addr;
		tim_pwrite <= 0;
		tim_psel <= 1;
		tim_penable <= 0;

		@(posedge sys_clk);
		#1;
		tim_penable <= 1;
//		timeout = 0
//		while (!tim_pready && timeout < 1000) begin
//			@(posedge sys_clk)begin
//				timeout = timeout + 1;end
//		end
		wait (tim_pready == 1);
		#1;
	//	tim_prdata = data;
		data= tim_prdata;
		@(posedge sys_clk);
		tim_pwrite <= 0;
		tim_pwdata <= 0;
		tim_paddr <= 0;
		tim_psel <= 0;
		tim_penable <= 0;
		$display("[read] 0x%0h = 0x%08h",addr,data);
//		$display("t=%10d [TB_READ]: addr=0x%0h || rdata=0x%08h",$time,addr, tim_prdata);
	end
endtask
/*
task test_div_val;
	integer i;
	reg [31:0] configg;
	begin
		for(i = 0; i<16; i = i + 1) begin
			configg = {28'd0, i[3:0]};
				$display(" TC_DIV_0%d: div_val = %0d",i,i);
				apb_write(12'h000,configg | 32'h00000003);
				repeat (10) @(posedge sys_clk);
				apb_read(12'h000,tim_prdata);
			end
		end
	endtask

initial begin test_div_val(); end*/
initial begin
//	assign tim_prdata = reg_of_data;
	wait (sys_rst_n == 1);
	#20;
	$display(" [01]: register default value");

	apb_read(12'h000,tim_prdata);
	apb_read(12'h004,tim_prdata);
	apb_read(12'h008,tim_prdata);
	apb_read(12'h00C,tim_prdata);
	apb_read(12'h010,tim_prdata);
	apb_read(12'h014,tim_prdata);
	apb_read(12'h018,tim_prdata);
	apb_read(12'h01C,tim_prdata);
	//#1000;
	$display(" [02]: overflow from TDR0 to TDR1");
	apb_write(12'h000, 32'h00000000);
	#10;
	apb_write(12'h004, 32'h000000FF);
	#10;
	apb_write(12'h008, 32'h00000000);
	#10;
	apb_write(12'h000, 32'h00000001);
	repeat (254) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	apb_read(12'h008,tim_prdata);

	$display (" [03]: overflow from TDR0 to TDR1");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h004, 32'hFFFFFF00);
	apb_write(12'h008, 32'h00000000);
	apb_write(12'h000, 32'h00000001);
	repeat (256) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	apb_read(12'h008,tim_prdata);

	$display(" [04]: Interrupt ");
	apb_write(12'h00C, 32'h00000010);
	apb_write(12'h010, 32'h00000000);
	apb_write(12'h014, 32'h00000001);
	apb_write(12'h000, 32'h00000001);
	repeat (20) @(posedge sys_clk);
	apb_read(12'h018,tim_prdata);
	apb_write(12'h018, 32'h00000001);
	apb_read(12'h018,tim_prdata);

	$display(" toggle psel ");
	@(posedge sys_clk);
	tim_psel <= 1;
	tim_pwrite <= 1;
	tim_penable <= 0;
	tim_paddr <= 12'h004;
	tim_pwdata <= 32'hAAAA_AAAA;
	@(posedge sys_clk);
	tim_penable <= 1;
	#2 tim_psel <= 0;
	#2 tim_psel <= 1;

	@(posedge sys_clk);
	tim_psel <= 0;
	tim_pwrite <= 0;
	tim_penable <= 0;
	apb_read(12'h004,tim_prdata);

	$display(" hold psel high in SETUP phase for mutiple cycle");
	@(posedge sys_clk);
	tim_psel <= 1;
	tim_pwrite <= 1;
	tim_penable <= 0;
	tim_paddr <= 12'h004;
	tim_pwdata <= 32'hBBBB_BBBB;
	repeat (3) @(posedge sys_clk);
	tim_penable <= 1;
	@(posedge sys_clk);
	tim_psel <= 0;
	tim_pwrite <= 0;
	tim_penable <= 0;
	apb_read(12'h004,tim_prdata);

	$display(" change pwrite mid ENABLE phase");
	@(posedge sys_clk);
	tim_psel <= 1;
	tim_pwrite <= 1;
	tim_penable <= 0;
	tim_paddr <= 12'h004;
	tim_pwdata <= 32'hCCCC_CCCC;
	@(posedge sys_clk);
	tim_penable <= 1;
	#2 tim_pwrite <= 0;
	@(posedge sys_clk);
	tim_psel <= 0;
	tim_pwrite <= 0;
	tim_penable <= 0;
	apb_read(12'h004,tim_prdata);
	
	$display(" [05]: div_en/div_val check");
	apb_write(12'h000, 32'h00000103);
	repeat(20) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	#50;
/*	for(cnt_en = 0; cnt_en <=1'b1; cnt_en = cnt_en + 1)begin
		for(timer_en = 0; timer_en <=1'b1; timer_en = timer_en + 1)begin
			for(addr = 0; addr <=12'h8; addr = addr + 1)begin
				$display("cnt_en=%b || timer_en=%b || addr = %h ", cnt_en, timer_en, addr);end
			end
		end
	#100;*/
	
	$display(" [06] psel = 0 penable = 1 pwrite = 0");
	@(posedge sys_clk);
	tim_psel <= 0;
	tim_pwrite <= 0;
	tim_penable <= 1;
	tim_paddr <= 12'h004;
	@(posedge sys_clk);
	tim_psel <= 0;
	tim_penable <= 0;	
	#100;

	$display("[07] THCSR write to toggle halt_req");
	apb_write(12'h01C, 32'h00000001);
	apb_read(12'h01C,tim_prdata);
	#100;

	$display("[08] TISR clear interrupt");
	apb_write(12'h018, 32'h00000001);
	apb_read(12'h018,tim_prdata);
	#100;

	$display("[09] TCR write with div_val > 8");
	apb_write(12'h000, 32'h00000F03);
	apb_read(12'h000,tim_prdata);
	#100;

	$display("[10] default case in write ");
	apb_write(12'hFFF, 32'hDEADBEEF);
	#100;

	$display("[11] TIER write to enable interrupt");
	apb_write(12'h014, 32'h00000001);
	apb_read(12'h014,tim_prdata);
	#100;

	$display(" [12] Write TISR with tim_pwdata[0] = ");
	apb_write(12'h018, 32'h00000000);
	apb_read(12'h018,tim_prdata);
	#100;

	$display(" [13] Trigger int_st_set by matching counter");
	apb_write(12'h00C, 32'h00001234);
	apb_write(12'h010, 32'h00005678);
	apb_write(12'h004, 32'h00005678);
	apb_read(12'h018,tim_prdata);
	#100;

	$display(" [14] Toggle register");
	apb_write(12'h00C, 32'hF2345678);
	apb_write(12'h008, 32'h87654321);
	apb_write(12'h014, 32'h0000000F);
	apb_write(12'h01C, 32'h00000001);
	apb_write(12'h01C, 32'h00000000);
	$display(" TCMP0 TCMP1");
	apb_write(12'h00C, 32'hFFFF_FFFF);
	apb_write(12'h010, 32'hAAAA_AAAA);
	$display(" TDR1");
	apb_write(12'h008, 32'h55555555);
	$display(" Toggle div_val");
	apb_write(12'h000, 32'h00000101);
	apb_write(12'h000, 32'h00000201);
	apb_write(12'h000, 32'h00000401);
	$display("toggle halt_req");
	apb_write(12'h01C, 32'h00000001);
	apb_write(12'h01C, 32'h00000000);
	$display(" Change value for toggling");
	apb_write(12'h008, 32'hAAAAAAAA);
	apb_write(12'h008, 32'h55555555);
	apb_write(12'h008, 32'h33333333);
	apb_write(12'h008, 32'hCCCCCCCC);

	apb_write(12'h000, 32'h00000001);
	apb_write(12'h000, 32'h00000002);
	apb_write(12'h000, 32'h00000004);
	apb_write(12'h000, 32'h00000008);
	#100;

	$display(" [15] {TDR1,TDR0} == {TCM1,TCMP0}");
	apb_write(12'h00C, 32'h89ABCDEF);
	apb_write(12'h010, 32'h01234567);
	apb_write(12'h004, 32'h89ABCDEF);
	apb_write(12'h008, 32'h01234567);
	apb_read(12'h018,tim_prdata);
	#100;

	$display(" [16] Match counter with compare value");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h004, 32'h89ABCDEF);
	apb_write(12'h008, 32'h01234567);
	apb_write(12'h00C, 32'h89ABCDEF);
	apb_write(12'h010, 32'h01234567);
	apb_write(12'h014, 32'h00000001);
	apb_write(12'h000, 32'h00000001);
	@(posedge sys_clk);
	apb_read(12'h018,tim_prdata);
	#100;

	$display(" [17] Trigger default case in register");
	apb_write(12'h000, 32'h0000000);
	apb_write(12'hFFF, 32'hDEADBEEF);
	apb_read(12'hFFF,tim_prdata);
	#100;

	$display(" [18] Clear interrupt status");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h004, 32'h89ABCDEF);
	apb_write(12'h008, 32'h01234567);
	apb_write(12'h00C, 32'h89ABCDEF);
	apb_write(12'h010, 32'h01234567);
	apb_write(12'h014, 32'h00000001);
	apb_write(12'h000, 32'h00000001);
	@(posedge sys_clk);
	apb_read(12'h018,tim_prdata);
	apb_write(12'h01C, 32'h00000001);
	@(posedge sys_clk);
	apb_read(12'h018,tim_prdata);
	#100;
	
	$display(" Toggle high bit");
	apb_write(12'h00C, 32'hFFFFFFFF);
	apb_write(12'h010, 32'hFFFFFFFF);
	apb_write(12'h00C, 32'h80000000);
	apb_write(12'h010, 32'h80000000);
	apb_write(12'h00C, 32'h00000000);
	apb_write(12'h010, 32'h00000000);
	#100;

	$display(" [19] div_val = 0");
	apb_write(12'h000, 32'h00000100);
	repeat (20) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
//	apb_read(12'h000);
	$display("Expect TDR0 = 0 ");
	#100;
	
	$display(" [20] div_en = 0 div_val = 8");
	apb_write(12'h000, 32'h00000801);
	repeat (20) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	$display(" Expect TDR = 0 when div_en = 0");
	#100;

	$display(" [21] div_val = 1");
	apb_write(12'h000, 32'h00000101);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	$display("Expect TDR0 = 10");
	#100;
	
	$display(" [22] div_val = 255");
	apb_write(12'h000, 32'h0000FF01);
	repeat(255) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	
	apb_write(12'h000, 32'h0000FF01);
	repeat (255) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);

	$display("[23] div_val = 0");
	apb_write(12'h000, 32'h00000100);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	#100;

	$display("[24] timer_en = 0");
	apb_write(12'h000, 32'h00000000);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);
	#100;

	$display(" [25] Toggle div_factor");
	apb_write(12'h000, 32'h00000100);
	apb_write(12'h000, 32'h00000018);
	apb_read(12'h000,tim_prdata);
	repeat(10) @(posedge sys_clk);
	#100

	$display(" [26] Enable interrupt counting ");
	apb_write(12'h000, 32'h00000001);
	apb_write(12'h008, 32'h00000001);
	apb_read(12'h000,tim_prdata);
	apb_read(12'h008,tim_prdata);
	repeat (100) @(posedge sys_clk);
	#100
	
	$display("[27]int_en = 0 while int_st = 1");
	apb_write(12'h00C, 32'h00000010);
	apb_write(12'h01C, 32'h00000000);
	apb_write(12'h014, 32'h00000000);
	apb_write(12'h000, 32'h00000001);
	repeat (20) @(posedge sys_clk);
	apb_read(12'h018, tim_prdata);
	#100;

	$display(" [28] Write TDR0 0x0000_00FF TDR1 0x0000_0000");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h004, 32'h000000FF);
	apb_write(12'h008, 32'h00000000);
	apb_write(12'h000, 32'h00000001);
	repeat(254) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);

	$display(" [29] Boundary TDR0, TDR1");
	apb_write(12'h004,32'hFFFFFF00);
	apb_write(12'h008,32'h00000000);
	repeat (252) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);
	#100;

	$display("[30] Countinues counting when overflow");
	apb_write(12'h004,32'hFFFFFF00);
	apb_write(12'h008,32'hFFFFFFFF);
	repeat(253) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);
	#100;

	$display("[31] div_en = 0, timer_en = 1, count on sys_clk");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h004, 32'h00000000);
	apb_write(12'h008, 32'h00000000);
	apb_write(12'h000, 32'h00000001);
	repeat (156) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);
	#100;

	$display(" [32] Write TCR to turn on timer");
	apb_write(12'h000, 32'h00000001);
	apb_read(12'h000, tim_prdata);#100;
	//them pass dis
	
	$display(" [33] Write TMP0 and TCMP1");
	apb_write(12'h00C, 32'h12345678);
	apb_write(12'h010, 32'h9ABCDEF0);
	apb_read(12'h00C, tim_prdata);
	#100;

	$display(" [34] Write TDR0 and TDR1");
	apb_write(12'h004, 32'h89ABCDEF);
	apb_write(12'h008, 32'h01234567);
	apb_read(12'h018, tim_prdata);
	#100;

	$display(" [35] Write TIER to turn on int_en");
	apb_write(12'h014, 32'h00000001);
	apb_read(12'h014, tim_prdata);
	#100;

	$display(" [36] Write TISR to delete");
	apb_write(12'h018, 32'h00000001);
	apb_read(12'h018, tim_prdata);
	#100;

	$display(" [37] div_val = 0");
	apb_write(12'h000, 32'h00000003);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display(" [38] div_val = 255");
	apb_write(12'h000, 32'h0000FF03);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display(" [39] Toggle int_cnt");
	apb_write(12'h00C, 32'h00000001);
	apb_write(12'h010, 32'h00000000);
	apb_write(12'h014, 32'h00000001);
	apb_write(12'h000, 32'h00000001);
	repeat (100) @(posedge sys_clk);
	apb_read(12'h018, tim_prdata);
	#100;

	$display(" [40] Continuos toggling div_val");
	apb_write(12'h000, 32'h00000103);
	apb_write(12'h000, 32'h00000203);
	apb_write(12'h000, 32'h00000403);
	apb_write(12'h000, 32'h00000803);
	repeat (20) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[41] timer_en off");
	apb_write(12'h000, 32'h00000000);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	#100;

	$display("[42] div_val = 0xF8");
	apb_write(12'h000, 32'h0000F803);
	repeat (20) @(posedge sys_clk);
	apb_read(12'h000,tim_prdata);
	#100;

	$display("[43] increase over 31");
	apb_write(12'h00C, 32'h00000001);
	apb_write(12'h010, 32'h00000000);
	apb_write(12'h014, 32'h00000001);
	apb_write(12'h000, 32'h00000001);

	repeat (40) @(posedge sys_clk);
	apb_read(12'h018,tim_prdata);
	#100;

	$display("[44] div_val = 0xE8");
	apb_write(12'h000, 32'h0000E803);
	repeat(20) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[45] increase int_cnt over 63");
	apb_write(12'h00C, 32'h0000001);
	apb_write(12'h010, 32'h0000000);
	apb_write(12'h014, 32'h0000001);
	apb_write(12'h000, 32'h0000001);
	repeat (70) @(posedge sys_clk);
	apb_read(12'h018, tim_prdata);
	#100;

	$display("[46] div_val = 4");
	apb_write(12'h000, 32'h00000403);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[47] div_val = 6");
	apb_write(12'h000, 32'h00000603);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[48] div_val = 8");
	apb_write(12'h000, 32'h00000803);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[49] div_val[3] = 1");
	apb_write(12'h000, 32'h00000803);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display(" [50] div_val[5] =1");
	apb_write(12'h000, 32'h00002003);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[51] div_val[7] = 1");
	apb_write(12'h000, 32'h00008003);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
		
	$display("[52] div_val = 7");
	apb_write(12'h000, 32'h00000703);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[53] div_val = 8");
	apb_write(12'h000, 32'h00000803);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[54] div_val = 5");
	apb_write(12'h000, 32'h00000503);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[55] div_val = 8");
	apb_write(12'h000, 32'h00000803);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000,tim_prdata);
	#100;

	$display("[56] div_val = 3");
	apb_write(12'h000, 32'h00000303);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);
	#100;

	$display("[57] div_val != 8");
	apb_write(12'h000, 32'h0000003);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[58] div_val != 8");
	apb_write(12'h000, 32'h00000003);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[59] int_cnt reaches 128");
	apb_write(12'h000, 32'h00000003);
	repeat (130) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[60] int_cnt reaches 256");
	apb_write(12'h000, 32'h00000003);
	repeat (260) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[61] cnt_en = 1 && timer_en = 0");
	apb_write(12'h000, 32'h00000002);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000,tim_prdata);
/*
	$display("[62] Toggle default");
	force uut.U3.state = 3'b111;
	repeat (5) @(posedge sys_clk);
	release uut.U3.state;*/
	
        $display("[63] timer_en = 0");
	apb_write(12'h004, 32'h00000055);
	apb_write(12'h008, 32'h00000000);
	repeat(100) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);

	$display(" Counter from 0");
	apb_write(12'h000, 32'h00000001);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);

	$display(" Default bracnch of div_val");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h000, 32'h00000901);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);

	$display(" cnt_en = 1 timer_en = 0");
	apb_write(12'h000, 32'h00000100);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);

	$display(" [64] Toggle default by fail div_val");
	apb_write(12'h000, 32'h00000903);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[65] Reset mid cycle");
	apb_write(12'h000, 32'h00000303);
	repeat (5) @(posedge sys_clk);
	sys_rst_n = 1'b1;
	repeat (2) @(posedge sys_clk);
	sys_rst_n = 1'b0;
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[66] Check cnt_en = 1, timer_en = 0");
	apb_write(12'h000, 32'h00000102);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[67] Force cnt_en = 1 timer_en = 0");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h000, 32'h00000100);
	repeat (20) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	
	$display( "[68] Counter not increase timer_en = 0");
	apb_write(12'h004, 32'h00000000);
	apb_write(12'h008, 32'h00000000);
	apb_write(12'h000, 32'h00000001);
	repeat (254) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);

	$display(" [69] Div_val default branch");
	apb_write(12'h000, 32'h00000903);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);

	$display("[70] cnt_en = 1 timer_en = 0");
	apb_write(12'h000, 32'h00000100);
	repeat (50) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);

	$display("[71] ");
	apb_write(12'h000, 32'h00000303);
	repeat (5)@(posedge sys_clk);
	
	$display("[72] Control counter div_val = 8");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h000, 32'h00000803);
	repeat(300) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);

	$display("[73] Control counter div_val = 1");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h000, 32'h00000103);
	repeat(100) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);

	$display("[74] Control counter div_val = 0");
	apb_write(12'h000, 32'h00000000);
	apb_write(12'h000, 32'h00000803);
	repeat(20) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);


	$display("[75] div_val != 8");
	apb_write(12'h000, 32'h00000003);
	repeat(10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[76] ");
	apb_write(12'h000, 32'hFFFFFFFF);
	repeat(300) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);

	$display("[76] div_val = 9");
	apb_write(12'h000, 32'h00000003);
	repeat(10) @(posedge sys_clk);

	$display("[77] Cnt_en = 1 timer_en = 0");
	apb_write(12'h000, 32'h00000102);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h000, tim_prdata);

	$display("[78] Cnt_value timer_en = 0");
	apb_write(12'h000, 32'h00000002);
	apb_write(12'h004, 32'h12345678);
	apb_write(12'h008, 32'h9ABCDEF0);
	repeat (5) @(posedge sys_clk);
	apb_read(12'h004, tim_prdata);
	apb_read(12'h008, tim_prdata);

	$display("[79] cnt_en = 0");
	apb_write(12'h000, 32'h00000001);
	repeat (10) @(posedge sys_clk);
	apb_read(12'h004,tim_prdata);

	$display(" TEST END");
	#50;
	$finish;
	
end
endmodule


