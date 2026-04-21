# Kronos-32 OOO Pipeline Engine — Build & Simulation Makefile

IVERILOG  = iverilog
VVP       = vvp
GTKWAVE   = gtkwave

RTL_INC   = rtl/
RTL_SRCS  = rtl/ooo_pkg.v rtl/regfile.v rtl/alu_unit.v rtl/mul_unit.v \
            rtl/bru_unit.v rtl/lsu_unit.v rtl/cdb_arbiter.v \
            rtl/rs_alu.v rtl/rs_mul.v rtl/rs_bru.v rtl/rs_lsu.v \
            rtl/rob.v rtl/fetch.v rtl/decode.v rtl/ooo_top.v
TB_SRC    = tb/ooo_tb.v
SIM_OUT   = sim/ooo_sim
VCD_OUT   = sim/ooo_core.vcd

.PHONY: all sim wave clean help

all: sim

sim: $(SIM_OUT)
	@echo ">>> Running simulation..."
	$(VVP) $(SIM_OUT)

$(SIM_OUT): $(RTL_SRCS) $(TB_SRC)
	@mkdir -p sim
	$(IVERILOG) -g2012 -I $(RTL_INC) -o $(SIM_OUT) $(RTL_SRCS) $(TB_SRC)
	@echo ">>> Compile OK"

wave: $(VCD_OUT)
	$(GTKWAVE) $(VCD_OUT) &

$(VCD_OUT): sim

clean:
	rm -f $(SIM_OUT) $(VCD_OUT)
	@echo ">>> Clean done"

help:
	@echo "Targets: all | sim | wave | clean"
	@echo "  make sim    — compile and run testbench"
	@echo "  make wave   — open waveform in GTKWave"
	@echo "  make clean  — remove build artifacts"
