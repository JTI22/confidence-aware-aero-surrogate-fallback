# Safety limits (locked before any Simulink run)

Locked on: 10 Oct 2026

A run FAILS if any limit below is broken at any time.

1. Pitch angle stays within -30 to +30 degrees.
2. Angle of attack stays within -5 to 15 degrees (the range of the XFOIL training data).
3. Altitude stays within 10 m of the reference run.
4. Airspeed stays within 20% of the reference run.

Three runs are compared:
- Reference: lookup table only.
- GP with no guard.
- GP with fallback.

The fallback passes only if the GP-with-fallback run stays inside all four limits while the GP-with-no-guard run breaks at least one. If the no-guard run never breaks a limit, the stress test was too gentle and will be made harsher.

Notes:
- These numbers are placeholders for a generic fixed-wing aircraft. They are not from a real aircraft specification.
- The 5 kg mass in the Simulink model is a test value only.
- The lookup table is built from the same XFOIL data. It is a safe default, not a certified source.