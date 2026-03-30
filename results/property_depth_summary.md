# Property Depth Summary

- Results below reflect the fresh 100-depth runs with `timeout 300` in the `.sby` configs.
- For `ASSERT`, `Depth` is the deepest checked step reached for that task.
- For `COVER`, `Depth` is the first step where the cover was reached.
- `TIMEOUT` means `SBY` hit the 300-second task limit and terminated the proof cleanly.

## Run Summary

| Task | Kind | Status | Deepest Step |
| --- | --- | --- | --- |
| `prim_fifo_sync_cover` | COVER | PASS | 3 |
| `prim_fifo_sync_bmc` | ASSERT (combined top-level BMC) | TIMEOUT | 22 |
| `depth0` | ASSERT | PASS | 99 |
| `depth1_nopass` | ASSERT | PASS | 99 |
| `depth1_pass_secure` | ASSERT | PASS | 99 |
| `depth3_pass` | ASSERT | TIMEOUT | 21 |
| `depth4_nopass_secure` | ASSERT | TIMEOUT | 21 |

## Assert Properties

### `depth0`

| Location | Description | Status | Depth |
| --- | --- | --- | --- |
| `prim_fifo_sync_tb.sv:175.7-175.26` | Width parameter must be at least 1. | checked | 99 |
| `prim_fifo_sync_tb.sv:179.9-179.22` | Depth-0 configuration must enable pass-through mode. | checked | 99 |
| `prim_fifo_sync_tb.sv:192.9-192.31` | Pass-through output must assert valid whenever write valid is high. | checked | 99 |
| `prim_fifo_sync_tb.sv:197.9-197.31` | Pass-through output data must equal current write data. | checked | 99 |
| `prim_fifo_sync_tb.sv:202.9-202.38` | Pass-through write-ready must mirror read-ready. | checked | 99 |
| `prim_fifo_sync_tb.sv:203.9-203.36` | Depth-0 FIFO must report full. | checked | 99 |
| `prim_fifo_sync_tb.sv:204.9-204.38` | Depth-0 FIFO depth output must stay at zero. | checked | 99 |
| `prim_fifo_sync_tb.sv:205.9-205.32` | Depth-0 FIFO must not raise error. | checked | 99 |
| `prim_fifo_sync_tb.sv:206.9-206.31` | Read-handshake accounting must never underflow the reference model. | checked | 99 |
| `prim_fifo_sync_tb.sv:207.9-207.31` | Read-handshake data must come from bypass or stored head data. | checked | 99 |
| `prim_fifo_sync_tb.sv:264.11-264.38` | Occupancy must be nonzero before consuming stored data. | checked | 99 |
| `prim_fifo_sync_tb.sv:266.11-266.33` | Stored-data read must return the reference head element. | checked | 99 |
| `prim_fifo_sync_tb.sv:267.11-267.44` | Write-only handshake must not occur when the FIFO is already full. | checked | 99 |
| `prim_fifo_sync_tb.sv:273.9-273.35` | Read-only handshake must not occur when the FIFO is empty. | checked | 99 |
| `prim_fifo_sync_tb.sv:278.9-278.31` | Full FIFO must deassert write-ready. | checked | 99 |
| `prim_fifo_sync_tb.sv:283.9-283.27` | Reference occupancy must never exceed configured depth. | checked | 99 |

### `depth1_nopass`

