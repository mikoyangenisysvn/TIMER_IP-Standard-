module test_bench;
	reg sys_clk = 0;
	reg sys_rst_n;
	reg tim_psel, tim_pwrite, tim_penable;
	reg [11:0] tim_paddr;
	reg [31:0] tim_pwdata;
	wire [31:0] tim_prdata;
	wire tim_pready;
	wire tim_pslverr;
	wire tim_int;
	reg [3:0] tim_pstrb;
	reg dbg_mode;

	reg [31:0] vals [0:3];
	reg [11:0] addrs [0:4];
	integer j,k,i;
	always #5 sys_clk = ~sys_clk;

	timer_top dut(
		.sys_clk(sys_clk),
		.sys_rst_n(sys_rst_n),
		.tim_psel(tim_psel),
		.tim_pwrite(tim_pwrite),
		.tim_penable(tim_penable),
		.tim_paddr(tim_paddr),
		.tim_pwdata (tim_pwdata),
		.tim_prdata (tim_prdata),
		.tim_pready (tim_pready),
		.tim_pslverr (tim_pslverr),
		.tim_int (tim_int),
		.tim_pstrb(tim_pstrb),
		.dbg_mode (dbg_mode)
	);

task write_apb;
	input [11:0] addr;
	input [31:0] data;
	begin
		@(posedge sys_clk);
		tim_psel = 1;
		tim_pwrite = 1;
		tim_penable = 0;
		tim_paddr = addr;
		tim_pwdata = data;

		@(posedge sys_clk);
		tim_penable = 1;

//		wait (tim_pready == 1);
		@(posedge sys_clk);
		tim_psel = 0;
		tim_penable = 0;
		tim_pwrite = 0;
		$display(" [WRITE] addr = 0x%03h | data = 0x%08h | time=%0t", addr, data, $time);
	end
endtask

task read_apb;
	input [11:0] addr;
	begin
		@(posedge sys_clk);
		tim_psel = 1;
		tim_pwrite = 0;
		tim_penable = 0;
		tim_paddr = addr;

		@(posedge sys_clk);
		tim_penable = 1;

	//	wait (tim_pready == 1);
		@(posedge sys_clk);
		$display ("[READ addr = 0x03h |  data = 0x08h | time=%0t", addr, tim_prdata,$time);
		tim_psel = 0;
		tim_penable = 0;
	end
endtask

task default_check;
	integer idx;
	reg [11:0] tbl [0:7];
	begin
		tbl[0] = 12'h000; 
		tbl[1] = 12'h004;
		tbl[2] = 12'h008;
		tbl[3] = 12'h00C;
		tbl[4] = 12'h010;
		tbl[5] = 12'h014;
		tbl[6] = 12'h018;
		tbl[7] = 12'h01C;

		$display("\n [09] Default value check after POR");
		sys_rst_n <= 0; 
		repeat (2) @(posedge sys_clk);
		for (idx=0; idx<8; idx=idx+1)
			read_apb(tbl[idx]);
	end
endtask

