# Design & Verification of an Arithmetic-Logic-Shift Unit (ALSU)

A SystemVerilog/UVM verification project for a parameterized 3-bit ALSU (Arithmetic, Logic, Shift, and Rotate Unit), verified using a layered UVM environment, SystemVerilog Assertions (SVA), and functional/code coverage closure on QuestaSim.

---

## Project Structure

```
.
├── rtl/                          # Synthesizable design sources
│   └── ALSU.v                    # Top-level ALSU design
├── tb/                           # UVM verification environment
│   ├── alsu_if.sv                # DUT interface
│   ├── alsu_sva.sv               # SystemVerilog Assertions (bound to DUT)
│   ├── alsu_seq_item.sv          # Sequence item / stimulus class
│   ├── alsu_reset_sequence.sv    # Reset sequence
│   ├── alsu_main_sequence.sv     # Main constrained-random sequence
│   ├── alsu_sequencer.sv
│   ├── alsu_driver.sv
│   ├── alsu_monitor.sv
│   ├── alsu_agent.sv
│   ├── alsu_config_obj.sv        # Config object (virtual interface handle)
│   ├── alsu_scoreboard.sv        # Reference model + checker
│   ├── alsu_coverage.sv          # Functional coverage model
│   ├── alsu_env.sv
│   ├── alsu_test.sv
│   ├── top.sv                    # Testbench top (DUT + SVA bind + UVM run)
│   └── shared_pkg.sv             # Shared enums (opcode_e)
├── sim/                          # Simulation collateral
│   ├── src_files.list            # File compilation order
│   ├── run.do                    # QuestaSim run script (coverage + waves)
│   ├── coverage.txt              # QuestaSim coverage report (code + functional + assertion)
│   └── coverage.ucdb             # QuestaSim coverage database
└── READ_ME.md
```

---

## Design Overview

The Design Under Test (DUT) is a 3-bit-wide **ALSU** that performs arithmetic, logic, shift, and rotate operations on two signed inputs `A` and `B`, with support for:

- **Bypass paths** for `A` and `B` (direct pass-through, evaluated before opcode logic)
- **Bitwise reduction operations** (`red_op_A`, `red_op_B`) that reduce a single operand instead of combining both (valid only for OR and XOR opcodes)
- **Invalid-operation detection**, which toggles a 16-bit `leds` pattern instead of producing an undefined result
- A configurable **full-adder mode** (`FULL_ADDER` parameter) that includes or excludes carry-in on ADD
- A configurable **input priority** (`INPUT_PRIORITY` parameter) that resolves which operand wins when both bypass flags are asserted simultaneously

For SHIFT and ROTATE opcodes, the DUT feeds back the registered `out` value as the shift/rotate register contents, supporting both left/right direction (`direction`) and a serial input bit (`serial_in`) for shift operations.

### Interface

| Signal | Dir | Width | Description |
|---|---|---|---|
| `clk`, `rst` | in | 1 | Clock and synchronous reset |
| `A`, `B` | in | signed [2:0] | Operands |
| `cin` | in | 1 | Carry-in for ADD |
| `opcode` | in | [2:0] | Operation select (see opcode table) |
| `bypass_A`, `bypass_B` | in | 1 | Force output to `A` or `B` directly |
| `red_op_A`, `red_op_B` | in | 1 | Reduce `A` or `B` bitwise (OR-reduce or XOR-reduce depending on opcode) |
| `direction` | in | 1 | Shift/rotate direction (0 = left, 1 = right) |
| `serial_in` | in | 1 | Serial input bit shifted in during SHIFT |
| `leds` | out | [15:0] | Toggling LED pattern while an invalid condition is active |
| `out` | out | signed [5:0] | ALSU result |

All inputs are registered on `posedge clk` before driving `out`, giving the design a **2-cycle observable latency** from applied stimulus to stable output (accounted for in the scoreboard reference model and SVA `# ##2` delays).

### Parameters

| Parameter | Default | Description |
|---|---|---|
| `INPUT_PRIORITY` | `"A"` | When `bypass_A && bypass_B`, select `"A"` or `"B"` |
| `FULL_ADDER` | `"ON"` | When `"ON"`, ADD includes `cin`; otherwise `A + B` only |

### Opcodes

| Opcode | Operation | Behavior |
|---|---|---|
| `3'h0` | OR | `A \| B` (or OR-reduction of `A`/`B` if `red_op_A`/`red_op_B` asserted) |
| `3'h1` | XOR | `A ^ B` (or XOR-reduction of `A`/`B` if `red_op_A`/`red_op_B` asserted) |
| `3'h2` | ADD | `A + B` (+ `cin` if `FULL_ADDER == "ON"`) |
| `3'h3` | MULT | `A * B` |
| `3'h4` | SHIFT | Shift registered `out` left or right; `serial_in` shifted in |
| `3'h5` | ROTATE | Rotate registered `out` left or right |
| `3'h6`, `3'h7` | INVALID | `out` forced to 0; `leds` begin toggling |

