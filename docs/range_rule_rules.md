# Range rule test rules (locked before any Simulink run)

Locked on: 18 Nov 2026

Question: is the GP uncertainty gate any better than a simple range rule ("use the GP only inside the training data")?

New mode, Mode 4, range rule:
- Use the flight GP if -5 <= alpha <= 15 deg AND 0 <= Mach <= 0.4 (the box covered by naca0012_data.csv, which the flight GP was trained on).
- Otherwise use the lookup table.
- No tuning. The limits come straight from the training data.

Tests: the same Test A (gust) and Test B (trim runaway) as docs/fault_test_rules.md, with the same fault settings, run times, fixed-step ode4 solver and step sizes.

Runs: all five modes (0 truth, 1 lookup, 2 GP only, 3 GP + gate, 4 range rule) in one script run.

Repeat check: Modes 0 to 3 must give the same numbers as docs/fault_test_output.txt (to 2 decimals). If they do not, stop and report it before reading Mode 4.

Limits and scoring: the same as docs/fault_test_rules.md (pitch within +-30 deg, altitude within 10 m of truth, airspeed within 20% of truth). Also reported: time the range rule refused the GP, and how much that time differs from the gate's refusal time.

Honest note: the training data is dense from -5 to 15 deg, and the gate already refused the GP mostly above 15 deg. So the range rule is expected to behave close to the gate here. This test is not blind about that. Its main use is as a baseline for later tests with sparse data, where the two may differ.

How results are read:
- If Mode 4 and Mode 3 give the same result, the gate gave no benefit over a range rule with this dense data. That is reported plainly.
- If they differ, the difference is reported with the times each one refused the GP.

The test is run once. The result is reported whatever it is.