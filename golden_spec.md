# Golden Specification: `prim_fifo_sync`

## Scope

This document is the step-1 golden specification for the DUT implemented in:

- `spec.md`
- `rtl/prim_fifo_sync.sv`
- `rtl/prim_fifo_sync_cnt.sv`
- `rtl/prim_util_pkg.sv`

Its purpose is to reconcile the prose specification with the RTL and produce a verification-ready description of intended behavior.

## Confidence Legend

- `P` = directly stated in the prose specification
- `R` = directly observed in RTL
- `I` = inferred design intent or chosen resolution for an ambiguity

## DUT Summary

`prim_fifo_sync` is a parameterized synchronous FIFO with valid/ready write and read interfaces. Depending on parameterization, it behaves as:

- a pure pass-through path when `Depth == 0`
- a specialized one-entry FIFO when `Depth == 1`
- a pointer-based FIFO when `Depth > 1`

The design supports optional pass-through on an empty FIFO, optional zeroing of invalid read data, an optional environment contract forbidding `clr_i`, and an optional hardened error-detection mode. Source: `P+R`.

## Parameters

| Name | Type | Default | Meaning | Source |
|---|---|---:|---|---|
| `Width` | `int unsigned` | `16` | Data width of `wdata_i` and `rdata_o`. Legal operating configurations require `Width >= 1`. | `P+R+I` |
| `Pass` | `bit` | `1'b1` | Enables pass-through behavior when the FIFO is empty. | `P+R` |
| `Depth` | `int unsigned` | `4` | Number of storable FIFO entries. Special implementations exist for `Depth == 0` and `Depth == 1`. | `P+R` |
| `OutputZeroIfEmpty` | `bit` | `1'b1` | When effective, invalid/empty read data is forced to zero instead of reflecting stale storage contents. | `P+R` |
| `NeverClears` | `bit` | `1'b0` | Declares that `clr_i` is never asserted. This is an environment contract, not a different external interface. | `R+I` |
| `Secure` | `bit` | `1'b0` | Enables hardened state/error detection logic for occupancy tracking. | `P+R` |
| `DepthW` | `localparam int` | `prim_util_pkg::vbits(Depth+1)` | Width of `depth_o`, sized to represent values in `[0, Depth]`. | `R` |

### Parameter Legality

- `GS-01` Legal configurations require `Width >= 1`. Zero-width data ports are not a meaningful operating point even though `Width` is declared as unsigned. Source: `I`.
- `GS-02` `Depth >= 0` is legal. Source: `R`.
- `GS-03` If `Depth == 0`, then `Pass` must be `1`. The RTL contains an elaboration-time assertion enforcing this. Source: `R`.
- `GS-04` `DepthW = prim_util_pkg::vbits(Depth+1)`, where `vbits(1) = 1` and otherwise `vbits(x) = ceil(log2(x))`. Therefore:
  - `Depth == 0` gives `DepthW == 1`
  - `Depth == 1` gives `DepthW == 1`
  - larger depths size `depth_o` to hold all values from `0` through `Depth`
  Source: `R`.

## Ports And Interfaces

| Port | Dir | Width | Meaning | Source |
|---|---|---|---|---|
| `clk_i` | input | 1 | Main clock. State changes occur on the positive edge. | `P+R` |
| `rst_ni` | input | 1 | Active-low asynchronous reset for occupancy/control state. | `P+R` |
| `clr_i` | input | 1 | Synchronous clear / flush request. Effect depends on `NeverClears` and FIFO regime. | `P+R` |
| `wvalid_i` | input | 1 | Write-side valid. | `P+R` |
| `wready_o` | output | 1 | Write-side ready / acceptance qualification. | `P+R` |
| `wdata_i` | input | `[Width-1:0]` | Write-side payload. Only sampled on an accepted write. | `P+R+I` |
| `rvalid_o` | output | 1 | Read-side valid / data availability indication. | `P+R` |
| `rready_i` | input | 1 | Read-side ready. | `P+R` |
| `rdata_o` | output | `[Width-1:0]` | Read-side payload. Meaningful when `rvalid_o == 1`, or when explicitly forced to zero by `OutputZeroIfEmpty`. | `P+R+I` |
| `full_o` | output | 1 | Occupancy-full indication, not always identical to write acceptance. | `P+R+I` |
| `depth_o` | output | `[DepthW-1:0]` | Observable occupancy count, except that the `Depth == 0` implementation hardwires it to zero and comments it as “meaningless.” | `P+R+I` |
| `err_o` | output | 1 | Error indication used only in hardened modes. Otherwise zero. | `P+R` |

