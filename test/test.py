import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer


def sem_mul(a, b):
    """Very basic SEM multiply reference model (no rounding)."""

    # Extract fields
    sign_a = (a >> 7) & 1
    sign_b = (b >> 7) & 1

    exp_a  = (a >> 3) & 0xF
    exp_b  = (b >> 3) & 0xF

    mant_a = a & 0x7
    mant_b = b & 0x7

    # NaN
    if (exp_a == 0xF and mant_a == 0x7) or \
       (exp_b == 0xF and mant_b == 0x7):
        return 0b0_1111_111

    # Zero
    if (exp_a == 0 and mant_a == 0) or \
       (exp_b == 0 and mant_b == 0):
        return 0b0_0000_000

    sign = sign_a ^ sign_b
    exp  = exp_a + exp_b
    mant = (mant_a * mant_b) & 0x7

    return (sign << 7) | ((exp & 0xF) << 3) | mant


@cocotb.test()
async def test_basic(dut):

    # Start clock
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.start_soon(clock.start())

    dut.ena.value = 1

    # Reset
    dut.rst_n.value = 0
    await Timer(40, units="ns")
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Test cases
    test_vectors = [
        (0b0_0101_010, 0b0_0011_001),
        (0b1_0100_011, 0b0_0010_010),
        (0b0_0000_000, 0b0_0101_010),  # zero
        (0b0_1111_111, 0b0_0101_010),  # NaN
    ]

    for a, b in test_vectors:
        dut.ui_in.value = a
        dut.uio_in.value = b

        await RisingEdge(dut.clk)
        await RisingEdge(dut.clk)

        expected = sem_mul(a, b)
        result = dut.uo_out.value.integer

        assert result == expected, \
            f"Mismatch: A={a:08b} B={b:08b} Got={result:08b} Expected={expected:08b}"
