#!/usr/bin/env python3
def enc(op, rd, rs1, rs2, imm):
    return ((op&0xF)<<28)|((rd&0xF)<<24)|((rs1&0xF)<<20)|((rs2&0xF)<<16)|(imm&0xFFFF)

OP = {'ADD':0,'ADDI':1,'SUB':2,'AND':3,'OR':4,'XOR':5,'SHL':6,'SHR':7,
      'MUL':8,'DIV':9,'LD':0xA,'ST':0xB,'BEQ':0xC,'BNE':0xD,'BLT':0xE,'JMP':0xF}

NOP = enc(0, 0, 0, 0, 0)

prog = [
    enc(OP['ADDI'], 1, 0, 0, 5),    # 0:  R1=5
    enc(OP['ADDI'], 2, 0, 0, 3),    # 1:  R2=3
    enc(OP['ADD'],  3, 1, 2, 0),    # 2:  R3=8
    enc(OP['ADDI'], 4, 0, 0, 10),   # 3:  R4=10
    enc(OP['ADDI'],14, 0, 0, 3),    # 4:  R14=3
    enc(OP['SUB'],  5, 4,14, 0),    # 5:  R5=7
    enc(OP['ADDI'], 6, 0, 0, 4),    # 6:  R6=4
    enc(OP['ADDI'], 7, 0, 0, 5),    # 7:  R7=5
    enc(OP['MUL'],  8, 6, 7, 0),    # 8:  R8=20
    enc(OP['ADDI'], 9, 0, 0, 99),   # 9:  R9=99
    enc(OP['ADDI'],10, 0, 0, 4),    # 10: R10=4
    enc(OP['ADDI'],11, 0, 0, 42),   # 11: R11=42
    enc(OP['ST'],   0,10,11, 0),    # 12: MEM[4]=42
    enc(OP['LD'],  12,10, 0, 0),    # 13: R12=MEM[4]
    enc(OP['ADDI'],13, 0, 0, 1),    # 14: R13=1
    enc(OP['ADDI'],15, 0, 0, 2),    # 15: R15=2
    enc(OP['BEQ'],  0,13,15, 8),    # 16: not taken
    enc(OP['ADDI'],15, 0, 0, 77),   # 17: R15=77
] + [NOP] * (256 - 18)

with open("imem.hex", "w") as f:
    for instr in prog[:256]:
        f.write(f"{instr:08x}\n")
print("Generated 256 instructions")