| Location | Description | Status | Depth |
| --- | --- | --- | --- |
| `prim_fifo_sync_tb.sv:175.7-175.26` | Width parameter must be at least 1. | checked | 99 |
| `prim_fifo_sync_tb.sv:184.9-184.36` | Depth-1 full flag must match single-entry occupancy. | checked | 99 |
| `prim_fifo_sync_tb.sv:185.9-185.39` | Depth-1 write-ready must be high only when empty. | checked | 99 |
| `prim_fifo_sync_tb.sv:186.9-186.39` | Depth-1 read-valid must reflect stored data or pass-through bypass. | checked | 99 |
| `prim_fifo_sync_tb.sv:187.9-187.50` | Empty pass-through read must return current write data. | checked | 99 |
| `prim_fifo_sync_tb.sv:192.9-192.31` | Depth-1 stored read must return the reference head data. | checked | 99 |
| `prim_fifo_sync_tb.sv:197.9-197.31` | OutputZeroIfEmpty must drive zero when no valid data is present. | checked | 99 |
| `prim_fifo_sync_tb.sv:212.9-212.44` | Read-handshake data must use bypass path when pass-through reads an empty FIFO. | checked | 99 |
| `prim_fifo_sync_tb.sv:213.9-213.46` | Otherwise read-handshake data must come from stored head data. | checked | 99 |
| `prim_fifo_sync_tb.sv:214.9-214.70` | Read-handshake from storage requires positive occupancy. | checked | 99 |
| `prim_fifo_sync_tb.sv:217.11-217.38` | Write-only handshake must not occur when the FIFO is full. | checked | 99 |
| `prim_fifo_sync_tb.sv:221.11-221.44` | Read-only handshake must not occur when the FIFO is empty. | checked | 99 |
| `prim_fifo_sync_tb.sv:225.11-225.33` | Full FIFO must deassert write-ready. | checked | 99 |
| `prim_fifo_sync_tb.sv:264.11-264.38` | Reference occupancy must never exceed configured depth. | checked | 99 |
| `prim_fifo_sync_tb.sv:266.11-266.33` | `depth_o` must track reference occupancy. | checked | 99 |
| `prim_fifo_sync_tb.sv:267.11-267.44` | Non-secure configurations must never raise `err_o`. | checked | 99 |
| `prim_fifo_sync_tb.sv:273.9-273.35` | Secure mode must not raise `err_o` immediately after reset release. | checked | 99 |
| `prim_fifo_sync_tb.sv:278.9-278.31` | Occupancy must remain within model bounds after all handshakes. | checked | 99 |
| `prim_fifo_sync_tb.sv:283.9-283.27` | Model bookkeeping indices must stay in range. | checked | 99 |

### `depth1_pass_secure`

| Location | Description | Status | Depth |
| --- | --- | --- | --- |
| `prim_fifo_sync_tb.sv:175.7-175.26` | Width parameter must be at least 1. | checked | 99 |
| `prim_fifo_sync_tb.sv:184.9-184.36` | Depth-1 full flag must match single-entry occupancy. | checked | 99 |
| `prim_fifo_sync_tb.sv:185.9-185.39` | Depth-1 write-ready must be high only when empty. | checked | 99 |
| `prim_fifo_sync_tb.sv:186.9-186.39` | Depth-1 read-valid must reflect stored data or pass-through bypass. | checked | 99 |
| `prim_fifo_sync_tb.sv:187.9-187.50` | Empty pass-through read must return current write data. | checked | 99 |
| `prim_fifo_sync_tb.sv:197.9-197.31` | Depth-1 stored read must return the reference head data. | checked | 99 |
| `prim_fifo_sync_tb.sv:212.9-212.44` | Read-handshake data must use bypass path when pass-through reads an empty FIFO. | checked | 99 |
| `prim_fifo_sync_tb.sv:213.9-213.46` | Otherwise read-handshake data must come from stored head data. | checked | 99 |
| `prim_fifo_sync_tb.sv:214.9-214.70` | Read-handshake from storage requires positive occupancy. | checked | 99 |
| `prim_fifo_sync_tb.sv:217.11-217.38` | Write-only handshake must not occur when the FIFO is full. | checked | 99 |
| `prim_fifo_sync_tb.sv:221.11-221.44` | Read-only handshake must not occur when the FIFO is empty. | checked | 99 |
| `prim_fifo_sync_tb.sv:225.11-225.33` | Full FIFO must deassert write-ready. | checked | 99 |
| `prim_fifo_sync_tb.sv:264.11-264.38` | Reference occupancy must never exceed configured depth. | checked | 99 |
| `prim_fifo_sync_tb.sv:266.11-266.33` | `depth_o` must track reference occupancy. | checked | 99 |
| `prim_fifo_sync_tb.sv:267.11-267.44` | Secure mode must not raise `err_o` immediately after reset release. | checked | 99 |
| `prim_fifo_sync_tb.sv:273.9-273.35` | Occupancy must remain within model bounds after all handshakes. | checked | 99 |
| `prim_fifo_sync_tb.sv:278.9-278.31` | Model bookkeeping indices must stay in range. | checked | 99 |
| `prim_fifo_sync_tb.sv:283.9-283.27` | Output-zero behavior must not corrupt valid data handling. | checked | 99 |

### `depth3_pass`

