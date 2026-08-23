# Tang Nano 9K / nand2tetris Hack computer build and test targets.
# Run these from Git Bash on Windows: make sim_all, make bitstream, make sram.

BOARD          ?= tangnano9k
FAMILY         ?= GW1N-9C
DEVICE         ?= GW1NR-LV9QN88PC6/I5
TOP            ?= top
TOOLBIN        ?= /c/Users/wolfpack/Downloads/tang_nano_9k/oss-cad-suite/bin
TOOLLIB        ?= /c/Users/wolfpack/Downloads/tang_nano_9k/oss-cad-suite/lib

export PATH := $(TOOLBIN):$(TOOLLIB):$(PATH)

OPENFPGA       ?= $(TOOLBIN)/openFPGALoader.exe
IVERILOG       ?= $(TOOLBIN)/iverilog.exe
VVP            ?= $(TOOLBIN)/vvp.exe
GOWIN_SH       ?= /c/Gowin/Gowin_V1.9.11.03_Education_x64/IDE/bin/gw_sh.exe
GOWIN_OUTPUT   ?= impl/pnr/top.fs

BITSTREAM      ?= top.fs
BUILD_DIR      ?= build
PROGRAM        ?= sim/hack/Pong.hack

RTL      	:= $(wildcard rtl/*.v)

SIM_FRAMES_DIR ?= sim/frames

.DEFAULT_GOAL := all

all: verify bitstream

verify: sim_all

bitstream: gowin_bitstream

# The current DVI transmitter is encrypted Gowin IP.  Build with the Gowin
# IDE flow; the former open-source HDMI/Yosys flow is intentionally removed.
gowin_bitstream: Prog.hack build_gowin.tcl tangnano9k.cst tangnano9k.sdc
	"$(GOWIN_SH)" build_gowin.tcl
	cp -f $(GOWIN_OUTPUT) $(BITSTREAM)

Prog.bin:
	python scripts/hack2bin.py Prog.bin $(PROGRAM)

flash:
	$(OPENFPGA) -b $(BOARD) -f top.fs --user-flash Prog.bin

$(BUILD_DIR):
	mkdir -p $@

$(SIM_FRAMES_DIR):
	mkdir -p $@

define SIM_RULE
sim_$(1): | $(BUILD_DIR)
	$(IVERILOG) -g2012 -DSIMULATION -s tb_$(1) -o $(BUILD_DIR)/tb_$(1).out $(2) sim/tb_$(1).v
	$(VVP) $(BUILD_DIR)/tb_$(1).out
endef

$(eval $(call SIM_RULE,alu,rtl/alu.v))
$(eval $(call SIM_RULE,cpu,rtl/alu.v rtl/pc.v rtl/cpu.v))
$(eval $(call SIM_RULE,keyboard,rtl/keyboard.v))
$(eval $(call SIM_RULE,memory,rtl/ram16k.v rtl/screen.v rtl/keyboard.v rtl/memory.v))
$(eval $(call SIM_RULE,pc,rtl/pc.v))
$(eval $(call SIM_RULE,ram16k,rtl/ram16k.v))
$(eval $(call SIM_RULE,screen,rtl/screen.v,sim/flash608k_model.v $(RTL)))
$(eval $(call SIM_RULE,flash_model,sim/flash608k_model.v))
$(eval $(call SIM_RULE,flash_primative,sim/flash608k_model.v rtl/flash608k_primitive.v))
$(eval $(call SIM_RULE,flash_reader,sim/flash608k_model.v $(RTL)))
$(eval $(call SIM_RULE,rom_flash,sim/flash608k_model.v $(RTL)))
$(eval $(call SIM_RULE,computer,sim/flash608k_model.v sim/hdmi_stubs.v $(RTL)))
$(eval $(call SIM_RULE,play_pong,sim/flash608k_model.v sim/hdmi_stubs.v $(RTL)))

movie: | $(BUILD_DIR) $(SIM_FRAMES_DIR)
	mkdir -p $(SIM_FRAMES_DIR)
	rm -f $(SIM_FRAMES_DIR)/frame_*.pbm sim/pong_movie.gif
	$(MAKE) sim_play_pong
	python scripts/make_movie.py --frames-dir $(SIM_FRAMES_DIR) --output sim/pong_movie.gif

sim_all: sim_alu sim_cpu sim_keyboard sim_memory sim_pc sim_ram16k sim_rom32k sim_screen sim_flash_reader sim_rom_flash sim_computer

clean:
	rm -rf $(BUILD_DIR) impl sim/*.vcd
	rm -f top.json top_pnr.json $(BITSTREAM) Prog.hack Prog.bin build.log

.PHONY: all verify bitstream gowin_bitstream flash sram flash_all clean movie sim_all sim_alu sim_cpu sim_keyboard sim_memory sim_pc sim_ram16k sim_rom32k sim_screen sim_flash_reader sim_rom_flash sim_computer sim_play_pong sim_computer_compile

