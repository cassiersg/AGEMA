# AGEMA
Automated Generation of Masked Hardware

This repository contains the source code (C++) and hardware implementations (HDL files) for the paper "[Automated Generation of Masked Hardware](https://doi.org/10.46586/tches.v2022.i1.589-629)".

## Features
AGEMA is a framework written in C++ which partially relies on Reduced Ordered Binary Decision Diagrams (ROBDDs) and ABC library.
This framework allows to construct provably-secure masked hardware implementations from an unprotected implementation (given as a Verilog design file).
It supports the following processing methods:
- naive
- AIG
- BDDsylvan
- BDDcudd
- ANF

It also supports different masking scheme with respect to the used gadgets:
- HPC1
- HPC2
- HPC3
- GHPC
- GHPCLL
- COMAR
- LMDPL

For more information about their meaning and difference, please see the paper.

## Contact and Support
Please contact Amir Moradi (amir.moradi@rub.de) if you have any questions, comments, if you found a bug that should be corrected, or if you want to reuse the framework or parts of it for your own research projects.

## Build Instructions
Please follow the instructions below to build the AGEMA framework:

1. Download and include the [Boost Graph Library (BGL)](https://www.boost.org/doc/libs/1_73_0/libs/graph/doc/index.html).
2. Update the `BOOST` variable in the makefile with the path to your copy of BGL.
6. Clone and build the [ABC](https://github.com/berkeley-abc/abc) library.
7. Copy (replace) the ABC library `libabc.so` to `/lib/`
8. Clone and build the [CUDD](https://github.com/ivmai/cudd) library.
9. Copy (replace) the CUDD library `libcudd.so` to `/lib/`
10. Clone and build the [Sylvan](https://github.com/trolando/sylvan) BDD library. Make sure you check out 5e9da9782885f6215f6b509ac250212df30aaf70.
12. Copy (replace) the Sylvan library `libsylvan.so` to `/lib/`
13. Copy (replace) the Sylvan header files to `/inc/sylvan/`
14. run `make clean` and then `make release` to build AGEMA

## Quick Start
Build the AGEMA framework using the instructions above, and run AGEMA by entering `./bin/release/AGEMA -h`. It shows a help and possible options for the command line.

## Input (Design)
AGEMA reads a Verilog netlist of the unprotected design. When the design in VHDL/Verilog is written at the behavioral level, it should be first synthesized by a synthesize, e.g., Design Compiler or Yosys. The resulting netlist should be flattened and should use certain cells. See the instructions below for each synthesizer.

### Synopsis Design Compiler

You can use NANGate 45 standard cell library for the synthesis. The following commands (for the synthesis script) can be used to restrict the resulting netlist to only those cells which are supported by AGEMA.

```
set_dont_use [get_lib_cells NangateOpenCellLibrary/FA*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/HA*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/AOI*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/OAI*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/CLKBUF*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/OR3*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/OR4*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/OR5*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/NOR3*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/NOR4*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/NOR5*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/XNOR3*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/XNOR4*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/XNOR5*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/XOR3*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/XOR4*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/XOR5*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/AND3*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/AND4*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/AND5*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/NAND3*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/NAND4*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/NAND5*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/BUF*]
set_dont_use [get_lib_cells NangateOpenCellLibrary/SDFF_X*]
```

The flowing command can be used to force the synthesizer to compile and keep the hierarchy and make a non-flattened netlist of the design.

```
compile_ultra -no_autoungroup -no_boundary_optimization
```

The resulting netlist is non-flattended and flip-flops in NANGage 45, e.g., DFF_X1, has two outputs Q and QN. Since AGEMA has difficulties to handle the flip-flops when both outputs are used, the resulting netlist should be edited by replacing all DFF_X1 modules by MyDFF.
The edited (yet non-flattended) netlist together with the `MyDFF.v` file (avaiable in the folder `./AGEMA/DesignCompiler/`) should be recompiled using the the following command.

```
compile_ultra -no_autoungroup -no_boundary_optimization
ungroup -all -flatten
```

This generates a flattened netlist where the QN outputs of flip-flops are not used and can be processed by AGEMA. In the current version (as of 11 Dec 2022), the final netlist must not be flattened. Hence the command ```ungroup -all -flatten``` is not necessary.

### Yosys

AGEMA can also parse the netlist generated by open-source synthesizer [Yosys](http://www.clifford.at/yosys/). The generated netlist should be flattened and based on a certain library whose cells are supported by AGEMA. As reference, we refer to folder `./AGEMA/Yosys/` where an exemplary synthesis script in addition to a customized library are given.

### Recommendation

It is highly recommended to hardcode multiplexers and XORs in the behavioral design. Since the hierarchy is kept when the netlist is generated (see above the descriptions for Design Compiler and Yosys), this forces the synthesizer to not merge multiplexers and XORs with other modules. This way, the resulting netlist contains MUX and XORs when placed. This has a direct effect on the efficiency of the masked design which is generated by AGEMA, since XORs on masked data do not require any register stages and MUXes on masked data which are controlled by an insecure signal can also be realized by normal multiplexers without any register stages. The provided cases studies include several cases where MUXes and XORs are hardcoded.

### Verilog attribute syntax

AGEMA needs to understand the role of each primary input of the given design. For this, all input signals of the Verilog netlist have to be annotated using custom attributes. In general, the annotation should use the following Verilog syntax:

```
(* attribute *) input inputname;
/* ... */

(* attribute *) output outputname;
/* ... */
```

#### AGEMA attributes

In particular, the verilog parser observes any attribute preceded by the AGEMA keyword, i.e., following the syntax: `(* AGEMA="attribute" *)`. In addition, the following different attributes are defined and recognized by the parser:

| attribute | description |
| --------- | ----------- |
| *clock*       | Keyword for identification of the clock signal. |
| *reset*       | Keyword for identification of the reset signal. |
| *constant*    | Keyword for identification of any other control signals or any input which should not be presented in a masked form. |
| *secure*      | Keyword for identification of signals which should be secured, i.e., represented in a masked form. |

##### Example

This example says that the plaintext should be masked but not the key, i.e., key masking is not desired.

```
(* AGEMA = "secure" *)    input [63:0]   plaintext;
(* AGEMA = "constant" *)  input [127:0]  key;
(* AGEMA = "clock" *)     input          clock;
(* AGEMA = "reset" *)     input          rst;
```

## Input (Library)

In addition to the given netlist, AGEMA needs a library file to understand the meaning of the cells used in the netlist file.
A library file is provided in `./AGEMA/cell/Library.txt` which covers all cells in the NANGate 45 (Design Compiler) and the custom library (Yosys) as well as HPC1, HPC2, GHPC and GHPCLL gadgets. The structure of the library file and how to edit as given inside the aforementioned file.

## Example

An example design is provided in the folder `./AGEMA/example/`.
It is a nibbel-serial implementation of the PRESENT-80 encryption function. The behavioural description of the design is given in the folder `./AGEMA/example/behavioral/`.
Using the above description, the design was synthesized by Design Compiler, and the resulting netlist is given in `./AGEMA/example/PRESENT.v`.

AGEMA can be used to process this design using the following command

`./bin/release/AGEMA -lf ./cell/Library.txt -df ./example/PRESENT.v -mn PRESENT -mt naive -sc HPC2 -so 1`

It takes the aforementioned libary file and the above explained design file. It looks for a module called `PRESENT` and processes the deign using `naive` processing method and `HPC2` gadgets as the masking scheme with `d=1` as the order of masking, i.e., first-order SCA security. Since option `-cg` is not given, it generates a pipeline design.
The resulting file is generated as `PRESENT_HPC2_Pipeline_d1.v`. The added number register stages and the required fresh masks are written inside the generated Verilog file.

The generated design requires the gadgets to be functional. All gadgets that AGEMA currently supports are given in the folder `./AGEMA/CaseStudies/0_Common_Gadgets/`.

## Troubleshooting

Here are some common issues you may encounter during execution along with possible fixes.

### Shared libraries (libsylvan.so)
In case you get an error message similar to:

```
./bin/release/AGEMA: error while loading shared libraries: libsylvan.so: cannot open shared object file: No such file or directory
```

please export the `/lib` directory to your linker library path, e.g., using `export LD_LIBRARY_PATH=``pwd``/lib` before executing the binary.

## Licensing
Copyright (c) 2021, David Knichel, Amir Moradi, Nicolai Müller, Pascal Sasdrich

All rights reserved.

Please see `LICENSE` for further license instructions.

## Publications
D. Knichel, A. Moradi, N. Müller, P. Sasdrich (2021): "[Automated Generation of Masked Hardware](https://doi.org/10.46586/tches.v2022.i1.589-629)" (TCHES 2022, Issue 1) [(pre-print)](https://eprint.iacr.org/2021/569.pdf)

D. Knichel, A. Moradi (2022): "[Composable Gadgets with Reused Fresh Masks, First-Order Probing-Secure Hardware Circuits with only 6 Fresh Masks](https://doi.org/10.46586/tches.v2022.i3.114-140)" (TCHES 2022, Issue 3)  [(pre-print)](https://eprint.iacr.org/2023/1141.pdf)

D. Knichel, A. Moradi (2022): "[Low-Latency Hardware Private Circuits](https://dl.acm.org/doi/abs/10.1145/3548606.3559362)" (ACM CCS 2022) [(pre-print)](https://eprint.iacr.org/2022/507.pdf)

N. Müller, S. Meschkov, D. R. E. Gnad, M. B. Tahoori, A. Moradi (2023): "[Automated Masking of FPGA-Mapped Designs](https://link_will_be_added_later)" (FPL 2023)
