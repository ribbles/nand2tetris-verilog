set_device GW1NR-LV9QN88PC6/I5 -device_version C

add_file rtl/alu.v
add_file rtl/computer.v
add_file rtl/cpu.v
add_file rtl/fetch_fsm.v
add_file rtl/flash608k_primitive.v
add_file rtl/flash608k_reader.v
add_file rtl/hdmi.v
add_file rtl/rom_flash.v
add_file rtl/keyboard.v
add_file rtl/memory.v
add_file rtl/pc.v
add_file rtl/ram16k.v
add_file rtl/screen.v
add_file rtl/top.v

add_file ip/dvi_tx.v

add_file tangnano9k.cst
add_file tangnano9k.sdc

set_option -top_module top
set_option -verilog_std v2001
set_option -output_base_name top

run all
