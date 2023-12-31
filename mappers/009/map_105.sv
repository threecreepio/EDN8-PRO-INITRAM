
module map_105(//MMC1

	input  MapIn  mai,
	output MapOut mao
);
//************************************************************* base header
	CpuBus cpu;
	PpuBus ppu;
	SysCfg cfg;
	SSTBus sst;
	assign cpu = mai.cpu;
	assign ppu = mai.ppu;
	assign cfg = mai.cfg;
	assign sst = mai.sst;
	
	MemCtrl prg;
	MemCtrl chr;
	MemCtrl srm;
	assign mao.prg = prg;
	assign mao.chr = chr;
	assign mao.srm = srm;

	assign prg.dati			= cpu.data;
	assign chr.dati			= ppu.data;
	assign srm.dati			= cpu.data;
	
	wire int_cpu_oe;
	wire int_ppu_oe;
	wire [7:0]int_cpu_data;
	wire [7:0]int_ppu_data;
	
	assign mao.map_cpu_oe	= int_cpu_oe | (srm.ce & srm.oe) | (prg.ce & prg.oe);
	assign mao.map_cpu_do	= int_cpu_oe ? int_cpu_data : srm.ce ? mai.srm_do : mai.prg_do;
	
	assign mao.map_ppu_oe	= int_ppu_oe | (chr.ce & chr.oe);
	assign mao.map_ppu_do	= int_ppu_oe ? int_ppu_data : mai.chr_do;
//************************************************************* configuration
	assign mao.prg_mask_off = 0;
	assign mao.chr_mask_off = 0;
	assign mao.srm_mask_off = 0;
	assign mao.mir_4sc		= 0;//enable support for 4-screen mirroring. for activation should be enabled in cfg.mir_4 also
	assign mao.bus_cf 		= 0;//bus conflicts
//************************************************************* save state regs read
	assign mao.sst_di[7:0] 	= 
	sst.addr[7:0] == 8 	? timer[7:0] :
	sst.addr[7:0] == 9 	? timer[15:8] :
	sst.addr[7:0] == 10 	? timer[23:16] :
	sst.addr[7:0] == 11 	? timer[29:24] :
	sst.addr[7:0] == 12 	? {irq_ctrl_st, prg_lock} :
	sst.addr[7:0] <  127 ? sst_di_mmc :
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= wram_ce;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= !prg_ce_n;
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[13:0]	= cpu.addr[13:0];
	assign prg.addr[17:14] 	= prg_addr_x[17:14];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[12:0]	= ppu.addr[12:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= ciram_a10;
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= irq_pend;
//************************************************************* mapper implementation below
	
	wire ciram_a10;
	wire wram_ce;
	wire prg_ce_n;
	wire [17:14]prg_addr;
	wire [16:12]chr_addr;
	wire [7:0]sst_di_mmc;
	
	chip_mmc1 mmc1_inst(
		
		.cpu_addr(cpu.addr[14:13]),
		.cpu_d7(cpu.data[7]),
		.cpu_d0(cpu.data[0]),
		.cpu_m2(cpu.m2),
		.cpu_ce_n(!cpu.addr[15]),
		.cpu_rw(cpu.rw),
		.ppu_addr(ppu.addr[12:10]),
		
		.wram_ce(wram_ce),
		.prg_ce_n(prg_ce_n),
		.ciram_a10(ciram_a10),
		.prg_addr(prg_addr[17:14]),
		.chr_addr(chr_addr[16:12]),
		
		.rst(mai.map_rst),
		.sst(sst),
		.sst_di(sst_di_mmc)
	);
	
//************************************************************* NES-EVENT custom hardware	
	wire irq_pend				= timer[29:25] == {1'b1, cfg.jumper[3:0]};
	
	wire prg_sel				= chr_addr_x[15];
	wire irq_ctrl				= chr_addr[16];
	
	wire [15:13]chr_addr_x	= prg_lock ? 0 : chr_addr[15:13];//lock prg to chip 0 and bank 0
	
	wire [17:14]prg_addr_x 	= prg_sel == 0 ? prg_addr_0 : prg_addr_1;
	wire [17:14]prg_addr_0 	= {1'b0, chr_addr_x[14:13], prg_addr[14]};
	wire [17:14]prg_addr_1 	= {1'b1, prg_addr[16:14]};
		
	wire rst = mai.map_rst | mai.sys_rst;
	
	reg prg_lock;
	reg irq_ctrl_st;
	reg [29:0]timer;
	
	always @(negedge cpu.m2, posedge rst)
	if(rst)
	begin
		prg_lock		<= 1;
		irq_ctrl_st	<= 1;
	end
		else
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 8) timer[7:0]		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 9) timer[15:8]		<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 10)timer[23:16]	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 11)timer[29:24]	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 12){irq_ctrl_st, prg_lock}	<= sst.dato;
	end
		else
	begin
		
		irq_ctrl_st <= irq_ctrl;
		
		if(irq_ctrl == 1 & irq_ctrl_st == 0)
		begin
			prg_lock <= 0;
		end
		
		if(irq_ctrl == 0)
		begin
			timer	<= timer + 1;
		end
			else
		begin
			timer	<= 0;
		end
		
	end
		
