BOARD=tangnano9k
FAMILY=GW1N-9C
DEVICE=GW1NR-LV9QN88PC6/I5
TOP=top
SYNTH_FLAGS ?= -noabc9 -nowidelut
NEXTPNR_FLAGS ?= --placer heap --seed 7
SERIAL_PORT ?= COM9
BAUDRATE ?= 115200
NONCE_CHUNK_SIZE ?= 524288
JOB_TTL_SEC ?= 20
LOG_INTERVAL_SEC ?= 5
STOP_ON_FOUND ?= true
GENESIS_JOB_ID ?= 1
PROBE_TIMEOUT ?= 5.0
TOOLBIN := /c/Users/wolfpack/Downloads/tang_nano_9k/oss-cad-suite/bin
TOOLLIB := /c/Users/wolfpack/Downloads/tang_nano_9k/oss-cad-suite/lib

export PATH := $(TOOLBIN):$(TOOLLIB):$(PATH)

YOSYS := $(TOOLBIN)/yosys.exe
NEXTPNR := $(TOOLBIN)/nextpnr-himbaechel.exe
GOWIN_PACK := $(TOOLBIN)/gowin_pack.exe
OPENFPGA := $(TOOLBIN)/openFPGALoader.exe
IVERILOG := $(TOOLBIN)/iverilog.exe
VVP := $(TOOLBIN)/vvp.exe
BITSTREAM ?= top.fs
GOWIN_BUILD_SCRIPT ?= build_gowin.tcl
GOWIN_SH ?= /c/Gowin/Gowin_V1.9.11.03_Education_x64/IDE/bin/gw_sh.exe
MINER_CE_DIVISOR ?= 2

RTL=$(wildcard rtl/*.v)

all: verify $(BITSTREAM)

verify: sim_all 

top.json: $(RTL)
	$(YOSYS) -p "read_verilog $(RTL); synth_gowin $(SYNTH_FLAGS) -top $(TOP) -json top.json"

top_pnr.json: top.json tangnano9k.cst
	$(NEXTPNR) --json top.json --write top_pnr.json --device $(DEVICE) --vopt family=$(FAMILY) --vopt cst=tangnano9k.cst $(NEXTPNR_FLAGS)

top.fs: top_pnr.json
	$(GOWIN_PACK) -d $(FAMILY) -o top.fs top_pnr.json

gowin_build:
	"$(GOWIN_SH)" $(GOWIN_BUILD_SCRIPT)
	rm -f top.fs
	cp impl/pnr/bitcoin-miner-gowin-slow.fs top.fs

flash: $(BITSTREAM)
	$(OPENFPGA) -b $(BOARD) $(BITSTREAM) -f

sram: $(BITSTREAM)
	$(OPENFPGA) -b $(BOARD) -m $(BITSTREAM)

sim_nonce: rtl/hash256d_pipeline.v rtl/nonce_scanner.v sim/tb_nonce_scanner.v
	$(IVERILOG) -g2012 -o sim/tb_nonce_scanner.out rtl/hash256d_pipeline.v rtl/nonce_scanner.v sim/tb_nonce_scanner.v
	$(VVP) sim/tb_nonce_scanner.out


sim_all: sim_nonce

clean:
	rm -f top.json top_pnr.json top.fs sim/*.out

.PHONY: all verify flash sram clean sim_nonce sim_multi sim_hash sim_found_match sim_genesis_found sim_uart_rx sim_uart_tx sim_uart_link sim_uart_top_ack sim_uart_top_genesis sim_all host_test host_regress pool_smoke fpga_smoke ping fpga_mine_easy_block fpga_genesis fpga_debug serial_ports run run_stub gowin_build
.INTERMEDIATE: top.json top_pnr.json
