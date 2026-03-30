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
- Follow the formal testbench coding conventions in [coding_guidelines.md](/Users/pradip/Documents/ChipAgents/fv_takehome/coding_guidelines.md) when implementing step 3 artifacts.

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
- Priority based on the criticality of the behavior and the likelihood that a failure would correspond to a real bug
- Verification method
- Expected proof target, observation, or completion criteria

Each testplan item must include a priority label. Use a simple ordered scale such as `P0`, `P1`, `P2`, and `P3`, where lower numbers indicate higher priority. Assign priority by considering both:

- How critical the behavior is to correct architectural or safety-relevant operation
- How likely a failure in this area is to expose a meaningful real-world design bug rather than a purely theoretical issue

Document the rationale for the chosen priority briefly enough that a reviewer can understand why the item was ranked at that level.

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

Functional coverage planned through `cover` properties or equivalent formal cover goals must explicitly exercise the identified corner-case scenarios of the design. Do not limit cover planning to only nominal flows; include covers for meaningful boundary conditions, rare mode combinations, exceptional but legal behaviors, and other edge situations called out by the golden specification.

The testplan should also say which requirements are best handled with direct SVA properties and which are better checked with a reference model or auxiliary logic.

## Step 3: SystemVerilog Formal Testbench

Goal: implement the testplan as a readable, traceable SystemVerilog formal harness.

The formal testbench should:

- Instantiate the DUT
- Set up clock and reset behavior appropriate for formal verification
- Model only justified environment assumptions
- Implement assertions, assumptions, and covers that trace back to testplan IDs
- Use helper logic or a lightweight reference model where direct properties are not the best fit
- Use a structured FPV setup where checks for each interface are placed in separate helper files, end-to-end checks are placed in separate helper files, and parameter-specific checks are placed in separate helper files as appropriate
- Keep shared reference logic, scoreboarding helpers, and top-level orchestration in `formal/<dut>_tb.sv` unless there is a strong reason to factor them further
- Stay focused on externally visible architectural behavior unless internal knowledge is necessary for a sound proof

The testbench should be written with these principles:

- Keep assumptions minimal
- Do not assume away meaningful bugs
- Prefer clarity and traceability over cleverness
- Use parameterized or generated structure when multiple configurations require different checks
- Organize the harness so reviewers can navigate interface-local checks, end-to-end intent checks, and parameter-dependent checks independently
- Add short comments linking key properties to testplan items
- Follow the property, reset-modeling, and symbolic-input conventions in [coding_guidelines.md](/Users/pradip/Documents/ChipAgents/fv_takehome/coding_guidelines.md)

Unless explicitly requested, do not modify the RTL just to make proofs pass. If the implementation appears buggy or inconsistent with the golden specification, document that as a finding.

## Review Checklist

Before finishing, confirm all of the following:

- `golden_spec.md` captures interfaces, I/Os, parameters, modes, and major behavior
- Specification gaps or ambiguities are clearly identified and resolved or flagged
- `testplan.md` traces back to the golden specification
- Every testplan item has an explicit priority with rationale based on criticality and real-bug likelihood
- `formal/<dut>_tb.sv` traces back to the testplan
- Normal behavior, corner cases, and configuration-dependent behavior are all covered
- Functional cover goals include the important corner-case scenarios identified for the design
- Assumptions are explicit and justified
- The FPV harness structure cleanly separates interface checks, end-to-end checks, and parameter-specific checks, with shared reference logic remaining in the top testbench
- The final harness is readable enough for a reviewer to audit requirement-to-property traceability

## Definition Of Done

The task is complete only when:

1. The golden specification provides a coherent and reviewable statement of intended DUT behavior.
2. The testplan describes the full formal verification intent in English.
3. The SystemVerilog formal testbench implements that plan with traceable properties and supporting logic.

If uncertainty remains, document it directly in the artifacts rather than hiding it in implementation choices.
