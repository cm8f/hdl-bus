#!/bin/python
from os.path import join, dirname
from subprocess import call
from vunit import VUnit, VUnitCLI
from glob import glob
from subprocess import call
import imp

def vhdl_ls(VU):
    libs = []
    srcfiles = VU.get_compile_order()
    for so in srcfiles:
        try:
            libs.index(so.library.name)
        except:
            libs.append(so.library.name)
    
    fd = open("vhdl_ls.toml", "w")
    fd.write("[libraries]\n")

    for l in libs:
        fd.write("%s.files = [\n" % l)

        flist = VU.get_source_files(library_name=l) 
        for f in flist:
            fd.write("  '%s',\n" % f.name)

        fd.write("]\n\n") 
    
    fd.close()

def post_run(results):
    results.merge_coverage(file_name="coverage_data")
    if VU.get_simulator_name() == "ghdl":
        call(["gcovr", "--exclude-unreachable-branches", "--exclude-unreachable-branches", "-o", "coverage.txt", "--fail-under-line", "100", "coverage_data"])

def create_test_suite(prj, args):
    root = dirname(__file__)

    try:
        lib = prj.library("work_lib")
    except:
        lib = prj.add_library("work_lib")
    lib.add_source_files(join(root, "./hdl/**/*.vhd"))
    lib.add_source_files(join(root, "./hdl/*.vhd"))
    lib.add_source_files(join(root, "./testbench/*.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/ram/hdl/ram_tdp.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/ram/hdl/ram_sdp.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/fifo/hdl/fifo_sc_single.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/fifo/hdl/fifo_sc_mixed.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/uart/hdl/uart_tx.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/uart/hdl/uart_rx.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/uart/hdl/uart_wrapper_top.vhd"))
    lib.add_source_files(join(root, "./external/hdl-base/arbiter/hdl/arbiter_rr.vhd"))

    prj.add_osvvm()
    prj.add_random()

    # configure simulator
    if prj.get_simulator_name() == "ghdl":
        lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
        lib.set_compile_option("ghdl.a_flags", ["--std=08", "--ieee=synopsys", "-frelaxed-rules"])
        lib.set_sim_option("ghdl.elab_flags", ["--ieee=synopsys", "-frelaxed-rules"])
        if args.cover > 0:
            lib.set_sim_option("enable_coverage", True)
            lib.set_compile_option("enable_coverage", True)

    tb_reg_bank = lib.test_bench("tb_avl_gen_reg_bank")
    registers = [4, 64, 256]
    widths = [32]

    for test in tb_reg_bank.get_tests():
        for num in registers:
            for wdt in widths:
                test.add_config(
                    name="numregs=%d,regwidth=%d" % (num, wdt),
                    generics=dict(
                        g_registers = num,
                        g_register_width = wdt
                    )
                )

    tb_splitter = lib.test_bench("tb_avl_bus_splitter")
    num_ports = [2, 3, 16]
    for test in tb_splitter.get_tests():
        for num in num_ports:
            test.add_config(
                name="slaves=%d" % num,
                generics=dict(
                    g_number_ports = num
                )
            )
    tb_arbiter = lib.test_bench("tb_avl_bus_arbiter")
    num_ports = [1, 2, 3, 4]
    for test in tb_arbiter.get_tests():
        for num in num_ports:
            test.add_config(
                name="masters=%d" %  num, 
                generics=dict(
                    g_number_ports=num
                )
            )
    
    tb_ram = lib.test_bench("tb_avl_ram")
    addr_width = [8, 10, 12]
    for test in tb_ram.get_tests():
        for wdt in addr_width:
            test.add_config(
                name="addr_width=%d" % wdt,
                generics=dict(
                    g_addr_width = wdt 
                )
            )
    tb_uart = lib.test_bench("tb_avl_uart")
    baud_arr = [4800, 9600, 14400, 19200, 57600, 115200, 128000, 256000]
    for test in tb_uart.get_tests():
        for baud in baud_arr:
            test.add_config(
                    name="baud=%d" % baud,
                    generics=dict(
                        g_baud=baud
                    )
                )


if __name__ == "__main__":
    cli = VUnitCLI()
    cli.parser.add_argument('--cover', action='store_true', help='Enable ghdl coverage')
    cli.parser.add_argument('--vhdl_ls', action='store_true', help='Generate vhdl_ls toml file')
    args = cli.parse_args()

    VU = VUnit.from_args(args=args)
    VU.add_osvvm()
    VU.add_random()
    VU.add_verification_components()
    create_test_suite(VU, args)

    if args.vhdl_ls:
        vhdl_ls(VU)
        exit()

    if args.cover < 1:
        VU.main()
    else:
        VU.main(post_run=post_run)