endmodule

//************************************************************* mmc1 
module chip_mmc1(
	
	//regular mapper io
	input  [14:13]cpu_addr,
	input  cpu_d7,
	input  cpu_d0,
	input  cpu_m2,
	input  cpu_ce_n,
	input  cpu_rw,
	input  [12:10]ppu_addr,
	
	output wram_ce,
	output prg_ce_n,
	output ciram_a10,
	output [17:14]prg_addr,
	output [16:12]chr_addr,
	
	//extra stuff
	input  rst,
	input  SSTBus sst,
	output [7:0]sst_di
);
	
	assign sst_di = 
	sst.addr[7:0] == 0 	? reg_8x :
	sst.addr[7:0] == 1 	? reg_ax :
	sst.addr[7:0] == 2 	? reg_cx :
	sst.addr[7:0] == 3 	? reg_ex :
	sst.addr[7:0] == 4 	? sreg :
	8'hff;
	
	
	assign wram_ce		= cpu_ce_n == 1 & cpu_addr[14:13] == 2'b11 & reg_ex[4] == 0;
	assign prg_ce_n	= !(cpu_ce_n == 0 & cpu_rw == 1);
	
	assign ciram_a10 	= 
	reg_8x[1] == 0 	? reg_8x[0] :
	reg_8x[0] == 0 	? ppu_addr[10] : ppu_addr[11];
	
		
	assign prg_addr 	= 
	reg_8x[3] == 0 	? {reg_ex[3:1], cpu_addr[14]} :
	reg_8x[2] == 0 	? (cpu_addr[14] == 0 ? 4'h0 : reg_ex[3:0]) :
							  (cpu_addr[14] == 1 ? 4'hf : reg_ex[3:0]);
	
	assign chr_addr 	=
	reg_8x[4] == 0 	? {reg_ax[4:1], ppu_addr[12]} : 
	ppu_addr[12] == 0 ? reg_ax[4:0] :
							  reg_cx[4:0];
	
	wire [4:0]shift_next	= {cpu_d0, sreg[4:1]};
	
	reg[4:0]reg_8x;//control
	reg[4:0]reg_ax;//chr bank 0
	reg[4:0]reg_cx;//chr bank 1
	reg[4:0]reg_ex;//prg bank
	
	reg [2:0]bit_ctr;
	reg [4:0]sreg;
	
	always @(negedge cpu_m2, posedge rst)
	if(rst)
	begin
		reg_8x		<= 5'b11111;
		reg_ex[4]	<= 0;//enable ram by defaukt
	end
		else
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0] == 0)reg_8x <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 1)reg_ax <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 2)reg_cx <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 3)reg_ex <= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 4)sreg 	<= sst.dato;
	end
		else
	if(!cpu_ce_n & !cpu_rw)
	begin
		
		
		if(cpu_d7 == 1)
		begin
			bit_ctr 		<= 0;
			reg_8x[3:2] <= 2'b11;
		end
			else
		if(cpu_d7 == 0 & cpu_rw_st == 1)
		begin
			bit_ctr 		<= bit_ctr == 4 ? 0 : bit_ctr + 1;
			sreg[4:0] 	<= shift_next;
		end
		
		
		if(cpu_d7 == 0 & cpu_rw_st == 1 & bit_ctr == 4)
		case(cpu_addr[14:13])
			0:reg_8x <= shift_next;
			1:reg_ax <= shift_next;
			2:reg_cx <= shift_next;
			3:reg_ex <= shift_next;
		endcase
		
		
	end
	
	reg cpu_rw_st;
	
	always @(negedge cpu_m2)
	begin
		cpu_rw_st <= cpu_rw;
	end
	
endmodule
