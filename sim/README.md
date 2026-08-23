# Hack CPU for Tang Nano 9K FPGA - NAND2Tetris

This is a port of the [nand2Tetris.org]() Hack CPU written in Verilog 
and set up to run on the Tang Nano 9K using GOWIN.


## Prerequisites

1. [YosysHQ OSS CAD Suite](https://github.com/yosyshq/oss-cad-suite-build)
2. [GOWIN FPGA Designer](https://www.gowinsemi.com/en/support/download_eda/)
3. 


## Build

```
make
```

## Simulate / Test Bench

```
make sim_all
```

## Make a Movie

![Pong](sim/pong-movie.gif)

> WARNING: Command takes up to 10 minutes!

```
make movie
```

## Flash FPGA

To save in flash (permanent):
```
make flash
```

or to save in RAM (wont survive reboot):

```
make sram
```

## Install Apps

### Pong



## FPGA Wiring
