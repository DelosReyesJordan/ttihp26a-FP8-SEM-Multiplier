import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


# ----------------------------------------------------
# Minimal behavioral acceptance model
# ----------------------------------------------------
def sem_acceptance_check(a, b, result):

    sign_a = (a >> 7) & 1
    sign_b = (b >> 7) & 1

    exp_a = (a >> 3) & 0xF
    exp_b = (b >> 3) & 0xF

    mant_a = a & 0x7
    mant_b = b & 0x7

    # Special cases must be correct
    if (exp_a == 0xF and mant_a == 0x7) or \
       (exp_b == 0xF and mant_b == 0x7):

        return result == 0b0_1111_111

    if (exp_a == 0 and mant_a == 0) or \
       (exp_b == 0 and mant_b == 0):

        return result == 0b0_0000_000

    # Sign bit must be correct
    if ((result >> 7) & 1) != (sign_a ^ sign_b):
        return False

    return True


# ----------------------------------------------------
# Testbench
# ----------------------------------------------------
@cocotb.test()
async def test_basic(dut):

    dut._log.info("Tiny Tapeout SEM multiplier acceptance test")

    clock = Clock(dut.clk, 20, unit="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1

    # Reset
    dut.rst_n.value = 0

    for _ in range(5):
        await RisingEdge(dut.clk)

    dut.rst_n.value = 1

    # Pipeline settle
    for _ in range(5):
        await RisingEdge(dut.clk)

    # Test vectors
    test_vectors = [
        (0b0_0101_010, 0b0_0011_001),
        (0b1_0100_011, 0b0_0010_010),
        (0b0_0000_000, 0b0_0101_010),
        (0b0_1111_111, 0b0_0101_010),
    ]

    # Testing
    for a, b in test_vectors:

        dut.ui_in.value = a
        dut.uio_in.value = b

        # Allow pipeline propagation
        for _ in range(5):
            await RisingEdge(dut.clk)

        result = dut.uo_out.value.to_unsigned()

        assert sem_acceptance_check(a, b, result), \
            f"Acceptance test failed A={a:08b} B={b:08b} OUT={result:08b}"

    dut._log.info("Test passed")
