;
; File generated by cc65 v 2.13.3
;
	.fopt		compiler,"cc65 v 2.13.3"
	.setcpu		"6502"
	.smart		on
	.autoimport	on
	.case		on
	.debuginfo	off
	.importzp	sp, sreg, regsave, regbank, tmp1, ptr1, ptr2
	.macpack	longbranch
	.forceimport	__STARTUP__
	.import		_gfx_vsync
	.import		_gfx_init
	.export		_gfxOn
	.export		_gfxOff
	.export		_setScroll
	.export		_ppuSetAddr
	.export		_strCopy
	.export		_joyRead
	.export		_printHex
	.export		_beepAPU
	.export		_beepEVD
	.export		_beepTest
	.export		_main

.segment	"RODATA"

L0001:
	.byte	$53,$50,$4C,$49,$54,$54,$54,$54,$54,$54,$54,$54,$54,$54,$54,$54
	.byte	$48,$48,$48,$48,$00,$48,$45,$4C,$4C,$00

; ---------------------------------------------------------------
; void __near__ gfxOn (void)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_gfxOn: near

.segment	"CODE"

;
; gfx_vsync();
;
	ldy     #$00
	jsr     _gfx_vsync
;
; PPU_MASK = 0x0A;
;
	lda     #$0A
	sta     $2001
;
; }
;
	rts

.endproc

; ---------------------------------------------------------------
; void __near__ gfxOff (void)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_gfxOff: near

.segment	"CODE"

;
; gfx_vsync();
;
	ldy     #$00
	jsr     _gfx_vsync
;
; PPU_MASK = 0;
;
	lda     #$00
	sta     $2001
;
; }
;
	rts

.endproc

; ---------------------------------------------------------------
; void __near__ setScroll (unsigned char, unsigned char)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_setScroll: near

.segment	"CODE"

;
; PPU_ADDR = 0;
;
	lda     #$00
	sta     $2006
;
; PPU_SCROLL = y;
;
	tay
	lda     (sp),y
	sta     $2005
;
; PPU_SCROLL = x;
;
	iny
	lda     (sp),y
	sta     $2005
;
; }
;
	jmp     incsp2

.endproc

; ---------------------------------------------------------------
; void __near__ ppuSetAddr (unsigned short)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_ppuSetAddr: near

.segment	"CODE"

;
; PPU_ADDR = addr >> 8;
;
	jsr     ldax0sp
	stx     $2006
;
; PPU_ADDR = addr & 0xff;
;
	ldy     #$00
	lda     (sp),y
	sta     $2006
;
; }
;
	jmp     incsp2

.endproc

; ---------------------------------------------------------------
; void __near__ strCopy (__near__ unsigned char*)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_strCopy: near

.segment	"CODE"

;
; while (*src)PPU_DATA = *src++;
;
L0178:	jsr     ldax0sp
	sta     ptr1
	stx     ptr1+1
	ldy     #$00
	lda     (ptr1),y
	jeq     incsp2
	jsr     ldax0sp
	sta     regsave
	stx     regsave+1
	jsr     incax1
	jsr     stax0sp
	ldy     #$00
	lda     (regsave),y
	sta     $2007
	jmp     L0178

.endproc

; ---------------------------------------------------------------
; unsigned char __near__ joyRead (void)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_joyRead: near

.segment	"CODE"

;
; u8 joy = 0;
;
	lda     #$00
	jsr     pusha
;
; JOY_PORT = 0x01;
;
	jsr     decsp1
	lda     #$01
	sta     $4016
;
; JOY_PORT = 0x00;
;
	lda     #$00
	sta     $4016
