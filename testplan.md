# Formal Verification Testplan: `prim_fifo_sync`

## Scope

This is the step-2 verification plan derived from [golden_spec.md](/Users/pradip/Documents/ChipAgents/fv_takehome/golden_spec.md). It translates the `GS-*` requirements into formal verification intent for a SystemVerilog harness.

The plan is requirement-driven: every item below traces back to the golden specification and identifies the preferred verification method.

## Verification Strategy

The DUT has materially different behavior in three implementation regimes:

- `Depth == 0`
- `Depth == 1`
- `Depth > 1`

The formal environment should therefore verify multiple parameter configurations rather than relying on a single instantiation. At minimum, the plan should exercise:

- one `Depth == 0` configuration
- one `Depth == 1` configuration with `Pass == 0`
- one `Depth == 1` configuration with `Pass == 1`
- one `Depth > 1` configuration with `Pass == 0`
- one `Depth > 1` configuration with `Pass == 1`
- at least one `Depth > 1` non-power-of-two depth such as `3` or `5` to exercise pointer wrap math beyond trivial power-of-two cases
- `OutputZeroIfEmpty` both enabled and disabled where the parameter is effective
- `Secure` both enabled and disabled where the parameter is implemented
- `NeverClears` both enabled and disabled where clear behavior is in scope

## Recommended Helper Logic

The testbench should define helper events and reference state used across multiple properties:

- `wr_hs`: accepted write handshake
- `rd_hs`: accepted read handshake
- reference occupancy counter
- reference FIFO queue / scoreboard for stored data ordering
- optional “bypass-active” helper for pass-through empty cases
- helper predicates for `is_depth0`, `is_depth1`, `is_depth_gt1`, `is_pass_mode`, `is_secure_mode`, and `is_zero_if_empty`

Direct SVA is preferred for handshakes, mode gating, reset/clear behavior, and simple occupancy relations. A small reference model is preferred for data ordering, no-loss/no-duplication checks, and selected occupancy/dataflow cross-checks.

## Testplan Items