task speed_test_normal;
	reg [63:0] exp_cnt;
	begin
		$display("\n [10] Counter speed test: div_en = 0");
		write_apb(12'h004, 32'h0);
		write_apb(12'h008, 32'h0);
		write_apb(12'h000, 32'h0000_0001);

		repeat (100) @(posedge sys_clk);
		read_apb(12'h004);
		read_apb(12'h008);

		exp_cnt = 100;
		if({tim_prdata, 32'hb0} !== {32'h0, exp_cnt[31:0]})
			$display(" [FAIL] speed_test_normal expect %0d", exp_cnt);
		else
			$display(" PASS");
	end
endtask

task speed_test_div;
	input [3:0] div_v;
	integer cyc;
	reg [63:0] exp_cnt;
	begin
		cyc = (1<<div_v);
		$display("\n [11] Speed test div_val=%0d", div_v);
		write_apb(12'h000,{20'h0, div_v, 6'h0, 1'b1, 1'b0});
		write_apb(12'h004,32'h0); write_apb(12'h008,32'h0);
		write_apb(12'h000,{20'h0, div_v, 6'h0, 1'b1,1'b1});

		repeat (cyc*5) @(posedge sys_clk);
		read_apb(12'h004);

		exp_cnt = 5;
		if(tim_prdata !== exp_cnt[31:0])
		$display("[FAIL] div_val=%0d expect %0d",div_v,exp_cnt);
		else
		$display("PASS");
end
endtask

task stop_run;
	reg [31:0] bfor, aft;
	begin
		$display("\n[12] Stop_run");
		write_apb(12'h000, 32'h0000_0001);
		repeat (50) @(posedge sys_clk);
		read_apb(12'h004); bfor = tim_prdata;

		write_apb(12'h000, 32'h0000_0000);
		repeat(100) @(posedge sys_clk);
		read_apb(12'h004);
		if(tim_prdata !== bfor)
			$display("[FAIL] counter still change when stop");
		write_apb(12'h000, 32'h0000_0001);
		repeat(10) @(posedge sys_clk);
		read_apb(12'h004); aft = tim_prdata;
		if(aft <= bfor) 
			$display("[FAIL] counter did not resume");
		else
			$display("PASS");
	end
endtask

task write_while_run;
	reg [31:0] snap;
	begin
		$display("\n [13] Write TDR while running(ignore)");
		write_apb(12'h000, 32'h0000_0001);
		repeat (10) @(posedge sys_clk);
		read_apb(12'h004);

		write_apb(12'h004, 32'hDEAD_BEEF);
		write_apb(12'h008, 32'hCAFE_F00D);

		repeat (1) @(posedge sys_clk);
		read_apb(12'h004);
		if(tim_prdata == 32'hDEAD_BEEF)
			$display("[FAIL] value overwritten!");
		else
			$display("[PASS] write ignored");
	end
endtask

task int_mask_unmask;
	begin
		$display("\n [14] Interrupt mid-run");
		write_apb(12'h00C, 32'd20);
		write_apb(12'h010, 32'd0);
		write_apb(12'h004, 32'd0);
		write_apb(12'h008, 32'd0);

		write_apb(12'h014, 32'h0);
		write_apb(12'h000, 32'h1);

		repeat (40) @(posedge sys_clk);
		if (tim_int) 
			$display("[FAIL] interrupt appeared while masked");
		write_apb(12'h014, 32'h1);
		repeat (1) @(posedge sys_clk);

		read_apb(12'h004);
		write_apb(12'h00C, tim_prdata+10);
		repeat (100) @(posedge sys_clk);

		if(tim_int)
			$display(" [PASS] int asserted after unmask");
		else
			$display("[FAIL] no interrupt after unmask");
	end
endtask

task overflow_64bit;
	begin
		$display("\n [15] 64-bit overflow check");

		write_apb(12'h004, 32'hFFFF_FFFF);
		write_apb(12'h000, 32'h1);

		repeat (30) @(posedge sys_clk);
		read_apb(12'h008);
		if(tim_prdata !== 32'h0)
			$display(" [FAIL] upper 32 not wrapped");
		else 
			$display("PASS");
	end
endtask

task access_reserved;
	begin
		$display("\n [16] Reserved address RAZ/WI test");
		write_apb(12'h060, 32'h1234_5678);
		read_apb (12'h060);
		if (tim_prdata !== 32'h0)
			$display("[FAIL] reserved read non-zero");
		else 
			$display("PASS");
	end
endtask

task start_from_ff;
	reg [31:0]hi, lo;
	begin
		$display("\n [17] Write TDR0=0xFF, 256 clk ");
		write_apb(12'h000, 32'h0);
		write_apb(12'h004, 32'h0000_00FF);
		write_apb(12'h008, 32'h0000_0000);
		write_apb(12'h000, 32'h1);
		repeat(256) @(posedge sys_clk);
		read_apb(12'h004); lo = tim_prdata;
		read_apb(12'h008); hi = tim_prdata;
		if(lo == 32'h0000_01FF && hi == 32'h0)
			$display(" PASS");
		else 
			$display("[FAIL] expect lo=0x1FF hi=0x0, got lo=0x%08h hi=0x%08h", lo,hi);
	end
endtask

initial begin
	//integer j,k,i;
	tim_psel = 0;
	tim_pwrite = 0;
	tim_penable = 0;
	tim_paddr = 0;
	tim_pwdata = 0;
	tim_pstrb = 4'b1111;
	dbg_mode = 1'b0;

	vals[0] = 32'h00000000;
	vals[1] = 32'h55555555;
	vals[2] = 32'haaaaaaaa;
	vals[3] = 32'hffffffff;

	addrs[0] = 12'h004;
	addrs[1] = 12'h008;
	addrs[2] = 12'h00C;
	addrs[3] = 12'h010;
	addrs[4] = 12'h018;
//reset
/*	sys_rst_n = 0;
	tim_psel = 0;
	tim_penable = 0;
	tim_pwrite = 0;*/
	repeat(2)
	@(posedge sys_clk);
	sys_rst_n = 1;
	$display("\n[01] System reset ");
	
	$display("\n [02] Check TCR default");
	read_apb(12'h000);
	
	$display("\n [03] Write TCR with div_val");
	write_apb(12'h000, 32'h00000802);
	read_apb(12'h000);

	write_apb(12'h000, 32'h00000902);
	read_apb(12'h000);

	$display("[04] Write and Read THCSR");
	write_apb(12'h01C, 32'h00000001);
	read_apb(12'h01C);

	write_apb(12'h01C, 32'h00000000);
	read_apb(12'h01C);

	$display("\n [05] Read other default registers");
	for(j = 0; j < 4; j = j + 1) begin
		write_apb(12'h000, vals[j]);
		read_apb(12'h000);end
	for(k = 0; k < 6; k = k + 1)begin
		read_apb(addrs[k]);end

	$display("\n [06] Access invalid addresses");
	write_apb(12'h020, 32'hA5A5A5A5);
	read_apb(12'h020);
	write_apb(12'hFFF, 32'h5A5A5A5A);
	read_apb(12'hFFF);


	$display("\n [07] Start timer from TDR=0xFF");
	write_apb(12'h004, 32'h000000FF);
	write_apb(12'h008, 32'h00000000);
	write_apb(12'h000, 32'h00000001);
	repeat(256) 
	@(posedge sys_clk);
	read_apb(12'h004);
	read_apb(12'h008);

	$display("\n [08] Check Interrupt generation");
	write_apb(12'h00C, 32'h00000010);
	write_apb(12'h010, 32'h00000000);
	write_apb(12'h014, 32'h00000001);
	write_apb(12'h000, 32'h00000001);

/*	for(i = 0; i < 1000; i = i + 1) begin
		@(posedge sys_clk);
		if(tim_int == 1)begin
		$display("[INT] interrupt at cycle %0d",i);
		break;
	end
end*/

	i = 0;
	while( i<1000 && tim_int != 1) begin
		@(posedge sys_clk);
		i = i + 1;end

	if (tim_int) $display("Interrupt at cycle %0d", i);
	else $display("[FAIL] no interrupt within 1000 cycles");

//	if(i == 1000)begin
//		$display("[FAIL] Not Interrupt within 1000 cyccles");end
//		$display("\n [08] Clear Interrupt");
		read_apb(12'h018);
		write_apb(12'h018, 32'h00000001);
		read_apb(12'h018);
	//	$display("\n DONE");
	repeat(10) @(posedge sys_clk);

	default_check();
	speed_test_normal();
	speed_test_div(1);
	speed_test_div(4);
	speed_test_div(8);
	stop_run();
	write_while_run();
	int_mask_unmask();
	overflow_64bit();
	access_reserved();
	$display("DONE");
	repeat (20) @(posedge sys_clk);

	start_from_ff();
/*	for (i = 0; i<= 32'hFFFF_FFFF; i = i + 1)begin
		write_apb(i,32'h0);
		for(j = 0; j <= 32'hFFFF_FFFF; j = j + 1)begin
			write_apb(32'h0,j);end
		end*/

		      
	$finish;
end
endmodule
