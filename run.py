#!/bin/python
from os.path import join, dirname
from subprocess import call
from vunit import VUnit, VUnitCLI

def post_run(results):
    results.merge_coverage(file_name="coverage_data")
    if VU.get_simulator_name() == "ghdl":
        call(["gcovr", "-x", "coverage.xml", "coverage_data"])
        call(["gcovr", "-o", "coverage.txt", "coverage_data"])

def create_test_suite(prj, args):
    root = dirname(__file__)

    try:
        lib = prj.library("work_lib")
    except:
        lib = prj.add_library("work_lib")
    lib.add_source_files(join(root, "./hdl/*.vhd"))
    lib.add_source_files(join(root, "./testbench/*.vhd"))

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
    registers = [4, 8, 16, 32, 64, 128, 256]
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
    num_ports = range(2, 8)
    for test in tb_splitter.get_tests():
        for num in num_ports:
            test.add_config(
                name="slaves=%d" % num,
                generics=dict(
                    g_number_ports = num
                )
            )


if __name__ == "__main__":
    cli = VUnitCLI()
    cli.parser.add_argument('--cover', type=int, default=0, help='Enable ghdl coverage')
    args = cli.parse_args()

    VU = VUnit.from_args(args=args)
    VU.add_osvvm()
    VU.add_random()
    VU.add_verification_components()
    create_test_suite(VU, args)
    if args.cover < 1:
        VU.main()
    else:
        VU.main(post_run=post_run)