| Location | Description | Status | Depth |
| --- | --- | --- | --- |
| `prim_fifo_sync_tb.sv:175.7-175.26` | Width parameter must be at least 1. | timeout | 21 |
| `prim_fifo_sync_tb.sv:184.9-184.36` | Multi-entry full flag must match reference occupancy at configured depth. | timeout | 21 |
| `prim_fifo_sync_tb.sv:185.9-185.39` | Multi-entry write-ready must drop when full or under reset bookkeeping. | timeout | 21 |
| `prim_fifo_sync_tb.sv:186.9-186.39` | Pass-through multi-entry read-valid must reflect stored data or bypass data. | timeout | 21 |
| `prim_fifo_sync_tb.sv:187.9-187.50` | Empty pass-through read on multi-entry FIFO must return current write data. | timeout | 21 |
| `prim_fifo_sync_tb.sv:192.9-192.31` | Stored multi-entry read must return the reference head data. | timeout | 21 |
| `prim_fifo_sync_tb.sv:197.9-197.31` | OutputZeroIfEmpty must drive zero when empty and not bypassing. | timeout | 21 |
| `prim_fifo_sync_tb.sv:231.9-231.48` | Non-pass multi-entry read-valid must depend only on stored occupancy. | timeout | 21 |
| `prim_fifo_sync_tb.sv:232.9-232.69` | Non-pass multi-entry read data must come from the reference head. | timeout | 21 |
| `prim_fifo_sync_tb.sv:235.11-235.81` | OutputZeroIfEmpty must drive zero on empty non-pass multi-entry FIFO. | timeout | 21 |
| `prim_fifo_sync_tb.sv:238.13-238.40` | Read-handshake from empty pass-through FIFO must bypass current write data. | timeout | 21 |
| `prim_fifo_sync_tb.sv:242.13-242.46` | Read-handshake from stored contents must require positive occupancy. | timeout | 21 |
| `prim_fifo_sync_tb.sv:246.13-246.35` | Read-handshake from stored contents must return reference head data. | timeout | 21 |
| `prim_fifo_sync_tb.sv:264.11-264.38` | Write-only handshake must not occur when the FIFO is full. | timeout | 21 |
| `prim_fifo_sync_tb.sv:266.11-266.33` | Read-only handshake must not occur when the FIFO is empty. | timeout | 21 |
| `prim_fifo_sync_tb.sv:267.11-267.44` | Full FIFO must deassert write-ready. | timeout | 21 |
| `prim_fifo_sync_tb.sv:273.9-273.35` | Reference occupancy must never exceed configured depth. | timeout | 21 |
| `prim_fifo_sync_tb.sv:278.9-278.31` | `depth_o` must track reference occupancy. | timeout | 21 |
| `prim_fifo_sync_tb.sv:283.9-283.27` | Model bookkeeping indices must stay in range. | timeout | 21 |

### `depth4_nopass_secure`

| Location | Description | Status | Depth |
| --- | --- | --- | --- |
| `prim_fifo_sync_tb.sv:175.7-175.26` | Width parameter must be at least 1. | timeout | 21 |
| `prim_fifo_sync_tb.sv:184.9-184.36` | Multi-entry full flag must match reference occupancy at configured depth. | timeout | 21 |
| `prim_fifo_sync_tb.sv:185.9-185.39` | Multi-entry write-ready must drop when full or under reset bookkeeping. | timeout | 21 |
| `prim_fifo_sync_tb.sv:186.9-186.39` | Non-pass multi-entry read-valid must depend only on stored occupancy. | timeout | 21 |
| `prim_fifo_sync_tb.sv:187.9-187.50` | Non-pass multi-entry read data must come from the reference head. | timeout | 21 |
| `prim_fifo_sync_tb.sv:197.9-197.31` | OutputZeroIfEmpty must drive zero on empty non-pass multi-entry FIFO. | timeout | 21 |
| `prim_fifo_sync_tb.sv:231.9-231.48` | Read-handshake from stored contents must require positive occupancy. | timeout | 21 |
| `prim_fifo_sync_tb.sv:232.9-232.69` | Read-handshake from stored contents must return reference head data. | timeout | 21 |
| `prim_fifo_sync_tb.sv:249.11-249.47` | Write-only handshake must not occur when the FIFO is full. | timeout | 21 |
| `prim_fifo_sync_tb.sv:252.13-252.46` | Read-only handshake must not occur when the FIFO is empty. | timeout | 21 |
| `prim_fifo_sync_tb.sv:256.13-256.35` | Full FIFO must deassert write-ready. | timeout | 21 |
| `prim_fifo_sync_tb.sv:264.11-264.38` | Reference occupancy must never exceed configured depth. | timeout | 21 |
| `prim_fifo_sync_tb.sv:266.11-266.33` | `depth_o` must track reference occupancy. | timeout | 21 |
| `prim_fifo_sync_tb.sv:267.11-267.44` | Secure mode must not raise `err_o` immediately after reset release. | timeout | 21 |
| `prim_fifo_sync_tb.sv:273.9-273.35` | Occupancy must remain within model bounds after all handshakes. | timeout | 21 |
| `prim_fifo_sync_tb.sv:278.9-278.31` | Model bookkeeping indices must stay in range. | timeout | 21 |
| `prim_fifo_sync_tb.sv:283.9-283.27` | Never-clears assumptions must not corrupt FIFO state accounting. | timeout | 21 |