## Global Behavioral Rules

- `GS-05` A write transaction is accepted on a clock edge when `wvalid_i && wready_o` is true in that cycle. Source: `P+R`.
- `GS-06` A read transaction is accepted on a clock edge when `rvalid_o && rready_i` is true in that cycle. Source: `P+R`.
- `GS-07` FIFO ordering is first-in, first-out for stored entries. No stored datum may be duplicated or re-ordered. Source: `P+I`.
- `GS-08` `depth_o` is the number of stored entries, not the number of combinationally visible pass-through items. In pass-through empty cases, data may be readable while `depth_o` remains zero. Source: `R+I`.
- `GS-09` `full_o` indicates stored-capacity fullness, not necessarily “cannot accept a write in this cycle.” In particular:
  - `Depth == 0`: `full_o` is hardwired high but writes may still pass through when `rready_i` is high
  - `Depth > 1`: `wready_o` is additionally suppressed during reset holdoff
  Source: `R+I`.
- `GS-10` Unless a stronger protocol is added externally, `wdata_i` only needs to be semantically correct in cycles where a write is accepted. Source: `I`.
- `GS-11` When `OutputZeroIfEmpty == 0`, `rdata_o` is not guaranteed meaningful while `rvalid_o == 0`; it may reflect stale or uninitialized storage. Source: `R+I`.

## Regime 1: `Depth == 0`

This is not a storage FIFO. It is a pure pass-through connection with handshake adaptation.

- `GS-12` `rvalid_o = wvalid_i`. Source: `R`.
- `GS-13` `rdata_o = wdata_i`. Source: `R`.
- `GS-14` `wready_o = rready_i`. Source: `R`.
- `GS-15` `depth_o` is hardwired to zero. The RTL comment says the output is “meaningless”; the chosen interpretation for verification is that there is no stored occupancy and the observable value is always zero. Source: `R+I`.
- `GS-16` `full_o` is hardwired to `1`. Chosen interpretation: because capacity is zero, the occupancy-full predicate is vacuously true even though pass-through transfers can still occur. Source: `R+I`.
- `GS-17` `err_o = 0`. Source: `R`.
- `GS-18` `clr_i` has no behavioral effect in this regime. Source: `R`.
- `GS-19` `OutputZeroIfEmpty` has no effect in this regime. Even when `wvalid_i == 0`, `rdata_o` remains a direct reflection of `wdata_i`, not forced zero. Source: `R`.
- `GS-20` `rst_ni` has no observable dataflow effect in this regime because no state is reset here. Source: `R`.

## Regime 2: `Depth == 1`

This is a specialized one-entry FIFO implemented with a single occupancy bit and one storage register.

- `GS-21` Stored occupancy is represented by `full_q`. `full_o = full_q`, `depth_o = full_q`, and `wready_o = ~full_q`. Source: `R`.
- `GS-22` When the single entry is occupied, `rvalid_o = 1`. When it is empty:
  - if `Pass == 1` and `wvalid_i == 1`, `rvalid_o = 1` through bypass
  - if `Pass == 0`, `rvalid_o = 0`
  Source: `R`.
- `GS-23` Read data selection is:
  - stored data when the entry is occupied
  - direct `wdata_i` bypass when empty and `Pass == 1`
  - storage contents when empty and `Pass == 0`, which is only meaningful if separately zeroed by `OutputZeroIfEmpty`
  Source: `R`.
- `GS-24` `OutputZeroIfEmpty` is applied using `!rvalid_o` in this regime. Therefore:
  - if `OutputZeroIfEmpty == 1` and `rvalid_o == 0`, `rdata_o` is zero
  - otherwise `rdata_o` reflects either storage or pass-through data
  Source: `R`.
