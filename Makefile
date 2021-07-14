FPGA_OUTDIR = ./workspace/output_files
SW_OUTDIR   = ./software/integration
DEPLOY_DIR  = ./deploy

QSH         = quartus_sh
QPGM        = quartus_pgm
QSYS_GEN    = qsys-generate

.PHONY: all clean msim_vunit ghdl_vunit 

all: fpga msim_vunit ghdl_vunit 

#apps:
#	make -C software all

fpga: ip
	cd workspace && ${QSH} --flow compile avl-integration.qpf

ip:
	cd workspace   && ${QSYS_GEN} nios_test_system.qsys -syn=VHDL -sim=VHDL -tb -tb-sim=VHDL

prog_fpga:
	${QPGM} -m jtag -o "p;workspace/output_files/nioskopter.sof"

prog_nios:
	nios2_command_shell.sh nios2-download -g ./software/nanoKopter_fw/nioskopter_fw.elf


msim_vunit:
	export VUNIT_SIMULATOR=modelsim && ./run.py -p 2 -o vunit_out_msim

ghdl_vunit:
	export VUNIT_SIMULATOR=ghdl && ./run.py -p 12 -o vunit_out_ghdl

doku:
	mkdir -p doc/pdf
	cd doc && latexmk -pdf main.tex
	cd doc && latexmk -pdf content/*.tex
	cd doc && latexmk -pdf -c main.tex
	cd doc && latexmk -pdf -c content/*.tex
	mv doc/*.pdf doc/pdf/

clean:
	rm -rf ./vunit_out