### Invalid Operations & Output Priority

An operation is **invalid** when:

- `red_op_A` or `red_op_B` is asserted with an opcode other than OR (`0`) or XOR (`1`), or
- `opcode[1]` and `opcode[2]` are both set (opcodes `6` and `7`).

On invalid operations: `out = 0` and `leds` toggles every clock cycle.

The output mux resolves simultaneous control signals in this order:

1. `bypass_A && bypass_B` → resolved by `INPUT_PRIORITY` parameter (`"A"` or `"B"`)
2. `bypass_A` alone → `out = A`
3. `bypass_B` alone → `out = B`
4. Invalid opcode/operand condition → `out = 0`
5. Otherwise → opcode-selected ALU / shift / rotate result

---

## Verification Environment

The environment is a standard layered UVM testbench, instantiated in `top.sv` and driven through a virtual interface (`alsu_if`) bound at run-time via `uvm_config_db`.

```
alsu_test
 └── alsu_env
      ├── alsu_agent
      │    ├── alsu_sequencer
      │    ├── alsu_driver    → drives alsu_if pins from alsu_seq_item
      │    └── alsu_monitor   → samples alsu_if pins into alsu_seq_item, publishes via analysis port
      ├── alsu_scoreboard     → predicts expected output (reference model) and compares vs. monitored output
      └── alsu_coverage       → functional coverage model fed from the monitor
```

**Data flow:** `alsu_monitor` publishes each sampled transaction on `agt_ap`. In `alsu_env.connect_phase`, that port fans out to both `alsu_scoreboard.sb_export` and `alsu_coverage.cov_export`. The virtual interface is passed from `top.sv` into the test through `uvm_config_db #(virtual alsu_if)::set(...)`, then into the agent via `alsu_config`.

SVA checks run concurrently inside the DUT hierarchy via `bind ALSU alsu_sva` in `top.sv`.

### Test Flow

1. **Build phase** — Constructs the config object, environment, and retrieves the virtual interface from `uvm_config_db` (fatal error if not set by `top.sv`).
2. **Run phase:**
   - Raises an objection
   - Starts `alsu_reset_sequence` to assert reset for one transaction
   - Starts `alsu_main_sequence`, a fully randomized sequence that issues **10,000** iterations of randomized `alsu_seq_item`s
   - Drops the objection on completion
3. **Report phase** — Scoreboard prints `correct_count` and `error_count`.

### Stimulus & Scoreboard

**Stimulus (`alsu_seq_item`)** — Randomized fields include `A`, `B`, `cin`, `opcode`, `bypass_A/B`, `red_op_A/B`, `direction`, `serial_in`, and `rst`, with constraints that:

- Bias opcode distribution to favor valid opcodes over invalid ones (`[0:5] := 90`, invalid opcodes `[6:7] := 10`)
- Bias `bypass_A`/`bypass_B` distribution (90% off / 10% on)
- Inject random reset events (95% off / 5% on)
- Generate **walking-one** patterns on `A` or `B` when the corresponding reduction flag is active (for reduction-operation coverage crosses)
- Constrain `A`/`B` to corner values (0, +3, −4) when the opcode is ADD or MULT
- Force the other operand to zero when `red_op_A` or `red_op_B` is exercised in isolation (so the reduction result is unambiguous)

The driver applies stimulus on **negedge clk**; the monitor samples on the same edge.

**Scoreboard (`alsu_scoreboard`)** — A cycle-accurate reference model that mirrors the DUT's registered input stage and replicates:

- Invalid-opcode/operand detection and `leds` toggling behavior
- The full bypass / reduction / opcode priority chain
- Signed arithmetic with correct sign-extension for ADD
- Shift/rotate behavior using feedback from the previous `out` value

Every transaction is compared against the DUT's actual `out` and `leds`; mismatches are flagged via `uvm_error`, and a running pass/fail tally is reported at `report_phase`. The scoreboard updates its reference model (`ref_model`) each cycle, then compares the monitored outputs against the **previous-cycle** predicted values (`out_old`, `leds_old`) to match the DUT's registered pipeline timing.

---

## Coverage Model

### Functional Coverage (`alsu_coverage`)

Covergroup **`Cov`** defines **16 coverpoints/crosses** and **45 bins**, sampled from monitored transactions:

- **`A_cp` / `B_cp`:** zero, max-positive (+3), max-negative (−4), and default bins
- **`A_cp1` / `B_cp1`:** walking-one patterns `{1, 2, 4}`, sampled only when the corresponding reduction op is active
- **`ALU_cp`:** opcode bins grouped into shift/rotate, arithmetic (ADD/MULT), bitwise (OR/XOR), and `illegal_bins` for opcodes 6/7
- **`cin_cp`, `direction_cp`, `serial_in_cp`, `red_op_A_cp`:** binary coverpoints
- **Cross coverage:**
  - `AB_addmul` — A/B corner crosses during ADD/MULT
  - `cin_add` — carry-in × ADD opcode
  - `direction_rotshift` — shift/rotate × direction
  - `serial_in_shift` — serial input × SHIFT opcode
  - `AB_orxorA` / `AB_orxorB` — walking-ones × reduction-op active during OR/XOR
  - `red_orxor` — invalid reduction flag × shift/arithmetic opcode families