- `GS-25` A write accepted while empty and not simultaneously read stores the datum and makes the FIFO full on the next cycle, unless `clr_i` is asserted. Source: `R+I`.
- `GS-26` If `Pass == 1`, an empty FIFO may present `wdata_i` to the read side in the same cycle. If `rready_i` is low, that datum becomes stored for a later cycle. If `rready_i` is high, it may be consumed immediately and the FIFO can remain empty. Source: `R`.
- `GS-27` When already full, the FIFO does not accept a same-cycle replacement write during a read because `wready_o` remains low while occupied. Source: `R`.
- `GS-28` `clr_i` synchronously empties the stored occupancy bit on the next clock edge. The storage register itself is not cleared. Therefore stale data may remain physically stored but is not logically valid unless re-selected while `rvalid_o == 1`. Source: `R+I`.
- `GS-29` `rst_ni` asynchronously clears the occupancy bit and resets the secure error register, but it does not reset the storage register. In pass-through mode, `wvalid_i` may still drive `rvalid_o` and `rdata_o` combinationally while reset is active. Source: `R`.
- `GS-30` If `Secure == 0`, `err_o = 0`. Source: `R`.
- `GS-31` If `Secure == 1`, `err_o` reports a registered mismatch between the occupancy bit and an inverted duplicate copy. Chosen interpretation: this is an integrity/fault-detection alarm on singleton occupancy state, not a protocol error indicator. Source: `R+I`.

## Regime 3: `Depth > 1`

This is the general FIFO implementation with pointer-based occupancy tracking.

- `GS-32` Stored occupancy is tracked by read and write wrap counters. `depth_o` is computed from those counters and ranges from `0` to `Depth`. Source: `R`.
- `GS-33` `full_o` is asserted exactly when the stored occupancy is `Depth`. `fifo_empty` is asserted exactly when stored occupancy is `0`. Source: `R`.
- `GS-34` `wready_o = ~full_o & ~under_rst`. Therefore write acceptance is suppressed both when the FIFO is full and during reset holdoff. Source: `R`.
- `GS-35` The implementation includes a one-cycle post-reset holdoff bit `under_rst`. It is set asynchronously by reset and remains high through the first rising clock edge after reset deassertion, then drops low. Source: `R`.
- `GS-36` In pass-through mode (`Pass == 1`):
  - if the stored FIFO is empty and `wvalid_i == 1`, `rdata_o` uses `wdata_i`
  - `rvalid_o` asserts for this bypass case only when `under_rst == 0`
  - the FIFO is considered logically empty only when `fifo_empty == 1` and `wvalid_i == 0`
  Source: `R`.
- `GS-37` In non-pass-through mode (`Pass == 0`):
  - `rdata_o` always comes from storage
  - `rvalid_o = ~fifo_empty`
  - at least one accepted write is required before the first valid read
  Source: `P+R`.
- `GS-38` In pass-through mode with an empty FIFO, simultaneous write/read handshakes are allowed. In that case the data may be consumed directly while `depth_o` remains zero after the cycle. Source: `R+I`.
- `GS-39` When the FIFO is non-empty and non-full, simultaneous accepted read and write increment both pointers and preserve occupancy count. Source: `R+I`.
- `GS-40` When the FIFO is full, `wready_o` is low even if `rready_i` is high. Therefore a full FIFO cannot perform a same-cycle read-and-replace write. Occupancy decreases only after the read completes. Source: `R`.
- `GS-41` `clr_i` synchronously resets pointer state to empty in the next cycle. The storage array is not cleared. Therefore `depth_o` becomes zero after clear, but stale data may remain in memory locations that are no longer logically valid. Source: `R+I`.
- `GS-42` `OutputZeroIfEmpty` is applied to the regime-specific `empty` signal:
  - in pass-through mode, the output is zero only when stored-empty and no bypass write is present
  - in non-pass-through mode, the output is zero whenever the FIFO is empty
  Source: `R`.
- `GS-43` `rst_ni` asynchronously resets pointer state to empty. Because storage is not reset, `rdata_o` is only architecturally meaningful after reset when `rvalid_o == 1` or when zeroing is active. Source: `R+I`.
- `GS-44` For `Pass == 1`, `under_rst` suppresses both `wready_o` and `rvalid_o` during active reset and for one additional cycle after reset release. Source: `R`.
- `GS-45` For `Pass == 0`, `rvalid_o` is not explicitly gated by `under_rst`; it remains low after reset because the FIFO is empty, while `wready_o` is still held low for one additional cycle. Source: `R+I`.

## Reset And Clear Semantics

- `GS-46` Asynchronous reset empties the FIFO’s logical occupancy state in all stateful regimes (`Depth >= 1`). Source: `P+R`.
- `GS-47` No regime clears all stored data bits on reset or clear. Reset and clear affect logical validity/occupancy, not physical memory contents. Source: `R`.
- `GS-48` Because some outputs are combinational and some storage is not reset, the prose statement “all outputs return to their reset values” is too strong as a universal claim. The chosen resolution is:
  - occupancy-related outputs reset to the empty state
  - `err_o` resets low where implemented
  - `rdata_o` is only guaranteed when `rvalid_o == 1` or when explicitly zeroed by `OutputZeroIfEmpty`
  - pass-through paths may still reflect live inputs during reset in `Depth == 0` and `Depth == 1`
  Source: `P+R+I`.
