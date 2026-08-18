set_device GW1NR-LV9QN88PC6/I5 -device_version C

add_folder rtlcd
add_file tangnano9k.cst

set_option -top_module top
set_option -verilog_std v2001
set_option -output_base_name nand2tetris

run all