;
; for (i = 0; i < 8; i++) {
;
	tay
L01AF:	sta     (sp),y
	cmp     #$08
	bcs     L01A2
;
; joy <<= 1;
;
	iny
	lda     (sp),y
	asl     a
	sta     (sp),y
;
; joy |= JOY_PORT & 1;
;
	lda     $4016
	and     #$01
	ora     (sp),y
	sta     (sp),y
;
; for (i = 0; i < 8; i++) {
;
	dey
	lda     (sp),y
	clc
	adc     #$01
	jmp     L01AF
;
; return joy;
;
L01A2:	iny
	ldx     #$00
	lda     (sp),y
;
; }
;
	jmp     incsp2

.endproc

; ---------------------------------------------------------------
; void __near__ printHex (unsigned char)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_printHex: near

.segment	"CODE"

;
; buff[0] = val >> 4;
;
	jsr     decsp3
	ldy     #$03
	ldx     #$00
	lda     (sp),y
	jsr     asrax4
	ldy     #$00
	sta     (sp),y
;
; buff[1] = val & 15;
;
	ldy     #$03
	lda     (sp),y
	and     #$0F
	ldy     #$01
	sta     (sp),y
;
; buff[2] = 0;
;
	lda     #$00
	iny
	sta     (sp),y
;
; buff[0] = buff[0] < 10 ? buff[0] + '0' : buff[0] - 10 + 'A';
;
	tay
	lda     (sp),y
	cmp     #$0A
	bcs     L0165
	ldx     #$00
	lda     (sp),y
	ldy     #$30
	jmp     L01B0
L0165:	ldx     #$00
	lda     (sp),y
	ldy     #$0A
	jsr     decaxy
	ldy     #$41
L01B0:	jsr     incaxy
	ldy     #$00
	sta     (sp),y
;
; buff[1] = buff[1] < 10 ? buff[1] + '0' : buff[1] - 10 + 'A';
;
	iny
	lda     (sp),y
	cmp     #$0A
	bcs     L016F
	ldx     #$00
	lda     (sp),y
	ldy     #$30
	jmp     L01B1
L016F:	ldx     #$00
	lda     (sp),y
	ldy     #$0A
	jsr     decaxy
	ldy     #$41
L01B1:	jsr     incaxy
	ldy     #$01
	sta     (sp),y
;
; strCopy(buff);
;
	lda     sp
	ldx     sp+1
	jsr     pushax
	jsr     _strCopy
;
; }
;
	jmp     incsp4

.endproc

; ---------------------------------------------------------------
; void __near__ beepAPU (unsigned char)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_beepAPU: near

.segment	"CODE"

;
; if (on == 0) {
;
	ldy     #$00
	lda     (sp),y
	bne     L0003
;
; APU_STAT = 0;
;
	sta     $4015
;
; return;
;
	jmp     incsp1
;
; APU_FCTR = 0;
;
L0003:	sty     $4017
;
; APU_STAT = 0xff;
;
	lda     #$FF
	sta     $4015
;
; APU_PLSE[1] = 8;
;
	ldx     #$40
	sty     ptr1
	stx     ptr1+1
	lda     #$08
	iny
	sta     (ptr1),y
;
; APU_PLSE[2] = 0xfd;
;
	lda     #$FD
	iny
	sta     (ptr1),y
;
; APU_PLSE[3] = 0;
;
	lda     #$00
	iny
	sta     (ptr1),y
;
; APU_PLSE[0] = 0xBF;
;
	lda     #$BF
	ldy     #$00
	sta     (ptr1),y
;
; }
;
	jmp     incsp1

.endproc

; ---------------------------------------------------------------
; void __near__ beepEVD (unsigned char)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_beepEVD: near

.segment	"CODE"

;
; if (on == 0) {
;
	ldy     #$00
	lda     (sp),y
	bne     L001F
;
; MMC5_STAT = 0;
;
	sta     $5015
;
; return;
;
	jmp     incsp1
;
; MMC5_STAT = 0xff;
;
L001F:	lda     #$FF
	sta     $5015
;
; MMC5_PLSE[1] = 8;
;
	ldx     #$50
	sty     ptr1
	stx     ptr1+1
	lda     #$08
	iny
	sta     (ptr1),y
;
; MMC5_PLSE[2] = 0xfd;
;
	lda     #$FD
	iny
	sta     (ptr1),y
;
; MMC5_PLSE[3] = 0;
;
	lda     #$00
	iny
	sta     (ptr1),y
;
; MMC5_PLSE[0] = 0xBF;
;
	lda     #$BF
	ldy     #$00
	sta     (ptr1),y
;
; }
;
	jmp     incsp1

.endproc

; ---------------------------------------------------------------
; void __near__ beepTest (void)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_beepTest: near

.segment	"CODE"