- `GS-49` `clr_i` is a synchronous flush of logical FIFO contents. If pass-through logic is active in the same cycle, data may still be visible combinationally on `rdata_o`; however, stored occupancy after the clock edge is empty. Source: `R+I`.

## Secure / Error Behavior

- `GS-50` If `Secure == 0`, then:
  - `err_o = 0` for `Depth == 0`
  - `err_o = 0` for `Depth == 1`
  - `err_o = 0` for `Depth > 1`
  Source: `R`.
- `GS-51` If `Secure == 1` and `Depth == 1`, `err_o` is driven by the singleton occupancy cross-check described in `GS-31`. Source: `R`.
- `GS-52` If `Secure == 1` and `Depth > 1`, `err_o` is the OR of hardened write-pointer and read-pointer counter error outputs. Chosen interpretation: `err_o` indicates integrity problems in occupancy-tracking state, not overflow/underflow protocol misuse by itself. Source: `R+I`.
- `GS-53` The exact internal fault model of `prim_count` is outside this repository, so the golden spec should only require that secure mode surface pointer-state integrity errors through `err_o`, not a stronger undocumented guarantee. Source: `I`.

## `NeverClears` Semantics

- `GS-54` `NeverClears == 1` means the environment must never assert `clr_i`. The RTL includes assertions enforcing this contract. Source: `R`.
- `GS-55` Chosen verification interpretation: when `NeverClears == 1`, `clr_i` should be treated as an illegal environment input and constrained low in the formal environment. Source: `R+I`.

## Chosen Environment Assumptions

These assumptions are not fully specified by the prose document, but they are the intended operating contract for verification unless a later task explicitly broadens scope.

- `GS-56` The environment does not require meaningful transaction semantics while `rst_ni == 0`. Verification may treat active reset as a state-initialization phase rather than a normal traffic phase. Source: `I`.
- `GS-57` When `NeverClears == 1`, `clr_i` is always low. Source: `R+I`.
- `GS-58` The environment may treat `rdata_o` as don’t-care whenever `rvalid_o == 0` and `OutputZeroIfEmpty == 0`. Source: `R+I`.
- `GS-59` The environment should not infer that `full_o` and `~wready_o` are equivalent in all configurations. Source: `R+I`.

## Discrepancies And Resolutions

| ID | Topic | Prose Spec | RTL Behavior | Chosen Resolution |
|---|---|---|---|---|
| D-01 | `NeverClears` | Not mentioned | Explicit parameter and assertions exist | Include `NeverClears` as part of the architectural contract and constrain `clr_i` low when enabled. |
| D-02 | `Depth == 0` | FIFO description implies normal FIFO semantics | Implementation is pure pass-through with `full_o = 1`, `depth_o = 0`, and no state | Treat `Depth == 0` as a legal zero-storage mode, not a conventional FIFO. |
| D-03 | `Depth == 0` `OutputZeroIfEmpty` | Parameter suggests zeroing when empty | Parameter is ineffective in this regime | Specify that the parameter has no effect for `Depth == 0`. |
| D-04 | Reset wording | Says all outputs return to reset values | Some outputs still depend on live inputs or stale storage | Narrow the reset guarantee to logical occupancy/error state and valid-qualified data semantics. |
| D-05 | `full_o` vs `wready_o` | Write interface text suggests ready is tied to fullness | RTL separates them in `Depth == 0` and during `under_rst` | Specify `full_o` as occupancy-full and `wready_o` as actual acceptance qualifier. |
| D-06 | Clear semantics with traffic | Prose only says FIFO is empty after clear | RTL permits same-cycle pass-through visibility while stored occupancy is flushed | Specify clear as flushing stored state for subsequent cycles, not necessarily suppressing same-cycle bypass visibility. |
| D-07 | `Secure` meaning | Says “used in Secure mode” | RTL only exposes pointer/full-state integrity alarms | Limit the architectural guarantee to integrity/error signaling on internal occupancy tracking. |
| D-08 | `depth_o` at `Depth == 0` | Described as current number of entries | RTL hardwires zero and comments it as meaningless | Use constant zero as the verification-visible value, while noting there is no stored occupancy. |

## Completion Note

This document is intended to be the source of truth for step 2. The testplan should trace to the `GS-*` requirements and the discrepancy resolutions above.
