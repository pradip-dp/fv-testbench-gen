# prim_fifo_sync — Specification

## Overview

`prim_fifo_sync` is a parameterized synchronous FIFO used throughout the OpenTitan SoC as a fundamental building block. It implements a standard valid/ready handshake on both the write and read interfaces.

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `Width` | int unsigned | 16 | Data width in bits |
| `Pass` | bit | 1 | When 1, data can pass through an empty FIFO combinationally — the write data appears on the read output in the same cycle without being stored first |
| `Depth` | int unsigned | 4 | Number of FIFO entries |
| `OutputZeroIfEmpty` | bit | 1 | When 1, read data output is forced to zero when the FIFO is empty |
| `Secure` | bit | 0 | When 1, uses hardened counters for fault detection |

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk_i` | input | 1 | Clock |
| `rst_ni` | input | 1 | Active-low asynchronous reset |
| `clr_i` | input | 1 | Synchronous clear — empties the FIFO |
| `wvalid_i` | input | 1 | Write valid — producer has data to write |
| `wready_o` | output | 1 | Write ready — FIFO can accept data |
| `wdata_i` | input | [Width-1:0] | Write data |
| `rvalid_o` | output | 1 | Read valid — FIFO has data available |
| `rready_i` | input | 1 | Read ready — consumer is ready to accept data |
| `rdata_o` | output | [Width-1:0] | Read data |
| `full_o` | output | 1 | FIFO is full |
| `depth_o` | output | [DepthW-1:0] | Current number of entries in the FIFO |
| `err_o` | output | 1 | Error signal (used in Secure mode) |

## Functional Behavior

### Write Interface

A write occurs when both `wvalid_i` and `wready_o` are high on the same clock edge. The data on `wdata_i` is stored in the FIFO.

`wready_o` is high when the FIFO is not full. When the FIFO is full, `wready_o` is low and writes are not accepted.

### Read Interface

A read occurs when both `rvalid_o` and `rready_i` are high on the same clock edge. The data on `rdata_o` is consumed and removed from the FIFO.

`rvalid_o` is high when the FIFO has at least one entry. When the FIFO is empty, `rvalid_o` is low.

### Pass-Through Mode (Pass = 1)

When `Pass` is enabled and the FIFO is empty, incoming write data bypasses storage and appears directly on the read output in the same cycle. In this mode:
- `rvalid_o` goes high when `wvalid_i` is high, even if the FIFO has no stored entries
- `rdata_o` reflects `wdata_i` directly

When `Pass` is disabled (Pass = 0), data must always be stored before it can be read. There is always at least one cycle of latency.

### Depth and Full

`depth_o` reflects the current number of stored entries. `full_o` is asserted when the FIFO has reached its maximum capacity (`depth_o == Depth`).

### Clear

Asserting `clr_i` synchronously empties the FIFO. On the next clock edge after clear, the FIFO is empty (`depth_o == 0`).

### Reset

On asynchronous reset (`rst_ni` low), the FIFO is emptied. All outputs return to their reset values.

## Invariants

- `depth_o` never exceeds `Depth`
- `full_o` is asserted if and only if `depth_o == Depth`
- Data written to the FIFO is read out in the same order (FIFO ordering)
- No data is lost or duplicated under normal operation
- A write followed by a read (without simultaneous new write) decrements depth by exactly 1
- A read followed by a write (without simultaneous new read) increments depth by exactly 1
