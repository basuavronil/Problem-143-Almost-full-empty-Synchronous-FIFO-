# Synchronous FIFO with Almost-Full / Almost-Empty Flags

A synchronous FIFO written in Verilog, with `almost_full` and `almost_empty` status flags, implemented and timing-verified in Xilinx Vivado.

## Design Overview

| Parameter | Value |
|---|---|
| Depth | 16 words |
| Data width | 8 bits |
| Clocking | Single clock (`clk`), rising edge |
| Reset | Asynchronous, active-low (`rst`) |
| `almost_empty` | Asserted when 2 or fewer words are stored |
| `almost_full` | Asserted when 14 or more words are stored (2 or fewer free slots) |

### Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `clk` | Input | 1 | Clock |
| `rst` | Input | 1 | Active-low asynchronous reset |
| `wr_en` | Input | 1 | Write enable |
| `rd_en` | Input | 1 | Read enable |
| `data_in` | Input | 8 | Write data |
| `data_out` | Output | 8 | Read data (registered) |
| `empty` | Output | 1 | FIFO empty |
| `full` | Output | 1 | FIFO full |
| `almost_empty` | Output | 1 | FIFO nearly empty |
| `almost_full` | Output | 1 | FIFO nearly full |

## Implementation Setup

| Item | Value |
|---|---|
| Tool | Vivado 2024.2 |
| Target device | `xc7a12ticsg325-1L` (Artix-7) |
| Speed grade | -1L |
| Flow | Synthesis, then implementation (routed) |

## Clock Constraint

| Clock | Port | Period | Frequency | Waveform |
|---|---|---|---|---|
| `clk` | `clk` | 10.000 ns | 100 MHz | rise at 0.000 ns, fall at 5.000 ns |

Constraints file (`sync_fifo.xdc`):

```tcl
# 100 MHz clock (10 ns period)
create_clock -period 10.000 -name clk [get_ports clk]

# Reset is asynchronous, so exclude it from timing analysis
set_false_path -from [get_ports rst]
```

## Timing Summary

**Result: all user specified timing constraints are met.**

### Setup

| Metric | Value |
|---|---|
| Worst Negative Slack (WNS) | **5.584 ns** |
| Total Negative Slack (TNS) | 0.000 ns |
| Number of failing endpoints | 0 |
| Total number of endpoints | 164 |

### Hold

| Metric | Value |
|---|---|
| Worst Hold Slack (WHS) | **0.236 ns** |
| Total Hold Slack (THS) | 0.000 ns |
| Number of failing endpoints | 0 |
| Total number of endpoints | 164 |

### Pulse Width

| Metric | Value |
|---|---|
| Worst Pulse Width Slack (WPWS) | **4.500 ns** |
| Total Pulse Width Negative Slack (TPWS) | 0.000 ns |
| Number of failing endpoints | 0 |
| Total number of endpoints | 147 |

### At a Glance

| Check | Slack | Failing endpoints | Status |
|---|---|---|---|
| Setup | +5.584 ns | 0 / 164 | Met |
| Hold | +0.236 ns | 0 / 164 | Met |
| Pulse width | +4.500 ns | 0 / 147 | Met |

## Interpretation

- **Setup:** the worst path has 5.584 ns of slack against the 10 ns period. The longest path takes roughly 4.4 ns, so the design could run at about 226 MHz on this device (estimate: 1 / (10 - 5.584) ns).
- **Hold:** the worst hold slack is positive (0.236 ns), so no hold violations exist.
- **Pulse width:** positive slack (4.500 ns), so the minimum clock pulse width requirements are met.
- A positive slack means the constraint is met. A negative slack would indicate a violation.

## Notes

- Timing was run with the clock constraint only. Input and output delay constraints were not applied, so the results cover internal register-to-register paths. This is appropriate when the FIFO is used as a block inside a larger design.
- If the FIFO ports are connected directly to chip pins, add `set_input_delay` and `set_output_delay` constraints that match your board. With a 10 ns clock and 2 ns I/O delays on this device, the output paths failed, so a slower clock (about 15 ns) would be needed.

## Files

| File | Description |
|---|---|
| `sync_fifo.v` | FIFO RTL |
| `tb_sync_fifo.v` | Self-checking testbench |
| `sync_fifo.xdc` | Timing constraints |

