
# Kronos-32 — Out-of-Order Pipeline Engine

A fully functional out-of-order superscalar processor core implementing **Tomasulo's algorithm** with a custom 32-bit ISA, written in Verilog-2001. Built as Project 3 of a VLSI portfolio.

## Architecture Overview

┌─────────┐    ┌─────────┐

      │  FETCH  │───▶│ DECODE  │

      └─────────┘    └────┬────┘

                          │ Dispatch

          ┌───────────────┼────────────────┐

          ▼               ▼                ▼               ▼

      ┌──────┐       ┌──────┐         ┌──────┐        ┌──────┐

      │RS_ALU│       │RS_MUL│         │RS_LSU│        │RS_BRU│

      └──┬───┘       └──┬───┘         └──┬───┘        └──┬───┘

         │              │                │                │

      ┌──▼───┐       ┌──▼───┐         ┌──▼───┐        ┌──▼───┐

      │ ALU  │       │ MUL  │         │ LSU  │        │ BRU  │

      └──┬───┘       └──┬───┘         └──┬───┘        └──┬───┘

         └──────────────┴─────────────────┴───────────────┘

                                │

                          ┌─────▼─────┐

                          │CDB Arbiter│  (round-robin, 4-way)

                          └─────┬─────┘

                                │ Broadcast

                ┌───────────────▼───────────────┐

                │     ROB (Reorder Buffer)       │

                │  In-order commit + RAT lookup  │

                └───────────────────────────────┘

## Key Microarchitectural Features

| Feature | Implementation |

|---|---|

| Dispatch | Single-issue, in-order dispatch into 4 RS pools |

| Issue | Out-of-order issue when all operands ready |

| ROB depth | 15 entries (tags 0–14); TAG_NONE = 0xF = 15 |

| Register file | 16×32-bit (R0 hardwired 0) |

| CDB arbitration | Round-robin across ALU / MUL / LSU / BRU |

| RAT | Embedded in ROB — youngest-entry-wins combinational lookup |

| Branch resolution | BRU issues cond + target; flush on taken |

| Load ordering | LD blocked in RS_LSU while any unexecuted ST in ROB |

| CDB same-cycle capture | RS dispatch latches CDB data immediately if tag matches |

## Functional Units

| Unit | Latency | Operations |

|---|---|---|

| ALU | 1 cycle | ADD, ADDI, SUB, AND, OR, XOR, SHL, SHR |

| MUL | 3 cycles | MUL, DIV (pipelined) |

| LSU | 2 cycles | LD (load word), ST (store word) |

| BRU | 1 cycle | BEQ, BNE, BLT, JMP |

## ISA Format

All instructions are 32-bit fixed width:

[31:28] opcode (4 bits) [27:24] rd (4 bits) [23:20] rs1 (4 bits) [19:16] rs2 (4 bits) [15:0] imm (16 bits, sign-extended)

| Opcode | Mnemonic | Operation |

|---|---|---|

| 0x0 | ADD  | rd = rs1 + rs2 |

| 0x1 | ADDI | rd = rs1 + imm |

| 0x2 | SUB  | rd = rs1 - rs2 |

| 0x3 | AND  | rd = rs1 & rs2 |

| 0x4 | OR   | rd = rs1 \| rs2 |

| 0x5 | XOR  | rd = rs1 ^ rs2 |

| 0x6 | SHL  | rd = rs1 << rs2 |

| 0x7 | SHR  | rd = rs1 >> rs2 |

| 0x8 | MUL  | rd = rs1 × rs2 |

| 0x9 | DIV  | rd = rs1 / rs2 |

| 0xA | LD   | rd = mem[rs1 + imm] |

| 0xB | ST   | mem[rs1 + imm] = rs2 |

| 0xC | BEQ  | if rs1 == rs2: PC += imm |

| 0xD | BNE  | if rs1 != rs2: PC += imm |

| 0xE | BLT  | if rs1 < rs2:  PC += imm |

| 0xF | JMP  | PC += imm (unconditional) |

## Test Program

11000005 ADDI R1, R0, 5 # R1 = 5 12000003 ADDI R2, R0, 3 # R2 = 3 03120000 ADD R3, R1, R2 # R3 = 8 (RAW dep chain) 1400000a ADDI R4, R0, 10 # R4 = 10 (independent — issued OOO) 1e000003 ADDI R14, R0, 3 # R14 = 3 254e0000 SUB R5, R4, R14 # R5 = 7 (RAW on R4, R14) 16000004 ADDI R6, R0, 4 # R6 = 4 17000005 ADDI R7, R0, 5 # R7 = 5 88670000 MUL R8, R6, R7 # R8 = 20 (3-cycle multiply) 19000063 ADDI R9, R0, 99 # R9 = 99 (issued OOO past MUL stall) 1a000004 ADDI R10, R0, 4 # R10 = 4 (store base addr) 1b00002a ADDI R11, R0, 42 # R11 = 42 (store data) b0ab0000 ST R0, R10, R11 # mem[4] = 42 aca00000 LD R12, R10, 0 # R12 = mem[4] = 42 (load-after-store) 1d000001 ADDI R13, R0, 1 # R13 = 1 1f000002 ADDI R15, R0, 2 # R15 = 2 (BEQ operand, ≠ R13) c0df0008 BEQ R0, R13, R15, +8 # not taken — falls through 1f00004d ADDI R15, R0, 77 # R15 = 77 (proves BEQ not taken)