;
; u8 old_joy = 0xff;
;
	jsr     decsp1
	lda     #$FF
	jsr     pusha
;
; u8 master_vol = 100;
;
	lda     #$64
	jsr     pusha
;
; gfx_vsync();
;
L003A:	ldy     #$00
	jsr     _gfx_vsync
;
; old_joy = joy;
;
	ldy     #$02
	lda     (sp),y
	dey
	sta     (sp),y
;
; joy = joyRead();
;
	dey
	jsr     _joyRead
	ldy     #$02
	sta     (sp),y
;
; if (old_joy == joy)continue;
;
	dey
	ldx     #$00
	lda     (sp),y
	iny
	cmp     (sp),y
	bne     L01B3
	txa
	beq     L003A
;
; if (joy == 0) {
;
L01B3:	lda     (sp),y
	bne     L0044
;
; beepAPU(0);
;
	jsr     pusha
	jsr     _beepAPU
;
; beepEVD(0);
;
	lda     #$00
	jsr     pusha
	jsr     _beepEVD
;
; if (joy == JOY_B && old_joy == 0) {
;
L0044:	ldy     #$02
	lda     (sp),y
	cmp     #$40
	bne     L004A
	dey
	lda     (sp),y
	bne     L004A
;
; beepAPU(1);
;
	tya
	jsr     pusha
	jsr     _beepAPU
;
; if (joy == JOY_A && old_joy == 0) {
;
L004A:	ldy     #$02
	lda     (sp),y
	cmp     #$80
	bne     L0050
	dey
	lda     (sp),y
	bne     L0050
;
; beepEVD(1);
;
	tya
	jsr     pusha
	jsr     _beepEVD
;
; if ((joy & JOY_LEFT) && !(old_joy & JOY_LEFT)) {
;
L0050:	ldy     #$02
	lda     (sp),y
	and     #$02
	beq     L005D
	dey
	lda     (sp),y
	and     #$02
	bne     L005D
;
; master_vol--;
;
	dey
	lda     (sp),y
	sec
	sbc     #$01
	sta     (sp),y
;
; if (master_vol > 200)master_vol = 199;
;
	cmp     #$C9
	bcc     L005D
	lda     #$C7
	sta     (sp),y
;
; if ((joy & JOY_RIGHT) && !(old_joy & JOY_RIGHT)) {
;
L005D:	ldy     #$02
	lda     (sp),y
	and     #$01
	jeq     L003A
	dey
	lda     (sp),y
	and     #$01
	jne     L003A
;
; master_vol++;
;
	dey
	lda     (sp),y
	clc
	adc     #$01
	sta     (sp),y
;
; if (master_vol > 200)master_vol = 0;
;
	cmp     #$C9
	jcc     L003A
	tya
	sta     (sp),y
;
; }
;
	jmp     L003A

.endproc

; ---------------------------------------------------------------
; void __near__ main (void)
; ---------------------------------------------------------------

.segment	"CODE"

.proc	_main: near

.segment	"CODE"

;
; u8 *exram = (u8 *) 0x5C00;
;
	jsr     decsp2
	ldx     #$5C
	lda     #$00
	jsr     pushax
;
; u8 *chr_banks = (u8 *) 0x55120;
;
	ldx     #$51
	lda     #$20
	jsr     pushax
;
; CHR_MODE = 0;
;
	jsr     decsp1
	lda     #$00
	sta     $5101
;
; NT_MAP = 0x80;
;
	lda     #$80
	sta     $5105
;
; EXRAM_MODE = 0;
;
	lda     #$00
	sta     $5104
;
; FILL_TILE = 'E';
;
	lda     #$45
	sta     $5106
;
; FILL_COLOR = 0xff;
;
	lda     #$FF
	sta     $5107
;
; for (i = 0; i < 12; i++)chr_banks[i] = 0;
;
	ldx     #$00
	txa
L01C0:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	bne     L0085
	dey
	lda     (sp),y
	cmp     #$0C
L0085:	bcs     L007F
	ldy     #$06
	jsr     ldaxysp
	clc
	ldy     #$01
	adc     (sp),y
	sta     ptr1
	txa
	iny
	adc     (sp),y
	sta     ptr1+1
	lda     #$00
	tay
	sta     (ptr1),y
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C0
;
; gfx_init();
;
L007F:	ldy     #$00
	jsr     _gfx_init
;
; ppuSetAddr(0x3F03);
;
	ldx     #$3F
	lda     #$03
	jsr     pushax
	jsr     _ppuSetAddr
;
; PPU_DATA = 0x27; //0x05;
;
	lda     #$27
	sta     $2007
;
; ppuSetAddr(0x3F07);
;
	ldx     #$3F
	lda     #$07
	jsr     pushax
	jsr     _ppuSetAddr
;
; PPU_DATA = 0x09;
;
	lda     #$09
	sta     $2007
;
; ppuSetAddr(0x3F0B);
;
	ldx     #$3F
	lda     #$0B
	jsr     pushax
	jsr     _ppuSetAddr
;
; PPU_DATA = 0x01;
;
	lda     #$01
	sta     $2007
;
; ppuSetAddr(0x3F0F);
;
	ldx     #$3F
	lda     #$0F
	jsr     pushax
	jsr     _ppuSetAddr
;
; PPU_DATA = 0x27;
;
	lda     #$27
	sta     $2007
;
; PPU_CTRL = 1 << 4; //select bg pattern
;
	lda     #$10
	sta     $2000
;
; ppuSetAddr(0x2000);
;
	ldx     #$20
	lda     #$00
	jsr     pushax
	jsr     _ppuSetAddr
;
; for (i = 0; i < 960; i++)PPU_DATA = ' ';
;
	ldx     #$00
	txa
L01C1:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	cmp     #$03
	bne     L00AB
	dey
	lda     (sp),y
	cmp     #$C0
L00AB:	bcs     L00A5
	lda     #$20
	sta     $2007
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C1
;
; for (i = 0; i < 64; i++)PPU_DATA = 0;
;
L00A5:	ldx     #$00
	txa
L01C2:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	bne     L00B7
	dey
	lda     (sp),y
	cmp     #$40
L00B7:	bcs     L00B1
	lda     #$00
	sta     $2007
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C2
;
; for (i = 0; i < 960; i++)PPU_DATA = ' ';
;
L00B1:	ldx     #$00
	txa
L01C3:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	cmp     #$03
	bne     L00C3
	dey
	lda     (sp),y
	cmp     #$C0
L00C3:	bcs     L00BD
	lda     #$20
	sta     $2007
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C3
;
; for (i = 0; i < 64; i++)PPU_DATA = 0;
;
L00BD:	ldx     #$00
	txa
L01C4:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	bne     L00CF
	dey
	lda     (sp),y
	cmp     #$40
L00CF:	bcs     L00C9
	lda     #$00
	sta     $2007
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C4
;
; for (i = 0; i < 960; i++)PPU_DATA = ' ';
;
L00C9:	ldx     #$00
	txa
L01C5:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	cmp     #$03
	bne     L00DB
	dey
	lda     (sp),y
	cmp     #$C0
L00DB:	bcs     L00D5
	lda     #$20
	sta     $2007
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C5
;
; for (i = 0; i < 64; i++)PPU_DATA = 0;
;
L00D5:	ldx     #$00
	txa
L01C6:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	bne     L00E7
	dey
	lda     (sp),y
	cmp     #$40
L00E7:	bcs     L00E1
	lda     #$00
	sta     $2007
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C6
;
; for (i = 0; i < 960; i++)PPU_DATA = ' ';
;
L00E1:	ldx     #$00
	txa
L01C7:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	cmp     #$03
	bne     L00F3
	dey
	lda     (sp),y
	cmp     #$C0
L00F3:	bcs     L00ED
	lda     #$20
	sta     $2007
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C7
;
; for (i = 0; i < 64; i++) {
;
L00ED:	ldx     #$00
	txa
L01C8:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	bne     L00FF
	dey
	lda     (sp),y
	cmp     #$40
L00FF:	bcs     L00F9
;
; if (i == 8) {
;
	ldy     #$06
	lda     (sp),y
	bne     L0101
	dey
	lda     (sp),y
	cmp     #$08
	bne     L0101
;
; PPU_DATA = 0x45;
;
	lda     #$45
;
; continue;
;
	jmp     L01B4
;
; if (i == 16) {
;
L0101:	ldy     #$06
	lda     (sp),y
	bne     L0107
	dey
	lda     (sp),y
	cmp     #$10
	bne     L0107
;
; PPU_DATA = 0x2a;
;
	lda     #$2A
;
; continue;
;
	jmp     L01B4
;
; PPU_DATA = 0;
;
L0107:	lda     #$00
L01B4:	sta     $2007
;
; for (i = 0; i < 64; i++) {
;
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C8
;
; ppuSetAddr(0x2000 + 32);
;
L00F9:	ldx     #$20
	txa
	jsr     pushax
	jsr     _ppuSetAddr
;
; strCopy("SPLITTTTTTTTTTTTHHHH");
;
	lda     #<(L0001)
	ldx     #>(L0001)
	jsr     pushax
	jsr     _strCopy
;
; ppuSetAddr(0x2000 + 64);
;
	ldx     #$20
	lda     #$40
	jsr     pushax
	jsr     _ppuSetAddr
;
; for (i = 0; i < 16; i++)printHex(i);
;
	ldx     #$00
	txa
L01C9:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	bne     L011D
	dey
	lda     (sp),y
	cmp     #$10
L011D:	bcs     L0117
	ldy     #$05
	lda     (sp),y
	jsr     pusha
	jsr     _printHex
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01C9
;
; for (i = 0; i < 30; i++) {
;
L0117:	ldx     #$00
	txa
L01CA:	ldy     #$05
	jsr     staxysp
	ldy     #$06
	lda     (sp),y
	bne     L0128
	dey
	lda     (sp),y
	cmp     #$1E
L0128:	bcs     L0122
;
; ppuSetAddr(0x2000 + 1024 * 3 + i * 32);
;
	ldy     #$06
	jsr     ldaxysp
	jsr     shlax4
	jsr     shlax1
	sta     ptr1
	stx     ptr1+1
	lda     #$00
	clc
	adc     ptr1
	pha
	lda     #$2C
	adc     ptr1+1
	tax
	pla
	jsr     pushax
	jsr     _ppuSetAddr
;
; strCopy("HELL");
;
	lda     #<(L0001+21)
	ldx     #>(L0001+21)
	jsr     pushax
	jsr     _strCopy
;
; printHex(i);
;
	ldy     #$05
	lda     (sp),y
	jsr     pusha
	jsr     _printHex
;
; for (i = 0; i < 30; i++) {
;
	ldy     #$06
	jsr     ldaxysp
	jsr     incax1
	jmp     L01CA
;
; setScroll(0, 0);
;
L0122:	lda     #$00
	jsr     pusha
	jsr     pusha
	jsr     _setScroll
;
; gfxOn();
;
	ldy     #$00
	jsr     _gfxOn
;
; SPLIT_MODE = 0x80 | 0x00 | 16;
;
	lda     #$90
	sta     $5200
;
; SPLIT_BANK = 1;
;
	lda     #$01
	sta     $5202
;
; SPLIT_SCRL = 0;
;
	lda     #$00
	sta     $5201
;
; i = 0;
;
	tax
	ldy     #$05
	jsr     staxysp
;
; beepTest();
;
	jsr     _beepTest
;
; gfx_vsync();
;
L0143:	ldy     #$00
	jsr     _gfx_vsync
;
; while (joyRead() != 0);
;
L0145:	ldy     #$00
	jsr     _joyRead
	cmp     #$00
	bne     L0145
;
; while (joyRead() == 0);
;
L0146:	tay
	jsr     _joyRead
	cmp     #$00
	beq     L0146
;
; if (joyRead() == JOY_UP) {
;
	ldy     #$00
	jsr     _joyRead
	cmp     #$08
	bne     L014B
;
; i += 8;
;
	ldy     #$05
	ldx     #$00
	jsr     addeqysp
;
; if (joyRead() == JOY_DOWN) {
;
L014B:	ldy     #$00
	jsr     _joyRead
	cmp     #$04
	bne     L014F
;
; i -= 8;
;
	ldx     #$00
	lda     #$08
	ldy     #$05
	jsr     subeqysp
;
; SPLIT_SCRL = i;
;
L014F:	ldy     #$05
	lda     (sp),y
	sta     $5201
;
; }
;
	jmp     L0143

.endproc

