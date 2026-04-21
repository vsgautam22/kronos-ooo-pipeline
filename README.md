
# Kronos-32 — Out-of-Order Pipeline Engine

![Language](https://img.shields.io/badge/HDL-Verilog--2001-blue)
![Simulator](https://img.shields.io/badge/Simulator-Icarus%20Verilog%2012.0-9cf)
![Algorithm](https://img.shields.io/badge/Algorithm-Tomasulo's%20OOO-purple)
![Tests](https://img.shields.io/badge/Tests-6%2F6%20PASSED-brightgreen)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Overview

**Kronos-32** is a fully functional out-of-order superscalar processor core implementing **Tomasulo's algorithm** with a custom 32-bit ISA, written entirely in Verilog-2001. Built as Project 3 of a VLSI/FPGA portfolio, it demonstrates hardware-level instruction-level parallelism, dynamic scheduling, and speculative execution — the same principles found in modern out-of-order CPUs.

Unlike in-order pipelines, Kronos-32 dispatches instructions to reservation stations and issues them the moment all operands are available — regardless of program order. A 15-entry Reorder Buffer (ROB) enforces precise in-order commit and maintains correct architectural state. A 4-way round-robin Common Data Bus (CDB) arbiter broadcasts results to all waiting reservation stations simultaneously.

---

## System Architecture

┌──────────────────────────────────────────────┐
     │              FETCH STAGE                     │
     │   PC → imem[PC] → instruction register       │
     └─────────────────┬────────────────────────────┘
                       │
     ┌─────────────────▼────────────────────────────┐
     │              DECODE / DISPATCH                │
     │  Opcode decode → FU select → RAT lookup      │
     │  Operand resolution (ROB / regfile)           │
     └──────┬──────────┬──────────┬─────────┬───────┘
            │          │          │         │
     ┌──────▼──┐ ┌─────▼──┐ ┌────▼───┐ ┌──▼─────┐
     │ RS_ALU  │ │ RS_MUL │ │ RS_LSU │ │ RS_BRU │
     │ 4 entry │ │ 2 entry│ │ 2 entry│ │ 2 entry│
     └──────┬──┘ └─────┬──┘ └────┬───┘ └──┬─────┘
            │          │         │         │
     ┌──────▼──┐ ┌─────▼──┐ ┌────▼───┐ ┌──▼─────┐
     │   ALU   │ │  MUL   │ │  LSU   │ │  BRU   │
     │ 1 cycle │ │3 cycle │ │2 cycle │ │1 cycle │
     └──────┬──┘ └─────┬──┘ └────┬───┘ └──┬─────┘
            └──────────┴─────────┴─────────┘
                             │
               ┌─────────────▼─────────────┐
               │      CDB ARBITER           │
               │  Round-robin 4-way mux     │
               └─────────────┬─────────────┘
                             │  Broadcast to all RS + ROB
               ┌─────────────▼─────────────┐
               │    REORDER BUFFER (ROB)    │
               │  15 entries, in-order      │
               │  commit + embedded RAT     │
               └───────────────────────────┘

---

## Microarchitectural Features

| Feature | Detail |
|---|---|
| Dispatch | Single-issue, in-order dispatch into 4 RS pools |
| Execution | Out-of-order issue when all operands ready |
| ROB depth | 15 entries (tags 0–14); `TAG_NONE = 0xF = 15` — never aliased |
| Register file | 16 × 32-bit (R0 hardwired to 0), write-through bypass |
| RAT | Embedded inside ROB — youngest-entry-wins combinational scan |
| CDB arbitration | 4-way round-robin across ALU / MUL / LSU / BRU |
| Branch resolution | BRU computes condition + target; full pipeline flush on taken |
| Load ordering | LD blocked in RS_LSU while any unexecuted ST remains in ROB |
| CDB same-cycle capture | RS dispatch logic latches CDB data immediately if tag matches at dispatch time |
| Hazard handling | All RAW hazards resolved via CDB forwarding; no register renaming needed |

---

## Functional Units

| Unit | Latency | Operations |
|---|---|---|
| ALU | 1 cycle | ADD, ADDI, SUB, AND, OR, XOR, SHL, SHR |
| MUL | 3 cycles (pipelined) | MUL, DIV |
| LSU | 2 cycles | LD (load word), ST (store word — speculative execute, commit-ordered write) |
| BRU | 1 cycle | BEQ, BNE, BLT, JMP |

---

## ISA Reference

All instructions are 32-bit fixed width, big-endian field layout:

31      28 27    24 23    20 19    16 15              0
┌────────┬────────┬────────┬────────┬────────────────┐
│ opcode │   rd   │  rs1   │  rs2   │      imm       │
│ [4b]   │ [4b]   │ [4b]   │ [4b]   │    [16b]       │
└────────┴────────┴────────┴────────┴────────────────┘

| Opcode | Mnemonic | Operation | FU |
|---|---|---|---|
| 0x0 | ADD  | rd = rs1 + rs2 | ALU |
| 0x1 | ADDI | rd = rs1 + imm (sign-ext) | ALU |
| 0x2 | SUB  | rd = rs1 − rs2 | ALU |
| 0x3 | AND  | rd = rs1 & rs2 | ALU |
| 0x4 | OR   | rd = rs1 \| rs2 | ALU |
| 0x5 | XOR  | rd = rs1 ^ rs2 | ALU |
| 0x6 | SHL  | rd = rs1 << rs2[4:0] | ALU |
| 0x7 | SHR  | rd = rs1 >> rs2[4:0] | ALU |
| 0x8 | MUL  | rd = rs1 × rs2 | MUL |
| 0x9 | DIV  | rd = rs1 / rs2 | MUL |
| 0xA | LD   | rd = mem[rs1 + imm] | LSU |
| 0xB | ST   | mem[rs1 + imm] = rs2 | LSU |
| 0xC | BEQ  | if rs1 == rs2: PC += imm | BRU |
| 0xD | BNE  | if rs1 != rs2: PC += imm | BRU |
| 0xE | BLT  | if rs1 < rs2 (signed): PC += imm | BRU |
| 0xF | JMP  | PC += imm (unconditional) | BRU |

---

## Test Program

18-instruction program covering all hazard classes and functional units:

Address  Encoding   Assembly                          Notes
───────  ────────   ────────────────────────────────  ────────────────────────────
0x00   11000005   ADDI  R1,  R0,  5                 R1 = 5
0x01   12000003   ADDI  R2,  R0,  3                 R2 = 3
0x02   03120000   ADD   R3,  R1,  R2                R3 = 8  ← RAW chain (dep on R1, R2)
0x03   1400000a   ADDI  R4,  R0,  10                R4 = 10 ← independent, issued OOO
0x04   1e000003   ADDI  R14, R0,  3                 R14 = 3
0x05   254e0000   SUB   R5,  R4,  R14               R5 = 7  ← RAW on R4 and R14
0x06   16000004   ADDI  R6,  R0,  4                 R6 = 4
0x07   17000005   ADDI  R7,  R0,  5                 R7 = 5
0x08   88670000   MUL   R8,  R6,  R7                R8 = 20 ← 3-cycle MUL stall
0x09   19000063   ADDI  R9,  R0,  99                R9 = 99 ← issued OOO past MUL
0x0A   1a000004   ADDI  R10, R0,  4                 R10 = 4 (store address base)
0x0B   1b00002a   ADDI  R11, R0,  42                R11 = 42 (store data)
0x0C   b0ab0000   ST    R0,  R10, R11               mem[4] = 42
0x0D   aca00000   LD    R12, R10, 0                 R12 = mem[4] = 42 ← load-after-store
0x0E   1d000001   ADDI  R13, R0,  1                 R13 = 1
0x0F   1f000002   ADDI  R15, R0,  2                 R15 = 2 (R13 ≠ R15)
0x10   c0df0008   BEQ   R0,  R13, R15, +8           not taken (1 ≠ 2), fall through
0x11   1f00004d   ADDI  R15, R0,  77                R15 = 77 ← proves branch not taken

---

## Simulation Results

**Simulator:** Icarus Verilog 12.0 + GTKWave  
**Result: 6/6 PASSED**

| # | Test Case | Register | Expected | Hazard Exercised | Result |
|---|---|---|---|---|---|
| 1 | ADD dependency chain | R3 | 8 | RAW via CDB forwarding | ✅ PASS |
| 2 | SUB with multi-source RAW | R5 | 7 | Two-source forwarding | ✅ PASS |
| 3 | 3-cycle pipelined MUL | R8 | 20 | Multi-cycle FU stall | ✅ PASS |
| 4 | OOO issue past MUL stall | R9 | 99 | True out-of-order execution | ✅ PASS |
| 5 | Load-after-Store | R12 | 42 | ST→mem, LD ordering, CDB capture | ✅ PASS |
| 6 | BEQ not-taken fall-through | R15 | 77 | Branch resolve, no flush | ✅ PASS |

---

## Bugs Diagnosed and Fixed

Three non-trivial RTL bugs were identified through waveform analysis and trace-driven debugging:

**Bug 1 — TAG_NONE collision with valid ROB entry**

With `ROB_DEPTH=16`, valid ROB tags span 0–15. `TAG_NONE` was defined as `4'hF = 15`, which aliased with the 16th valid ROB entry. Any instruction assigned ROB tag 15 was invisible to the RAT — consumers saw `qj == TAG_NONE` and read stale regfile values instead of waiting for the in-flight result. Fixed by reducing `ROB_DEPTH` to 15 (tags 0–14) and adding explicit modulo-15 wrap on head and tail pointers.

**Bug 2 — CDB same-cycle dispatch race in all RS modules**

When the CDB broadcast for a source tag arrived on the exact same cycle an instruction was dispatched into an RS, the new entry was not yet marked `busy` — so the CDB snoop loop (which only updates `busy` entries) skipped it. The entry entered the RS with `qj` unresolved and `vj = 0`. Since the tag was never re-broadcast, the instruction stalled indefinitely and issued with wrong operands. Fixed by adding same-cycle capture logic at the dispatch write port in all four RS modules: if `cdb_valid && disp_qj == cdb_tag`, latch `cdb_data` and clear `qj` to `TAG_NONE` immediately.

**Bug 3 — Branch target sign-extension width**

`bru_unit.v` computed `branch_target` using only `{1{imm[15]}, imm[14:0]}` — a 16-to-16-bit non-extension that silently discarded the MSB. Fixed to correct `{16{imm[15]}, imm[15:0]}` for proper signed PC-relative offset.

---

## Build & Simulate

**Requirements:** Icarus Verilog (`iverilog`, `vvp`), GTKWave (optional)

```bash
# Clone
git clone https://github.com/vsgautam22/kronos-ooo-pipeline.git
cd kronos-ooo-pipeline

# Compile and simulate
make sim

# Open waveform in GTKWave
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

---

## Repository Structure

kronos-ooo-pipeline/
├── rtl/
│   ├── ooo_pkg.v        # Global parameters, opcode & FU defines
│   ├── ooo_top.v        # Top-level interconnect
│   ├── fetch.v          # PC register + instruction memory (256 × 32-bit)
│   ├── decode.v         # Decode, FU select, operand resolution, dispatch
│   ├── rob.v            # 15-entry ROB + embedded RAT (youngest-wins scan)
│   ├── regfile.v        # 16 × 32 register file with write-through bypass
│   ├── rs_alu.v         # ALU reservation station (4 entries)
│   ├── rs_mul.v         # MUL reservation station (2 entries)
│   ├── rs_lsu.v         # LSU reservation station (2 entries, ST ordering)
│   ├── rs_bru.v         # BRU reservation station (2 entries, PC forwarded)
│   ├── alu_unit.v       # 1-cycle combinational ALU
│   ├── mul_unit.v       # 3-stage pipelined multiplier / divider
│   ├── lsu_unit.v       # 2-cycle LSU with 256-word data memory
│   ├── bru_unit.v       # Branch condition eval + target compute
│   └── cdb_arbiter.v    # 4-way round-robin CDB arbiter (registered output)
├── tb/
│   ├── ooo_tb.v         # Self-checking testbench — 6 assertions
│   ├── imem.hex         # 18-instruction test program (hex)
│   └── gen_imem.py      # Instruction assembler / hex generator
├── sim/                 # Simulation outputs — gitignored
├── synth/               # Synthesis outputs — gitignored
├── Makefile
├── LICENSE
└── README.md

---

## Tools & Environment

| Tool | Purpose |
|---|---|
| Icarus Verilog 12.0 | RTL simulation (`iverilog` + `vvp`) |
| GTKWave | Waveform inspection (VCD) |
| WSL2 Ubuntu 24.04 | Development environment |

---

## Future Enhancements

- Superscalar dual-issue dispatch (2-wide)
- Branch predictor (2-bit saturating counter, BTB)
- Full RV32I ISA front-end replacing custom ISA
- Yosys synthesis + OpenLane tape-out on SKY130A
- Formal verification of ROB commit ordering (SymbiYosys)

---

## References

1. Tomasulo, R.M., *An Efficient Algorithm for Exploiting Multiple Arithmetic Units*, IBM Journal, 1967
2. Hennessy & Patterson, *Computer Architecture: A Quantitative Approach*, 6th Ed.
3. Icarus Verilog — https://steveicarus.github.io/iverilog

---

## Portfolio

Part of an FPGA/VLSI portfolio by **Gautam Suresh** (B.E. Electronics, VLSI Design & Technology, CIT Chennai).

| # | Project | Description |
|---|---|---|
| 1 | [CRC Engine](https://github.com/vsgautam22/crc-engine) | RTL + SymbiYosys formal verification + OpenLane GDS on SKY130A (0 DRC violations) |
| 2 | [RISC-V RV32I Core](https://github.com/vsgautam22/riscv-core) | 5-stage in-order pipeline, full hazard handling, 14/14 tests passed |
| 3 | **Kronos-32 OOO Engine** | Tomasulo OOO core, 4 FUs, ROB+RAT+CDB, 6/6 tests passed |
