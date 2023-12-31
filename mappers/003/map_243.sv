
module map_243(

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
	assign mao.sst_di[7:0] =
	sst.addr[7:0]  < 8 ? regs[sst.addr[2:0]] : 
	sst.addr[7:0] == 8 ? reg_addr : 
	sst.addr[7:0] == 127 ? cfg.map_idx : 8'hff;
//************************************************************* mapper-controlled pins
	assign srm.ce				= {cpu.addr[15:13], 13'd0} == 16'h6000;
	assign srm.oe				= cpu.rw;
	assign srm.we				= !cpu.rw;
	assign srm.addr[12:0]	= cpu.addr[12:0];
	
	assign prg.ce				= cpu.addr[15];
	assign prg.oe 				= cpu.rw;
	assign prg.we				= 0;
	assign prg.addr[14:0]	= cpu.addr[14:0];
	assign prg.addr[16:15] 	= prg_map[1:0];
	
	assign chr.ce 				= mao.ciram_ce;
	assign chr.oe 				= !ppu.oe;
	assign chr.we 				= cfg.chr_ram ? !ppu.we & mao.ciram_ce : 0;
	assign chr.addr[12:0]	= ppu.addr[12:0];
	assign chr.addr[16:13]	= chr_map[3:0];

	
	//A10-Vmir, A11-Hmir
	assign mao.ciram_a10 	= 
	mirror_mode[1:0] == 2'b00 	? ppu.addr[11] :
	mirror_mode[1:0] == 2'b01 	? ppu.addr[10] :
	mirror_mode[1:0] == 2'b11 	? 1 :
	ppu.addr[11:10] == 0 		? 0 : 1;
	
	assign mao.ciram_ce 		= !ppu.addr[13];
	
	assign mao.irq				= 0;
	assign int_cpu_oe 		= regs_ce & cpu.rw & cpu.addr[0];
	assign int_cpu_data		= regs[reg_addr[2:0]];
//************************************************************* mapper implementation
		
	wire regs_ce 				= (cpu.addr[15:0] & 16'hC100) == 16'h4100;
		
	wire [3:0]chr_map 		= {regs[2][0], regs[4][0], regs[6][1:0]};
	wire [2:0]prg_map 		= cfg.map_idx == 150 ? (regs[2][0] | regs[5][1:0]) : regs[5][1:0];//sub mapper required?
	wire [1:0]mirror_mode 	= regs[7][2:1];
	
	reg [2:0]reg_addr;
	reg [2:0]regs[8];
	
	always @(negedge cpu.m2)
	if(sst.act)
	begin
		if(sst.we_reg & sst.addr[7:0]  < 8)regs[sst.addr[2:0]] 	<= sst.dato;
		if(sst.we_reg & sst.addr[7:0] == 8)reg_addr 					<= sst.dato;
	end
		else
	if(mai.map_rst)
	begin
		regs[4] <= 0;
		regs[5] <= 0;
		regs[6] <= 0;
		regs[7] <= 0;
	end
		else
	if(regs_ce & !cpu.rw)
	begin
		
		if(cpu.addr[0] == 0)reg_addr[2:0] 				<= cpu.data[2:0];
		if(cpu.addr[0] == 1)regs[reg_addr[2:0]][2:0] <= cpu.data[2:0];
	
	end
	
endmodule
