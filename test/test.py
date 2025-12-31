import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # クロックの生成 (10us周期 = 100kHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # リセット動作
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test CIC Filter functionality (Basic check)")

    # PDM入力として「0」と「1」を交互に入れてみる
    # エラーが出ずにシミュレーションが走ればOKとする
    for i in range(100):
        dut.ui_in.value = 1
        await ClockCycles(dut.clk, 1)
        dut.ui_in.value = 0
        await ClockCycles(dut.clk, 1)

    dut._log.info("Test finished")
