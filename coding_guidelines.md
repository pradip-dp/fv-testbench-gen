# Coding Guidelines

## Scope

This document captures coding-style expectations for formal SystemVerilog testbenches in this repository.

Use these guidelines when implementing step 3 from [AGENTS.md](/Users/pradip/Documents/ChipAgents/fv_takehome/AGENTS.md).

## Property Style

- Use explicit named concurrent properties only.
- Do not use assertion macros in the formal testbench.
- Do not use procedural or immediate `assert`, `assume`, or `cover`.
- Prefer this format for all checks:

```systemverilog
property_name: assert property (
  @(posedge clk_i) disable iff (!rst_ni)
  a |-> b
);
```

- The same structure should be used for assumptions and covers:

```systemverilog
property_name: assume property (
  @(posedge clk_i) disable iff (!rst_ni)
  a |-> b
);

property_name: cover property (
  @(posedge clk_i) disable iff (!rst_ni)
  a |-> ##1 b
);
```

- Do not use `|=>`. Use `|-> ##1` instead when next-cycle behavior is intended.

## Clock And Reset Modeling

- Do not use `initial` blocks in the formal testbench.
- Do not use simulation-style `#` delays for clock or reset startup.
- Model reset behavior with explicit assumptions instead of procedural startup code.
- Use `@(posedge clk_i)` as the clocking event for properties.
- Use `disable iff (!rst_ni)` on assertions and covers unless there is a deliberate reason not to.

## Symbolic Inputs

- Do not rely on tool-specific attributes such as `(* gclk *)` or `(* anyseq *)` in the formal testbench.
- Prefer plain top-level input ports for formal stimulus signals such as:
  - `clk_i`
  - `rst_ni`
  - `clr_i`
  - `wvalid_i`
  - `wdata_i`
  - `rready_i`
- Let the formal tool treat those top-level inputs as symbolic.

## Traceability

- Name properties clearly and consistently.
- Add short comments linking properties to testplan IDs where helpful.
- Keep the harness readable enough that a reviewer can map each property back to the verification plan.

## General Testbench Style

- Keep assumptions minimal and justified.
- Prefer interface-level checks over internal implementation coupling unless internal modeling is necessary.
- Use helper logic or a small reference model when it simplifies end-to-end correctness checks.
- Keep the testbench portable and standard-friendly where possible.
