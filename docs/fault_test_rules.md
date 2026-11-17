# Fault test rules: gust and trim runaway (locked before any Simulink run)

Locked on: 18 Nov 2026

Question: when the aircraft is pushed outside the training data during flight, does the GP gate keep the aircraft closer to the true behaviour than the GP alone, and how does it compare with the lookup table?

Model: aircraft_6dof_cl.slx (closed loop, trim at 30 m/s, airframe drag CD 0.02, illustrative tail). Flight GP threshold 0.1055.

Four runs per test, same start and same fault:
- Mode 0, truth: lookup built from ALL XFOIL data, including the near-stall points 15.5 to 18 deg (naca0012_hi_test.csv). Neither the GP nor the lookup was trained on those points. This is the reference.
- Mode 1: lookup only (data up to 15 deg; holds the edge value beyond).
- Mode 2: flight GP only.
- Mode 3: flight GP with the uncertainty gate (lookup when uncertainty > 0.1055).

Test A, gust (realistic case):
- Upward gust, 1-cos shape, peak 10 m/s, duration 0.5 s, starting at t = 2 s. Run time 20 s.
- The gust enters through the airflow (air-relative velocity), not by setting the angle of attack.
- Honest note: before locking, this gust was simulated offline in a separate Python model of the same aircraft for all modes. It predicted that the angle stays above 15 deg for only about 0.15 s, and that all modes stay inside the limits. So this result is not blind.

Test B, slow trim runaway (hard case):
- An extra nose-up pitching moment coefficient ramps from 0 at t = 5 s to 0.065 at t = 35 s, then stays. Run time 90 s.
- The fault size was chosen offline with the truth model only, so that the angle stays above 15 deg for a long time but below 18 deg (inside the data). The modes were NOT compared offline. This test is blind.

Limits (a run fails if any is broken at any time; compared with the truth run):
1. Pitch angle within -30 to +30 deg.
2. Altitude within 10 m of the truth run.
3. Airspeed within 20% of the truth run.
The angle-of-attack limit (-5 to 15 deg) is not scored, because both faults push the angle past 15 deg on purpose.

Also reported for each run: peak angle of attack, time above 15 deg, and for Mode 3 the time the gate refused the GP.

Validity check: if the truth run goes above 18 deg, the truth model is outside its data there, and that part of the result is reported as not valid.

How results are read:
- The gate helps if Mode 3 passes a limit that Mode 2 breaks, or stays closer to the truth run than Mode 2.
- If Mode 3 and Mode 1 behave the same, the gate gave no benefit over the lookup in this test. That is reported plainly.

Each test is run once. The result is reported whatever it is.