| ID | Golden Spec | Behavior To Verify | Why It Matters | Method | Expected Proof Target / Observation |
|---|---|---|---|---|---|
| `TP-01` | `GS-01` `GS-02` `GS-03` `GS-04` | Parameter legality and derived-width assumptions are consistent with the supported DUT operating space. | Prevents meaningless proofs over invalid elaborations. | Assumptions plus elaboration-time checks. | Formal runs are restricted to legal configurations, especially `Depth == 0 -> Pass == 1`. |
| `TP-02` | `GS-54` `GS-55` `GS-57` | When `NeverClears == 1`, `clr_i` is never asserted. | This is an explicit architectural contract and must not be left unconstrained. | Assumption. | `clr_i` is held low in all cycles for `NeverClears` configurations. |
| `TP-03` | `GS-56` | Reset is treated as initialization, not a required traffic phase. | Avoids proving behavior that the golden spec deliberately leaves out of scope. | Assumption. | No meaningful protocol obligations are imposed while `rst_ni == 0`. |
| `TP-04` | `GS-05` `GS-06` | Accepted write and read events occur exactly on `wvalid_i && wready_o` and `rvalid_o && rready_i`. | These handshake definitions anchor all downstream properties and helper logic. | Assertions plus helper signals. | All reference-model updates and temporal properties key off the same acceptance definitions as the DUT contract. |
| `TP-05` | `GS-08` `GS-09` `GS-59` | `depth_o`, `full_o`, and `wready_o` are related correctly, without assuming they are identical concepts. | The design intentionally separates occupancy-full from write acceptance in some modes. | Assertions. | Properties distinguish capacity state from immediate readiness, including `Depth == 0` and reset-holdoff cases. |
| `TP-06` | `GS-11` `GS-58` | Invalid read data is only checked when architecturally meaningful. | Prevents false failures from stale storage exposure when zeroing is disabled. | Assumption plus selective assertion enable conditions. | Data-value properties are gated by `rvalid_o` or by zero-if-empty obligations. |
| `TP-07` | `GS-12` `GS-13` `GS-14` `GS-15` `GS-16` `GS-17` `GS-18` `GS-19` `GS-20` | `Depth == 0` acts as a pure pass-through path with constant `depth_o == 0`, constant `full_o == 1`, `err_o == 0`, ignored `clr_i`, and no storage behavior. | This regime is structurally different from a normal FIFO and must be verified separately. | Direct assertions plus covers. | Pass-through interface equations hold in all cycles for `Depth == 0`; a cover should witness a successful end-to-end transfer (`wvalid_i && rready_i`). |
| `TP-08` | `GS-21` `GS-22` `GS-23` `GS-24` | `Depth == 1` occupancy, valid, ready, and data-select behavior match the singleton implementation. | The singleton logic is specialized and should not be assumed to behave like the generic FIFO. | Direct assertions. | `full_o`, `depth_o`, `wready_o`, `rvalid_o`, and `rdata_o` follow the singleton equations in both pass and non-pass modes. |
| `TP-09` | `GS-25` `GS-26` | In `Depth == 1`, an empty pass-through write becomes immediately readable; if not read, it becomes stored for the next cycle. | This is a key latency/bypass behavior and a likely bug surface. | Assertions plus cover. | A cover should witness empty bypass with `rready_i == 0`, followed by the datum being retained and later read. |
| `TP-10` | `GS-27` | In `Depth == 1`, a full FIFO cannot accept a same-cycle replacement write during a read. | Distinguishes singleton behavior from deeper FIFOs and prevents over-optimistic assumptions. | Assertion plus cover. | When full, `wready_o == 0` regardless of `rready_i`; a cover should witness “read while full” followed by write acceptance one cycle later. |
| `TP-11` | `GS-28` `GS-29` | In `Depth == 1`, reset and clear empty logical occupancy without implying cleared storage bits. | Ensures proofs align with logical validity rather than stale register contents. | Assertions. | After reset or clear, occupancy drops to empty; data-value checks remain valid-qualified. |
| `TP-12` | `GS-32` `GS-33` `GS-34` `GS-35` | For `Depth > 1`, pointer-driven occupancy, `full_o`, and `wready_o` behave correctly, including reset holdoff via `under_rst`. | This is the core control behavior of the general FIFO. | Direct assertions. | `depth_o` stays in range, `full_o` corresponds to full occupancy, and `wready_o` is suppressed during reset holdoff. |
| `TP-13` | `GS-36` `GS-44` | For `Depth > 1` and `Pass == 1`, an empty FIFO can bypass `wdata_i` to the read side, but only outside reset holdoff. | Captures the most important mode-dependent latency behavior in the general implementation. | Assertions plus cover. | A cover should show same-cycle empty bypass; an assertion should show bypass is suppressed during `under_rst`. |
| `TP-14` | `GS-37` `GS-45` | For `Depth > 1` and `Pass == 0`, the first read must come from stored data after a prior accepted write, and no bypass path is exposed. | Distinguishes architectural latency between pass and non-pass modes. | Assertions plus cover. | No read is valid from an empty FIFO; a cover should show write-then-read with at least one-cycle storage latency. |
| `TP-15` | `GS-38` | In pass-through mode with an empty `Depth > 1` FIFO, simultaneous write/read may occur while stored occupancy remains zero. | This is a subtle but architecturally important special case. | Assertions plus cover. | Same-cycle bypass transfer does not falsely increment retained occupancy. |
| `TP-16` | `GS-39` | In a non-empty, non-full `Depth > 1` FIFO, simultaneous accepted read and write preserve occupancy while advancing dataflow. | This is a common steady-state operating mode and must not corrupt depth tracking. | Assertion plus reference-model cross-check. | Reference occupancy is unchanged across simultaneous transfer cycles; subsequent read order remains correct. |
| `TP-17` | `GS-40` | A full `Depth > 1` FIFO cannot perform same-cycle read-and-replace. | Prevents an incorrect assumption that “read frees space soon enough” within the same cycle. | Assertion plus cover. | When full, `wready_o == 0`; a cover should show full, then read, then write accepted in a later cycle. |
| `TP-18` | `GS-41` `GS-49` | `clr_i` flushes logical occupancy in stateful regimes while not requiring storage bits to be zeroed. | Clear behavior is externally important and easy to mis-specify. | Assertions plus targeted covers. | After a clear edge, occupancy becomes empty; covers should exercise clear during idle, clear after filling, and clear concurrent with pass-through visibility. |
| `TP-19` | `GS-46` `GS-47` `GS-48` | Reset empties logical occupancy and resets error state where implemented, without over-asserting reset values on stale data outputs. | Aligns formal checks with the actual reset semantics of the RTL. | Assertions. | Occupancy-related outputs converge to empty-state behavior after reset; no property incorrectly requires all raw storage bits to reset. |
| `TP-20` | `GS-24` `GS-42` | `OutputZeroIfEmpty` forces `rdata_o == 0` exactly in the regimes and cycles where the golden spec says it is effective. | This parameter is externally visible and differs by regime. | Assertions. | Zeroing occurs when empty for `Depth == 1` and `Depth > 1` as specified; no zeroing obligation is imposed for `Depth == 0`. |
| `TP-21` | `GS-07` `GS-10` | Accepted writes are eventually observable in FIFO order on accepted reads, with no loss or duplication of stored entries. | This is the core end-to-end function of the FIFO. | Reference model / scoreboard checks. | The sequence of read data matches the sequence of accepted write data after accounting for pass-through and clear/reset flush rules. |
| `TP-22` | `GS-08` `GS-21` `GS-32` `GS-33` | `depth_o` matches reference occupancy accounting across writes, reads, simultaneous transfers, clear, and reset. | Occupancy bugs are common and directly affect protocol behavior. | Reference occupancy model plus assertions. | `depth_o` equals the modeled number of stored entries in each configuration where the signal is architecturally meaningful. |
| `TP-23` | `GS-50` | When `Secure == 0`, `err_o` must remain zero. | Establishes the non-secure baseline and catches accidental error leakage. | Direct assertions. | `err_o == 0` in all non-secure configurations. |
| `TP-24` | `GS-31` `GS-51` `GS-52` `GS-53` | Secure-mode behavior is limited to integrity alarm propagation, not generic protocol checking. | Avoids claiming proof targets that the local repository cannot justify. | Assertions plus optional fault-injection strategy note. | At minimum, secure mode should prove reset-low behavior and correct signal plumbing; positive alarm triggering may be an optional extension if hardened primitive fault injection is available. |
| `TP-25` | `GS-15` `GS-32` `GS-33` `GS-38` `GS-39` `GS-40` | Boundary occupancy behavior is exercised at empty, singleton, almost-full, full, and wraparound points. | Corner cases around boundaries are where most FIFO bugs appear. | Covers plus assertions. | Covers should witness empty bypass, first fill, reaching full, full-to-not-full via read, simultaneous rd/wr in steady state, and pointer wrap for `Depth > 1`. |
| `TP-26` | `D-01` `D-02` `D-03` `D-04` `D-05` `D-06` `D-07` `D-08` | All discrepancy resolutions from the golden spec are represented in formal checks or assumptions. | Ensures step 1 decisions are not lost in implementation. | Traceability review item backed by assertions/assumptions/covers above. | Every documented ambiguity is either proven, constrained, or intentionally left as a documented non-goal. |

