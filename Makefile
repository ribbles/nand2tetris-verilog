# Tang Nano 9K / nand2tetris Hack computer build and test targets.
# Run these from Git Bash on Windows: make sim_all, make bitstream, make sram.

BOARD          ?= tangnano9k
FAMILY         ?= GW1N-9C
DEVICE         ?= GW1NR-LV9QN88PC6/I5
TOP            ?= top
TOOLBIN        ?= /c/Users/wolfpack/Downloads/tang_nano_9k/oss-cad-suite/bin
TOOLLIB        ?= /c/Users/wolfpack/Downloads/tang_nano_9k/oss-cad-suite/lib

export PATH := $(TOOLBIN):$(TOOLLIB):$(PATH)

YOSYS          ?= $(TOOLBIN)/yosys.exe
NEXTPNR        ?= $(TOOLBIN)/nextpnr-himbaechel.exe
GOWIN_PACK     ?= $(TOOLBIN)/gowin_pack.exe
OPENFPGA       ?= $(TOOLBIN)/openFPGALoader.exe
IVERILOG       ?= $(TOOLBIN)/iverilog.exe
VVP            ?= $(TOOLBIN)/vvp.exe
GOWIN_SH       ?= /c/Gowin/Gowin_V1.9.11.03_Education_x64/IDE/bin/gw_sh.exe
GOWIN_OUTPUT   ?= impl/pnr/nand2tetris.fs
GOWIN_SH       ?= /c/Gowin/Gowin_V1.9.11.03_Education_x64/IDE/bin/gw_sh.exe
GOWIN_OUTPUT   ?= impl/pnr/nand2tetris.fs

SYNTH_FLAGS    ?= -noabc9 -nowidelut
NEXTPNR_FLAGS  ?= --placer heap --seed 7
BITSTREAM      ?= top.fs
BUILD_DIR      ?= build
PROGRAM        ?= sim/hack/Pong.hack
RTL            := $(wildcard rtl/*.v)

.DEFAULT_GOAL := all

all: verify bitstream

verify: sim_all

bitstream: $(BITSTREAM)

Prog.hack: $(PROGRAM)
	@cp $< $@

top.json: $(RTL) Prog.hack
	$(YOSYS) -p "read_verilog -sv -D SYNTHESIS $(RTL); synth_gowin $(SYNTH_FLAGS) -top $(TOP) -json $@"

top_pnr.json: top.json tangnano9k.cst
	$(NEXTPNR) --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=tangnano9k.cst $(NEXTPNR_FLAGS)

$(BITSTREAM): top_pnr.json
	$(GOWIN_PACK) -d $(FAMILY) -o $@ $<

# Program the persistent flash or the volatile SRAM respectively.
flash: $(BITSTREAM)
	$(OPENFPGA) -b $(BOARD) -f $<

sram: $(BITSTREAM)
	$(OPENFPGA) -b $(BOARD) -m $<

$(BUILD_DIR):
	mkdir -p $@

define SIM_RULE
sim_$(1): | $(BUILD_DIR)
	cd sim && $(IVERILOG) -g2012 -DSIMULATION -s tb_$(1) -o ../$(BUILD_DIR)/tb_$(1).out $(2) tb_$(1).v
	cd sim && $(VVP) ../$(BUILD_DIR)/tb_$(1).out
endef

$(eval $(call SIM_RULE,alu,../rtl/alu.v))
$(eval $(call SIM_RULE,cpu,../rtl/alu.v ../rtl/pc.v ../rtl/cpu.v))
$(eval $(call SIM_RULE,keyboard,../rtl/keyboard.v))
$(eval $(call SIM_RULE,memory,../rtl/ram16k.v ../rtl/screen.v ../rtl/keyboard.v ../rtl/memory.v))
$(eval $(call SIM_RULE,pc,../rtl/pc.v))
$(eval $(call SIM_RULE,ram16k,../rtl/ram16k.v))
$(eval $(call SIM_RULE,rom32k,../rtl/rom32k.v))
$(eval $(call SIM_RULE,screen,../rtl/screen.v))
$(eval $(call SIM_RULE,flash_model,flash608k_model.v))
$(eval $(call SIM_RULE,flash_primative,flash608k_model.v ../rtl/flash608k_primitive.v))
$(eval $(call SIM_RULE,flash_reader,flash608k_model.v ../rtl/flash608k_primitive.v ../rtl/flash608k_reader.v))

sim_all: sim_alu sim_cpu sim_keyboard sim_memory sim_pc sim_ram16k sim_rom32k sim_screen sim_flash_reader

clean:
	rm -rf $(BUILD_DIR)
	rm -f top.json top_pnr.json $(BITSTREAM) Prog.hack

.PHONY: all verify bitstream gowin_bitstream gowin_build flash sram clean sim_all sim_alu sim_cpu sim_keyboard sim_memory sim_pc sim_ram16k sim_rom32k sim_screen sim_flash_reader
.INTERMEDIATE: top.json top_pnr.json
# Alternative bitstream flow using the installed Gowin IDE.
gowin_bitstream: Prog.hack build_gowin.tcl tangnano9k.cst
	"$(GOWIN_SH)" build_gowin.tcl
	cp "$(GOWIN_OUTPUT)" "$(BITSTREAM)"

gowin_build: gowin_bitstream
