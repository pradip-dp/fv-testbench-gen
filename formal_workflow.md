# Formal Verification Workflow

This is a generic runbook for taking a design from elaboration through SymbiYosys proof execution and result collation.

## Scope

Assumed inputs:

- RTL for the DUT
- supporting RTL or packages, if required
- formal verification sources such as a harness, helper modules, or assertion packages
- a local Yosys/SymbiYosys toolchain

The `.sby` file is part of the verification collateral and is created from the available RTL and formal files. It is not assumed to exist up front.

Use placeholders like:

- `<rtl files>`
- `<formal files>`
- `<top_module>`
- `<job>.sby`
- `<task_name>`

## 1. Run Elaboration First

Before running proofs, confirm that the DUT and formal sources elaborate cleanly in Yosys.

Example:

```sh
yosys -p 'read_verilog -formal -sv <rtl files> <formal files>; hierarchy -check -top <top_module>; proc; check'
```

Elaboration catches:

- missing files
- bad include paths
- wrong top module
- parameter binding mistakes
- undriven or multiply driven signals
- width mismatches
- unsupported constructs

Do not start SymbiYosys until elaboration is clean.

## 2. Create And Tune The `.sby` File

Create a SymbiYosys job file that:

- lists RTL and formal files
- names the top module
- selects proof mode
- selects engine
- sets depth
- sets timeout
- optionally defines multiple tasks

Minimal example:

```ini
[options]
mode bmc
depth 100
timeout 300

[engines]
smtbmc yices

[script]
read_verilog -formal -sv <rtl files> <formal files>
prep -top <top_module>

[files]
<rtl files>
<formal files>
```

Multi-task example:

```ini
[tasks]
bmc
cover

[options]
bmc: mode bmc
bmc: depth 100
bmc: timeout 300
cover: mode cover
cover: depth 100
cover: timeout 300

[engines]
bmc: smtbmc yices
cover: smtbmc yices
```

Guidelines:

- Use `timeout` in the `.sby` file instead of manually killing jobs.
- Use multiple tasks when separating `bmc`, `cover`, `prove`, or hard parameter sets.
- Verify engine syntax for the installed `SBY` version before relying on engine-specific options.
- `depth 100` in BMC means assertions are checked through step `99`.

## 3. Watch For Common Compatibility Issues

Harness issues:

- guard helper logic that is only valid in some parameter modes
- keep helper-state invariants explicit
- avoid modeling storage or state that does not exist in all configurations
- do not over-model architecturally invisible behavior

Property issues:

- some properties work well in BMC but not induction
- scoreboard-style checks often need extra invariants before `prove` closes
- covers must be legal and reachable in the configurations where they exist
- configuration-specific properties should be structurally gated

Flow issues:

- use `--sequential` for heavy multi-task runs
- split hard configurations into separate tasks when one combined run becomes hard to interpret

## 4. Run Proofs

Single-task run:

```sh
sby -f <job>.sby
```

Specific task:

```sh
sby -f <job>.sby <task_name>
```

Sequential multi-task run:

```sh
sby --sequential -f <job>.sby
```

Recommended order:

1. elaboration only
2. bounded assertions
3. covers
4. unbounded proof, if needed
5. split reruns for hard configurations

## 5. Diagnose Problems Early

If elaboration fails:

- fix structure before touching solver settings

If BMC fails quickly:

- inspect the counterexample first
- check that the failure is not caused by broken helper logic

If cover does not hit:

- look for over-constraint
- verify the cover is legal for that configuration

If `prove` fails but BMC looks healthy:

- add inductive invariants
- simplify or decompose end-to-end checks

If one task dominates runtime:

- split by parameter set, mode, or configuration

## 6. Read Results

Common artifacts:

- `PASS`
- `FAIL`
- `TIMEOUT` or `UNKNOWN`
- `logfile.txt`
- `<task>.xml` or similar machine-readable summary
- traces such as `.vcd` or `.yw`

Interpretation:

- `PASS` for BMC means no assertion failure was found within the explored bound
- `PASS` for cover means all requested cover goals were reached
- `FAIL` means the solver found a counterexample
- `TIMEOUT` means the task stopped at the configured wall-clock limit

## 7. Compile Results

For assertions:

- read `logfile.txt`
- find the last `Checking assertions in step N..`
- report the property set as checked through step `N`

For covers:

- read the log or summary file
- extract the first step where each cover was reached
- report that as the cover depth

For reviewer-facing summaries, include:

- task or configuration name
- property location
- short property description
- status
- depth reached or checked

Reporting conventions:

- say "checked through step N" for assertions
- say "first reached at step N" for covers
- keep `PASS`, `FAIL`, and `TIMEOUT` distinct

## 8. Rerun Guidance

- check for leftover `sby` or solver processes before rerunning
- prefer letting `SBY` terminate jobs through its own timeout handling
- avoid manual kills unless you are abandoning the run
- for reproducible summaries, rerun hard tasks one at a time