## Simulation Results

**Simulator:** Icarus Verilog 12.0 + GTKWave  
**Result: 6/6 tests PASSED**

| Test | Checks | Result |
|---|---|---|
| ADD dependency chain (R3=8) | RAW hazard via CDB forwarding | ✅ PASS |
| SUB with RAW deps (R5=7) | Multi-source forwarding | ✅ PASS |
| 3-cycle MUL (R8=20) | Pipelined multiply unit | ✅ PASS |
| OOO issue past MUL (R9=99) | True out-of-order execution | ✅ PASS |
| Load-after-Store (R12=42) | ST→mem, LD blocked, forwarded | ✅ PASS |
| BEQ not-taken (R15=77) | Branch prediction + flush | ✅ PASS |

## Bugs Fixed During Development

Three non-trivial bugs were debugged and fixed:

**1. TAG_NONE collision** — With `ROB_DEPTH=16`, valid tags are 0–15. `TAG_NONE=0xF=15` aliased with valid ROB entry 15, corrupting operand tracking for the 16th instruction. Fixed by setting `ROB_DEPTH=15` and adding explicit modulo-15 wrap on head/tail pointers.

**2. CDB same-cycle dispatch race** — When the CDB broadcast for a source tag arrived on the exact same cycle an instruction was dispatched, the new RS entry was not yet `busy`, so the snoop loop skipped it. The entry entered the RS with a stale `vj=0` and the tag was never rebroadcast. Fixed by adding same-cycle capture logic at dispatch in all four RS modules.

**3. Branch target width** — `bru_unit.v` sign-extended the 16-bit branch immediate to only 15 bits. Fixed to full 16-bit sign extension.

## Build & Simulate

```bash
# Compile and run (requires Icarus Verilog)
make sim

# Open waveform
make wave

# Clean build artifacts
make clean
```

Manual compile:
```bash
iverilog -g2012 -I rtl/ -o sim/ooo_sim \
    rtl/ooo_pkg.v rtl/regfile.v rtl/alu_unit.v rtl/mul_unit.v \
    rtl/bru_unit.v rtl/lsu_unit.v rtl/cdb_arbiter.v \
    rtl/rs_alu.v rtl/rs_mul.v rtl/rs_bru.v rtl/rs_lsu.v \
    rtl/rob.v rtl/fetch.v rtl/decode.v rtl/ooo_top.v tb/ooo_tb.v
vvp sim/ooo_sim
```

## Project Structure
kronos-ooo-pipeline/
├── rtl/
│   ├── ooo_pkg.v       # Global parameters and opcode defines
│   ├── ooo_top.v       # Top-level interconnect
│   ├── fetch.v         # PC + instruction memory (256×32)
│   ├── decode.v        # Decode, FU select, operand resolution, dispatch
│   ├── rob.v           # Reorder buffer + RAT (15 entries)
│   ├── regfile.v       # 16×32 register file, write-through bypass
│   ├── rs_alu.v        # ALU reservation station (4 entries)
│   ├── rs_mul.v        # MUL reservation station (2 entries)
│   ├── rs_lsu.v        # LSU reservation station (2 entries)
│   ├── rs_bru.v        # BRU reservation station (2 entries)
│   ├── alu_unit.v      # 1-cycle ALU
│   ├── mul_unit.v      # 3-cycle pipelined multiplier
│   ├── lsu_unit.v      # 2-cycle load/store unit with data memory
│   ├── bru_unit.v      # Branch resolution unit
│   └── cdb_arbiter.v   # 4-way round-robin CDB arbiter
├── tb/
│   ├── ooo_tb.v        # Self-checking testbench (6 tests)
│   ├── imem.hex        # 18-instruction test program
│   └── gen_imem.py     # Instruction assembler/hex generator
├── sim/                # Simulation outputs (gitignored)
├── synth/              # Synthesis outputs (gitignored)
├── Makefile
└── README.md

## Tools

- RTL: Verilog-2001
- Simulation: Icarus Verilog + GTKWave
- Development: WSL2 Ubuntu 24.04

## Portfolio

Part of an FPGA/VLSI portfolio by Gautam Suresh (B.E. Electronics, VLSI Design & Technology, CIT Chennai).

**Project 1:** [CRC Engine](https://github.com/vsgautam22/crc-engine) — RTL + formal verification (SymbiYosys/Z3) + OpenLane GDS (SKY130A, 0 DRC violations)

**Project 2:** [RISC-V RV32I Core](https://github.com/vsgautam22/riscv-core) — 5-stage pipeline, full hazard handling, 14/14 tests passed
