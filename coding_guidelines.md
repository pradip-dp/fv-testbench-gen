# Coding Guidelines

## Scope

This document captures coding-style expectations for formal SystemVerilog testbenches in this repository.

Use these guidelines when implementing step 3 from [AGENTS.md](/Users/pradip/Documents/ChipAgents/fv_takehome/AGENTS.md).

## Property Style

- Target the open-source SymbiYosys/Yosys-supported subset of SystemVerilog formal constructs.
- Do not use assertion macros in the formal testbench.
- Do not use concurrent SVA syntax such as:
  - `assert property (...)`
  - `assume property (...)`
  - `cover property (...)`
  - `disable iff`
  - implication operators such as `|->` or `|=>`
  - sequence delays such as `##1`
- Prefer procedural immediate checks inside clocked `always` / `always_ff` blocks.
- Name checks with nearby comments or stable labels when helpful for traceability.
- Prefer this format for assertions:

```systemverilog
always_ff @(posedge clk_i) begin
  if (rst_ni) begin
    // TP-XX: explain intent
    assert (expr);
  end
end
```

- Use the same style for assumptions and covers:

```systemverilog
always_ff @(posedge clk_i) begin
  if (rst_ni) begin
    assume (expr);
    cover (expr);
  end
end
```

- For next-cycle or temporal intent, use helper state, delayed registers, or `$past(...)` rather than concurrent property syntax.
- Example:

```systemverilog
always_ff @(posedge clk_i) begin
  if (rst_ni) begin
    if ($past(valid_a)) begin
      assert (valid_b);
    end
  end
end
```

- Avoid using `$past(...)` or `$initstate` directly as procedural `if` conditions in stock Yosys when an equivalent helper-valid bit or sampled register can express the same intent more robustly.

## Clock And Reset Modeling

- Do not use `initial` blocks in the formal testbench.
- Do not use simulation-style `#` delays for clock or reset startup.
- Model reset behavior with explicit assumptions instead of procedural startup code.
- Use `@(posedge clk_i)` as the clocking event for formal checks.
- Gate assertions, assumptions, and covers explicitly with `if (rst_ni)` or equivalent reset-valid logic.
- If startup behavior matters, prefer explicit post-reset validity tracking such as `f_past_valid` and sampled prior-cycle registers.
- If `$initstate` is used, keep it in simple assumption expressions and avoid relying on it inside nested procedural control flow.

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
- Add short comments linking checks to testplan IDs where helpful.
- Keep the harness readable enough that a reviewer can map each property back to the verification plan.

## General Testbench Style

- Keep assumptions minimal and justified.
- Prefer interface-level checks over internal implementation coupling unless internal modeling is necessary.
- Use helper logic or a small reference model when it simplifies end-to-end correctness checks.
- Keep the testbench portable and standard-friendly where possible.

## Yosys Syntax Notes

- In package functions, assign to the function name instead of using `return`.

```systemverilog
function automatic integer vbits(integer value);
  vbits = (value == 1) ? 1 : $clog2(value);
endfunction
```

- Prefer unpacked memory declarations over packed multidimensional declarations when writing RTL that must be parsed by Yosys.

```systemverilog
logic [Width-1:0] storage [0:Depth-1];
```

- In formal reference models, prefer flat packed vectors plus explicit muxing over memories when warning-clean `yosys check` results are important.
- If a reference model does use storage, explicitly reset or clear all tracked state so Yosys does not create undriven helper artifacts.
- After significant syntax or modeling changes, run a Yosys elaboration check:

```sh
yosys -p 'read_verilog -formal -sv ...; hierarchy -check -top <tb_top>; proc; check'
```
