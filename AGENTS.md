# AGENTS.md

## Purpose

This repository is used for a formal-verification workflow where an agent starts from available design documentation and RTL, then produces a verification-ready understanding of the design and a SystemVerilog formal harness.

The work must always be executed in exactly these 3 steps:

1. Create a golden specification.
2. Convert the golden specification into a verification testplan.
3. Convert the testplan into a SystemVerilog formal testbench.

Do not skip steps. Each step is an explicit input to the next one.

## General Operating Rules

- Keep the instructions generic and reusable across designs.
- Treat the written specification as potentially incomplete, ambiguous, or stale.
- Treat the RTL as an implementation source of truth for current behavior, but not automatically as the full design intent.
- Reconcile documentation and RTL deliberately. If they disagree, document the discrepancy and justify the chosen interpretation.
- Do not jump directly into writing assertions or testbench code before the golden specification and testplan exist.
- Prefer documenting uncertainty over silently guessing.

## Inputs

When starting the task, inspect the repository for:

- The primary design specification or requirements document
- The RTL files for the DUT and its supporting modules/packages
- Any existing verification collateral, interface definitions, or parameter documentation

The agent should identify the DUT being verified and then use the available spec and RTL together to build a complete verification view.

## Required Outputs

Produce the artifacts in this order:

1. `golden_spec.md`
2. `testplan.md`
3. `formal/<dut>_tb.sv`

If helper files are needed, keep them under `formal/`.

## Step 1: Golden Specification

Goal: create a complete, implementation-aware specification that captures the major functionality and intended behavior of the DUT.

The golden specification must include:

- DUT name and high-level purpose
- All parameters and configuration modes that affect behavior
- All interfaces, ports, I/Os, widths, directions, and reset behavior
- Interface protocols and legal transaction rules
- Functional behavior in normal and corner-case operation
- Observable state/accounting signals, if present
- Error reporting, exception behavior, or fault-detection behavior, if present
- Any environment assumptions that are required to interpret the design correctly
- Any ambiguities, omissions, or contradictions found in the original specification

The golden specification should:

- Cover all major functionalities and design intent
- Distinguish between facts derived from documentation, facts derived from RTL, and inferred intent
- Call out unresolved gaps explicitly
- State the chosen resolution for each important gap and explain why

The output should be strong enough that another engineer can understand what the DUT is supposed to do without first reading the RTL.

## Step 2: Testplan

Goal: convert the golden specification into a verification plan written in English.

The testplan must be requirement-driven. Each item should trace back to one or more golden-spec requirements and have a stable identifier.

For each testplan item, describe:

- What behavior is being verified
- Why it matters
- Verification method
- Expected proof target, observation, or completion criteria

Verification methods may include:

- Assertions
- Assumptions
- Covers
- Reference model or scoreboard checks
- Helper state or helper logic

The testplan should cover:

- Interface correctness
- Reset and initialization behavior
- Nominal data/control flow
- Boundary and corner cases
- Parameter-dependent or mode-dependent behavior
- Error handling or fault detection, if applicable
- Illegal or unreachable scenarios that should be constrained by assumptions
- End-to-end intent, not just local signal behavior

The testplan should also say which requirements are best handled with direct SVA properties and which are better checked with a reference model or auxiliary logic.

## Step 3: SystemVerilog Formal Testbench

Goal: implement the testplan as a readable, traceable SystemVerilog formal harness.

The formal testbench should:

- Instantiate the DUT
- Set up clock and reset behavior appropriate for formal verification
- Model only justified environment assumptions
- Implement assertions, assumptions, and covers that trace back to testplan IDs
- Use helper logic or a lightweight reference model where direct properties are not the best fit
- Stay focused on externally visible architectural behavior unless internal knowledge is necessary for a sound proof

The testbench should be written with these principles:

- Keep assumptions minimal
- Do not assume away meaningful bugs
- Prefer clarity and traceability over cleverness
- Use parameterized or generated structure when multiple configurations require different checks
- Add short comments linking key properties to testplan items

Unless explicitly requested, do not modify the RTL just to make proofs pass. If the implementation appears buggy or inconsistent with the golden specification, document that as a finding.

## Review Checklist

Before finishing, confirm all of the following:

- `golden_spec.md` captures interfaces, I/Os, parameters, modes, and major behavior
- Specification gaps or ambiguities are clearly identified and resolved or flagged
- `testplan.md` traces back to the golden specification
- `formal/<dut>_tb.sv` traces back to the testplan
- Normal behavior, corner cases, and configuration-dependent behavior are all covered
- Assumptions are explicit and justified
- The final harness is readable enough for a reviewer to audit requirement-to-property traceability

## Definition Of Done

The task is complete only when:

1. The golden specification provides a coherent and reviewable statement of intended DUT behavior.
2. The testplan describes the full formal verification intent in English.
3. The SystemVerilog formal testbench implements that plan with traceable properties and supporting logic.

If uncertainty remains, document it directly in the artifacts rather than hiding it in implementation choices.