## Items Best Proven With Direct Assertions

These are strongest and simplest as local SVA properties:

- parameter legality and configuration gating
- handshake definitions
- `Depth == 0` interface equations
- `Depth == 1` occupancy/ready/valid equations
- `Depth > 1` reset holdoff and pass/no-pass mode gating
- full/empty/write-ready boundary relations
- zero-if-empty behavior
- non-secure `err_o == 0`
- reset/clear convergence to empty-state behavior

## Items Best Proven With A Reference Model

These are best implemented with helper state rather than purely local temporal formulas:

- FIFO ordering
- no loss / no duplication
- occupancy tracking across long sequences
- simultaneous read/write depth preservation
- pass-through versus stored-data disambiguation across mixed traffic
- pointer-wrap scenarios for `Depth > 1`

## Coverage Goals

The harness should include covers that demonstrate the formal search can reach the main architectural scenarios:

- empty pass-through transfer
- stored write followed by later read
- simultaneous read/write in steady state
- full condition
- clear after non-empty state
- reset release followed by resumed traffic
- `Depth > 1` pointer wrap
- `Depth == 1` blocked replacement write while full
- `OutputZeroIfEmpty` active on an empty cycle

## Step-3 Exit Criteria

Step 3 should be considered complete only when the SystemVerilog formal testbench contains traceable implementation for every `TP-*` item above, with each item realized as one or more assertions, assumptions, covers, or reference-model checks.