## Cover Properties

| Instance | Location | Description | Status | Depth |
| --- | --- | --- | --- | --- |
| `u_depth0` | `prim_fifo_sync_tb.sv:396.11-396.23` | Reach a depth-0 simultaneous write/read pass-through transfer. | reached | 3 |
| `u_depth1_nopass` | `prim_fifo_sync_tb.sv:324.11-324.23` | Fill a depth-1 FIFO, read it out, then write again. | reached | 1 |
| `u_depth1_nopass` | `prim_fifo_sync_tb.sv:332.11-332.23` | Clear a full depth-1 FIFO and observe empty depth. | reached | 1 |
| `u_depth1_nopass` | `prim_fifo_sync_tb.sv:407.11-407.23` | Reach OutputZeroIfEmpty behavior while empty. | reached | 3 |
| `u_depth1_pass_secure` | `prim_fifo_sync_tb.sv:311.11-311.23` | Exercise depth-1 pass-through store-then-read sequence. | reached | 1 |
| `u_depth1_pass_secure` | `prim_fifo_sync_tb.sv:324.11-324.23` | Fill a depth-1 FIFO, read it out, then write again. | reached | 1 |
| `u_depth1_pass_secure` | `prim_fifo_sync_tb.sv:332.11-332.23` | Clear a full depth-1 FIFO and observe empty depth. | reached | 1 |
| `u_depth3_pass` | `prim_fifo_sync_tb.sv:339.11-339.23` | Exercise empty pass-through read on a multi-entry FIFO. | reached | 1 |
| `u_depth3_pass` | `prim_fifo_sync_tb.sv:347.11-347.23` | Clear while bypassing on a multi-entry pass-through FIFO. | reached | 1 |
| `u_depth3_pass` | `prim_fifo_sync_tb.sv:363.11-363.23` | Fill multi-entry FIFO to full, read, then write again. | reached | 1 |
| `u_depth3_pass` | `prim_fifo_sync_tb.sv:368.11-368.23` | Exercise simultaneous read/write while partially full. | reached | 1 |
| `u_depth3_pass` | `prim_fifo_sync_tb.sv:376.11-376.23` | Clear a non-empty multi-entry FIFO and observe empty depth. | reached | 1 |
| `u_depth3_pass` | `prim_fifo_sync_tb.sv:384.11-384.23` | Exercise write-pointer wraparound in the reference model. | reached | 1 |
| `u_depth3_pass` | `prim_fifo_sync_tb.sv:407.11-407.23` | Reach OutputZeroIfEmpty behavior while empty. | reached | 3 |
| `u_depth4_nopass_secure` | `prim_fifo_sync_tb.sv:363.11-363.23` | Fill multi-entry FIFO to full, read, then write again. | reached | 1 |
| `u_depth4_nopass_secure` | `prim_fifo_sync_tb.sv:368.11-368.23` | Exercise simultaneous read/write while partially full. | reached | 1 |
| `u_depth4_nopass_secure` | `prim_fifo_sync_tb.sv:376.11-376.23` | Clear a non-empty multi-entry FIFO and observe empty depth. | reached | 1 |
| `u_depth4_nopass_secure` | `prim_fifo_sync_tb.sv:384.11-384.23` | Exercise write-pointer wraparound in the reference model. | reached | 1 |
