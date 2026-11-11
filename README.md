# EC551 Programming Assignment 2 — Hardware Synthesis

**Course:** EC551 Advanced Digital Design with Verilog and FPGAs  
**Semester:** Fall 2026  
**Professor:** Douglas Densmore  
**Target Board:** Nexys A7 (Artix-7 XC7A100T)  
**Development Tools:** Python 3, Verilog, AMD Vivado 2024.1

## 1. Project Overview

This project implements a simplified High-Level Synthesis (HLS) tool that converts arithmetic equations into synthesizable Verilog RTL.

The complete workflow includes:

1. Parsing arithmetic equations from a text file.
2. Converting assignments into Static Single Assignment (SSA) form.
3. Building a Directed Acyclic Graph (DAG) of operation dependencies.
4. Scheduling operations using five scheduling strategies.
5. Generating resource-shared Verilog datapath and FSM logic.
6. Simulating and deploying the design on an FPGA.

The hardware demonstration supports button-controlled execution, arithmetic unit observation, result selection, and completion indication.

## 2. Repository Structure

| File or Folder | Purpose |
|---|---|
| `equations.txt` | Input arithmetic equations |
| `parser.py` | Parses and validates equations |
| `ssa.py` | Converts equations into SSA |
| `dag.py` | Builds the dependency DAG |
| `scheduler.py` | Implements five scheduling strategies |
| `main.py` | Runs the HLS front end |
| `verilog_generator.py` | Original Verilog generator |
| `verilog_generator_step.py` | Step-controlled RTL generator |
| `generated_step_auto.v` | Automatically generated RTL example |
| `fpga/generated_step.v` | Manually written step-controlled reference |
| `fpga/button_step.v` | Button synchronization and debouncing |
| `fpga/hls_fpga_top.v` | Nexys A7 FPGA integration |
| `rtl/` | Arithmetic functional-unit modules |
| `tb/` | Verilog simulation testbenches |
| `tests/` | Python unit tests |
| `schedule.json` | Generated scheduling information |

## 3. Input Format

The tool accepts up to 20 arithmetic equations, one equation per line.

Supported operations are addition, subtraction, and multiplication.

Example:

```text
X=A+B
Y=X+A
Z=X-B
Q=B*Z
```

Variables may be reassigned. SSA conversion creates unique versions automatically.

The assignment assumes that arithmetic expressions do not produce negative results.

## 4. HLS Architecture

**Parsing:** The parser extracts the destination, two operands, and arithmetic operator.

**SSA Conversion:** Reassigned variables receive unique names such as `X_1` and `X_2`.

**DAG Construction:** Each arithmetic operation becomes a node, and directed edges represent data dependencies.

**Scheduling:** The scheduler assigns operations to clock cycles while preserving dependencies and, when selected, respecting functional-unit resource limits.

**RTL Generation:** The generator produces arithmetic units, operand multiplexers, intermediate registers, and an FSM controller.

**FPGA Runtime:** The FPGA uses a debounced button pulse to advance the FSM by one state.

## 5. Supported Scheduling Modes

| Scheduling Mode | Description |
|---|---|
| ASAP | As Soon As Possible |
| ALAP | As Late As Possible |
| Constrained ASAP | ASAP with hardware resource limits |
| Constrained ALAP | ALAP with resource limits and a deadline |
| Custom | Critical-path-first scheduling |

For the default example:

| Mode | Observed Latency |
|---|---:|
| ASAP | 3 cycles |
| ALAP (deadline 5) | 5 cycles |
| Constrained ASAP | 3 cycles |
| Constrained ALAP (deadline 5) | 5 cycles |
| Custom | 3 cycles |

## 6. How to Run

Run all commands from the repository root directory.

### Generate an ASAP Schedule

```bash
python main.py equations.txt --mode asap --export-ssa
```

This generates `schedule.json` and exports the SSA representation.

### Generate Step-Controlled Verilog

```bash
python verilog_generator_step.py schedule.json --output generated_step_auto.v
```

### Resource-Constrained Scheduling

```bash
python main.py equations.txt --mode constrained-asap --adders 1 --subtractors 1 --multipliers 1
```

### ALAP Scheduling

```bash
python main.py equations.txt --mode alap --deadline 5
```

### Run Python Tests

```bash
python -m unittest discover -s tests -v
```

### Test Different Equations

Edit a separate input file and rerun the HLS tool.

For example:

```bash
python main.py equations_extra.txt --mode constrained-asap --output extra_schedule.json
python verilog_generator_step.py extra_schedule.json --output generated_extra.v --module generated_extra_circuit
```

## 7. FPGA Hardware Design

The FPGA implementation uses the Nexys A7 board with a 100 MHz clock.

The `button_step.v` module synchronizes and debounces the physical button signal, generating a step pulse for each valid press.

The generated FSM changes states only when it receives a step pulse.

### Switch and Button Mapping

| FPGA Control | Function |
|---|---|
| SW7–SW4 | Input A |
| SW11–SW8 | Input B |
| SW3–SW2 | Select output X, Y, Z or Q |
| SW1–SW0 | Select arithmetic unit type |
| SW12 | Enable functional-unit observation |
| SW13 | Display Done status |
| SW15–SW14 | Functional-unit index |
| BTNC | Step |
| BTNU | Reset |

### Example Calculation

For A = 12 and B = 5:

| Variable | Result |
|---|---:|
| X = A+B | 17 |
| Y = X+A | 29 |
| Z = X−B | 12 |
| Q = B×Z | 60 |

The first button press enters Cycle 1, and subsequent presses execute scheduled operations.

Functional-unit observation displays the current combinational output of the selected unit.

## 8. Verification Results

### Python Tests

Three Python unit tests passed.

All five scheduling modes successfully generated schedule files for the example equations.

An additional reassignment example generated a four-cycle resource-constrained schedule and Verilog output.

### Vivado Simulation

- Step-controlled circuit: 8/8 checks passed.
- Integrated FPGA top: 9/9 checks passed.
- Functional-unit observation: 16/16 checks passed.

### FPGA Hardware Testing

The design was synthesized, implemented, and programmed on the Nexys A7.

Physical hardware testing confirmed the results X = 17, Y = 29, Z = 12, and Q = 60.

Adder, subtractor, multiplier, and Done observation were also verified using the board switches and LEDs.


## 9. Known Limitations

- The demonstrated hardware uses 16-bit arithmetic.
- FPGA switch inputs are limited to four bits per input variable in the current top-level design.
- Arithmetic overflow can truncate results.
- Negative results are outside the assignment assumptions.
- The FPGA top-level wrapper is currently configured for inputs A and B and outputs X, Y, Z, and Q.
- New input/output variable names require a compatible FPGA wrapper.
- The HLS front end can generate new schedules and RTL, but arbitrary equation sets have not all been physically deployed on the FPGA.

## 10. Conclusion

This project demonstrates a simplified HLS workflow from arithmetic equations to resource-shared Verilog RTL.

The default design successfully passed functional simulation and was demonstrated on the Nexys A7 FPGA with button-controlled execution and observable arithmetic results.
## 11. Team Members and Contributions

This project was developed collaboratively by **Sirena** and **Benine**. Responsibilities were divided between the HLS software development and FPGA hardware integration, with both members contributing to the overall system.

### Benine — HLS Software Development

- Developed the high-level equation parser (`parser.py`) and Static Single Assignment conversion (`ssa.py`).
- Implemented Directed Acyclic Graph construction (`dag.py`) to represent arithmetic data dependencies.
- Developed the scheduling engine (`scheduler.py`), supporting ASAP, ALAP, Constrained ASAP, Constrained ALAP, and Custom scheduling.
- Developed the original automatic Verilog generator (`verilog_generator.py`) for resource-shared datapath and FSM generation.
- Contributed to software testing and verification of the HLS workflow.

### Sirena — FPGA Integration and Hardware Verification

- Developed and verified the step-controlled HLS circuit (`generated_step.v`).
- Extended the Verilog generation workflow to support button-controlled FSM execution (`verilog_generator_step.py`).
- Developed the FPGA top-level integration (`hls_fpga_top.v`), connecting the generated HLS circuit with physical buttons, switches, and LEDs.
- Implemented and tested functional-unit observation, output selection, and Done indication.
- Developed integration testbenches (`generated_step_tb.v` and `hls_fpga_top_tb.v`).
- Performed Vivado functional simulation, synthesis, implementation, and bitstream generation.
- Programmed and tested the design on the Nexys A7 FPGA board, verifying arithmetic results and step-by-step execution.

### Joint Contributions

- Integrated the HLS software and generated Verilog with the FPGA hardware system.
- Verified arithmetic operations, scheduling behavior, and the overall design workflow.
- Prepared the GitHub repository, project documentation, and the 30-minute demonstration plan.
- Collaborated on debugging and final system validation.