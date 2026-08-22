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

SYNTH_FLAGS    ?= -noabc9 -nowidelut
NEXTPNR_FLAGS  ?= --placer heap --seed 7
BITSTREAM      ?= top.fs
BUILD_DIR      ?= build
PROGRAM        ?= sim/hack/Pong.hack
RTL            := $(wildcard rtl/*.v)
SIM_FRAMES_DIR ?= sim/frames

.DEFAULT_GOAL := all

all: verify bitstream

verify: sim_all

bitstream: $(BITSTREAM)

Prog.hack: $(PROGRAM)
	@cp $< $@

top.json: $(RTL) Prog.hack
	$(YOSYS) -p "read_verilog -sv -D SYNTHESIS $(RTL) submodules/hdmi/hdmi/src/svo_hdmi.v $(wildcard submodules/hdmi/hdmi/src/hdmi/*.v) $(wildcard submodules/hdmi/hdmi/src/gowin_*/*.v); synth_gowin $(SYNTH_FLAGS) -top $(TOP) -json $@"

top_pnr.json: top.json tangnano9k.cst
	$(NEXTPNR) --json $< --write $@ --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=tangnano9k.cst $(NEXTPNR_FLAGS)

$(BITSTREAM): top_pnr.json
	$(GOWIN_PACK) -d $(FAMILY) -o $@ $<

# Alternative bitstream flow using the installed Gowin IDE.
gowin_bitstream: Prog.hack build_gowin.tcl tangnano9k.cst
	"$(GOWIN_SH)" build_gowin.tcl
	cp "$(GOWIN_OUTPUT)" "$(BITSTREAM)"

Prog.bin: Prog.hack scripts/hack2bin.py
	python scripts/hack2bin.py $< $@

flash: $(BITSTREAM)
	$(OPENFPGA) -b $(BOARD) -f $<

sram: $(BITSTREAM)
	$(OPENFPGA) -b $(BOARD) -m $<

flash_all: $(BITSTREAM) Prog.bin
	$(OPENFPGA) -b $(BOARD) -f $< --user-flash Prog.bin

$(BUILD_DIR):
	mkdir -p $@

$(SIM_FRAMES_DIR):
	mkdir -p $@

define SIM_RULE
sim_$(1): | $(BUILD_DIR) $(SIM_FRAMES_DIR)
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
$(eval $(call SIM_RULE,rom_flash,flash608k_model.v ../rtl/flash608k_primitive.v ../rtl/flash608k_reader.v ../rtl/rom_flash.v))
$(eval $(call SIM_RULE,computer,flash608k_model.v ../rtl/flash608k_primitive.v ../rtl/flash608k_reader.v ../rtl/rom_flash.v ../rtl/alu.v ../rtl/pc.v ../rtl/cpu.v ../rtl/ram16k.v ../rtl/screen.v ../rtl/keyboard.v ../rtl/memory.v ../rtl/fetch_fsm.v ../rtl/hdmi.v ../sim/hdmi_stubs.v ../rtl/computer.v))
$(eval $(call SIM_RULE,play_pong,flash608k_model.v ../rtl/flash608k_primitive.v ../rtl/flash608k_reader.v ../rtl/rom_flash.v ../rtl/alu.v ../rtl/pc.v ../rtl/cpu.v ../rtl/ram16k.v ../rtl/screen.v ../rtl/keyboard.v ../rtl/memory.v ../rtl/fetch_fsm.v ../rtl/hdmi.v ../sim/hdmi_stubs.v ../rtl/computer.v))

movie: | $(BUILD_DIR) $(SIM_FRAMES_DIR)
	rm -f $(SIM_FRAMES_DIR)/frame_*.pbm sim/pong_movie.gif
	$(MAKE) sim_play_pong
	python scripts/make_movie.py --frames-dir $(SIM_FRAMES_DIR) --output sim/pong_movie.gif

sim_all: sim_alu sim_cpu sim_keyboard sim_memory sim_pc sim_ram16k sim_rom32k sim_screen sim_flash_reader sim_rom_flash sim_computer

clean:
	rm -rf $(BUILD_DIR) $(SIM_FRAMES_DIR) sim/pong_movie.gif
	rm -f top.json top_pnr.json $(BITSTREAM) Prog.hack Prog.bin

.PHONY: all verify bitstream gowin_bitstream flash sram flash_all clean movie sim_all sim_alu sim_cpu sim_keyboard sim_memory sim_pc sim_ram16k sim_rom32k sim_screen sim_flash_reader sim_rom_flash sim_computer sim_play_pong sim_computer_compile
.INTERMEDIATE: top.json top_pnr.json