### Assertions (`alsu_sva.sv`)

**17 concurrent SVA properties** plus **2 reset `final` assertions**, bound directly to the DUT via `bind ALSU alsu_sva` in `top.sv`, covering:

- Reset behavior (`out == 0`, `leds == 0`)
- LED toggle on invalid conditions and LED clear on valid conditions (`p1`, `p2`)
- Bypass priority correctness (`p3`–`p5`)
- Per-opcode functional correctness for OR/XOR — plain and reduction variants (`p6`–`p11`)
- ADD with sign-extended operands and carry-in (`p12`)
- MULT signed product (`p13`)
- SHIFT/ROTATE in both directions (`p14`–`p17`)

Each property uses a **2-cycle delay** (`##2`) to align with the DUT's registered pipeline. Each assertion has a matching **`cover property`** directive (17 cover properties), giving directive-coverage points alongside the assertions.

| Property | Checks |
|---|---|
| `out_a`, `leds_a` | Reset: `out == 0`, `leds == 0` |
| `p1`, `p2` | LED toggles when invalid; cleared when valid |
| `p3`–`p5` | Bypass A, bypass B, invalid → `out == 0` |
| `p6`–`p8` | OR — reduction A, reduction B, bitwise |
| `p9`–`p11` | XOR — reduction A, reduction B, bitwise |
| `p12` | ADD with sign extension and carry-in |
| `p13` | MULT signed product |
| `p14`–`p17` | SHIFT/ROTATE left and right |

### Coverage Results

Results below are pulled from `sim/coverage.txt` (QuestaSim coverage report) for the primary verification targets:

**DUT (`/top/dut`)**

| Metric | Result |
|---|---|
| Statement Coverage | 48 / 49 — **97.95%** |
| Branch Coverage | 31 / 32 — **96.87%** |
| Condition Coverage | 6 / 6 — **100.00%** |
| Expression Coverage | 8 / 8 — **100.00%** |

The one missed branch is the `default` arm of the opcode `case` statement (unreachable in normal operation when invalid opcodes are handled upstream).

**SVA (`/top/dut/alsu_sva_inst`)**

| Metric | Result |
|---|---|
| Assertion Coverage | 19 / 19 — **100.00%** (0 failures) |
| Cover Property Hits | 17 / 17 — **100.00%** |

**Functional Coverage (`alsu_coverage_pkg::Cov`)**

| Metric | Result |
|---|---|
| Covergroup Bins | 45 / 45 — **100.00%** |
| Coverpoints / Crosses | 16 — **100.00%** |

> **Note:** The all-instance total in the report also includes testbench-side packages (sequence item, driver, scoreboard, coverage classes) whose statement/branch coverage is not a closure target. The DUT, bound SVA module, and UVM functional covergroup are the primary verification closure metrics.

---

## Running the Simulation

The project is set up for **QuestaSim**. From the `sim/` directory:

```tcl
do run.do
```

`run.do` performs:

1. `vlib work` — create the work library
2. `vlog -cover sbcef -f src_files.list` — compile all sources with statement, branch, condition, expression, and FSM coverage enabled
3. `vsim -coverage -voptargs=+acc work.top -classdebug -uvmcontrol=all` — elaborate with full visibility and UVM debug controls
4. Adds key waveform signals on `/top/aif/*`
5. `run -all` — runs the full UVM test to completion
6. `coverage report -details -output coverage.txt` — writes the detailed coverage report
7. `coverage save coverage.ucdb` — saves the coverage database for GUI review

**Pass criteria:** zero `UVM_ERROR` / `UVM_FATAL`, scoreboard `error_count == 0`, and coverage artifacts generated under `sim/`.

**Reviewing results:**
- Transcript — scoreboard `correct_count` / `error_count`
- `sim/coverage.txt` — detailed per-bin report
- `sim/coverage.ucdb` — open in QuestaSim Coverage GUI for drill-down

---

## Verification Techniques Demonstrated

- UVM agent / driver / monitor / scoreboard / coverage architecture with `config_db`-based interface binding
- Constrained-random stimulus generation, including walking-ones patterns and conditional operand constraints
- A cycle-accurate reference model used for self-checking (`out` and `leds`)
- SystemVerilog Assertions bound non-intrusively to RTL via `bind`
- Functional coverage with targeted cross-coverage to verify combinations of control and data conditions
- Code coverage collection (statement, branch, condition, expression) on the DUT via QuestaSim `-cover sbcef`
- QuestaSim simulation flow with coverage database generation and waveform debug

---

## Author

Digital Verification Diploma — under the supervision of **Eng. Kareem Wassem**.
