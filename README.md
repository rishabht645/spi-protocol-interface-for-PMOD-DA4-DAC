
# SPI Protocol Interface for PMOD DA4 DAC

A hardware implementation of the SPI protocol to interface with the Digilent PMOD DA4 Digital-to-Analog Converter, written in Verilog. The design includes a fully functional SPI master, DAC initialization logic, and a finite state machine for data transmission.

---

## Table of Contents

- [Open Source Tools Used](#open-source-tools-used)
- [PMOD DA4 DAC](#pmod-da4-dac)
- [Design Overview](#design-overview)
- [RTL Schematic](#rtl-schematic)
- [FPGA Layout](#fpga-layout)
- [Running the Project](#running-the-project)

---

## Open Source Tools Used

- [Yosys](https://github.com/YosysHQ/yosys) : Verilog synthesis and netlist generation
- [netlistsvg](https://github.com/nturley/netlistsvg) : renders Yosys netlist as a visual SVG schematic
- [nextpnr](https://github.com/YosysHQ/nextpnr) : FPGA placement and routing with an interactive GUI
- [OSS CAD Suite](https://github.com/YosysHQ/oss-cad-suite-build) : bundles all of the above tools in a single suite for easy installation
- [Icarus Verilog](https://github.com/steveicarus/iverilog) : verilog synthesis, interfaceable with VScode
- [GTKwave](https://github.com/gtkwave/gtkwave) : viewing and examining waveforms
---

## PMOD DA4 DAC

<!-- Add an image of the PMOD DA4 board here -->

The Digilent PMOD DA4 is an 8-channel, 12-bit Digital-to-Analog Converter based on the AD5628 chip. It communicates over SPI and accepts 32-bit frames consisting of:

- 4-bit command field : specifies the operation (write, update, etc.)
- 4-bit address field : selects the DAC channel
- 12-bit data field : the analog value to output
- 8-bit padding : zero-filled

Before sending DAC data, the device requires a one-time initialization sequence to configure its internal reference voltage and operating mode.

---

## Design Overview

The system clock runs at 100MHz, which is divided down to 1MHz to serve as the SPI clock — this keeps the communication speed within the operating limits of the AD5628 DAC.

The top module `spi_pmod_da4` implements a 4-state FSM:

- `IDLE` - waits for the `st_wrt` signal, routes to INITIAL or DAC_DATA based on whether the DAC has been initialized
- `INITIAL` - sends the 32-bit DAC initialization frame (`0x08000001`) over MOSI
- `DAC_DATA` - prepares the 32-bit data frame (`{0x030, data_in, 0x00}`)
- `SEND_DATA` - serially transmits the data frame bit by bit, MSB first, with CS held low

---

## RTL Schematic

<!-- Add spi_pmod_da4_schematic.svg here -->

The RTL schematic was generated using [Yosys](https://github.com/YosysHQ/yosys) and [netlistsvg](https://github.com/nturley/netlistsvg). It shows the synthesized logic including the FSM state registers, multiplexers, adders, and output logic.

---

## FPGA Layout

<!-- Add nextpnr screenshot here -->

The design was placed and routed on a Lattice iCE40HX8K FPGA using [nextpnr](https://github.com/YosysHQ/nextpnr). The layout shows the physical placement of LUTs and flip-flops on the FPGA fabric along with the routing wires connecting them.

---

## Running the Project

### Prerequisites

1. Install OSS CAD Suite (includes Yosys and nextpnr)

Download the macOS archive (I'm on macOS, if you're on windows, install the windows x86 archive) from the [releases page](https://github.com/YosysHQ/oss-cad-suite-build/releases/latest) and extract it. 

Set the environment — run this every time you open a new terminal:
```bash
source ~/Downloads/oss-cad-suite/environment
```

Remove macOS quarantine if needed:
```bash
sudo xattr -rd com.apple.quarantine ~/Downloads/oss-cad-suite
```
1. Install Icarus Verilog
```bash
brew install icarus-verilog
```

2. Install GTKWave
```bash
brew install --cask gtkwave
```

3. Install Node.js

Download from [nodejs.org](https://nodejs.org) (LTS version).

4. Install netlistsvg
```bash
sudo npm install -g netlistsvg
```

---

### Run Simulation

Using [Icarus Verilog](https://github.com/steveicarus/iverilog):
```bash
iverilog -o sim.out spi_pmod_da4_design.v
vvp sim.out
```

View waveforms using [GTKWave](https://github.com/gtkwave/gtkwave):
```bash
gtkwave dump.vcd
```

---

### Generate RTL Schematic

```bash
source ~/Downloads/oss-cad-suite/environment
cd rtl/
yosys -p "read_verilog spi_pmod_da4_design.v; hierarchy -top spi_pmod_da4; proc; write_json spi_pmod_da4.json" spi_pmod_da4_design.v
netlistsvg spi_pmod_da4.json -o spi_pmod_da4.svg
open spi_pmod_da4.svg
```

---

### Run FPGA Placement and Routing

```bash
source ~/Downloads/oss-cad-suite/environment
cd rtl/
yosys -p "synth_ice40 -top spi_pmod_da4 -json spi_pmod_da4.json" spi_pmod_da4_design.v
nextpnr-ice40 --hx8k --json spi_pmod_da4.json --pcf-allow-unconstrained --gui
```

Then in the nextpnr console at the top, click the "PACK", "PLACE" and "ROUTE" buttons in that order

<img width="444" height="131" alt="Screenshot 2026-05-23 at 8 49 47 AM" src="https://github.com/user-attachments/assets/9bb29245-dfac-4993-9b57-d5a9750182df" />

---

## License

MIT License
