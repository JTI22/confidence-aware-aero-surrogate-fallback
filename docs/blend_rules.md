# Smooth blend test rules (locked before any Simulink run)

Locked on: 21 Nov 2026

Question: does blending the GP and the lookup smoothly, instead of switching hard, keep the flight closer to the truth, and does it make the pitching moment change more gently?

New mode, Mode 5, smooth blend:
- Weight on the GP: w = 1 when sd <= thr, w = 0 when sd >= 2 thr, and a straight line in between (w = 2 - sd/thr).
- Coefficients used: y = w * yGP + (1 - w) * yLookup.
- thr = 0.1055, the same flight GP threshold as Mode 3. The upper end (2 thr) is a fixed choice made now, not tuned.
- The gate output gives w in Mode 5 (0 to 1). In the other modes it stays 0 or 1.

Tests: the same Test A (gust) and Test B (trim runaway) as docs/fault_test_rules.md, with the same settings and fixed-step ode4 solver.

Runs: all six modes (0 truth, 1 lookup, 2 GP only, 3 GP + gate, 4 range rule, 5 smooth blend) in one script run.

Repeat check: Modes 0 to 4 must give the same numbers as docs/range_test_output.txt (to 2 decimals). If they do not, stop and report it before reading Mode 5.

Limits and scoring: the same as docs/fault_test_rules.md (pitch within +-30 deg, altitude within 10 m of truth, airspeed within 20% of truth).

Also reported:
- Mode 5: time with w < 1 (GP partly or fully refused) and time with w = 0 (GP fully refused).
- Modes 3, 4 and 5: the largest rate of change of the pitching moment (|dM/dt|, N m/s), from a new log of the moment M. This measures how sharply the aerodynamic moment jumps.

Honest note: above 15 deg the GP predicts too much lift. The blend lets part of the GP in for longer than the hard gate, so it may drift further from the truth in Test B. This is stated before the run. The size of the effect is not known, and no mode was simulated offline for this test.

How results are read:
- The blend helped if Mode 5 passes a limit that Mode 3 fails, or stays closer to the truth run than Mode 3.
- The blend hurt if Mode 5 drifts further from the truth run than Mode 3.
- The blend is smoother if its largest |dM/dt| is lower than in Mode 3.
- Each finding is reported plainly, whatever it is.

The test is run once.