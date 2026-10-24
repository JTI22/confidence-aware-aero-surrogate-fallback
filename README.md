# Confidence-Aware Fallback for a Learned Aerodynamic Surrogate: A Case Study on the NACA 0012 Airfoil

**Status:** in progress. Sections marked *(in progress)* are not finished.

## Question

Can a learned aerodynamic model know when not to be trusted, and does its uncertainty give a better trade-off than a simple range rule?

## What this project does

- Generates NACA 0012 airfoil data (CL, CD, CM) with XFOIL 6.99, for angles of attack from -5 to 15 degrees and Mach 0 to 0.4 (Reynolds number 1,000,000).
- Trains Gaussian Process (GP) surrogates from scratch in MATLAB, with no toolbox. Each GP gives a prediction and an uncertainty value.
- Uses the uncertainty to decide when to trust the GP. If the uncertainty is above a locked threshold, a lookup table built from the same XFOIL data is used instead.
- Compares this uncertainty gate with a simple range rule in a pre-registered, blind test.
- Tests the gate inside a closed-loop Simulink 6DOF aircraft model.

All limits, settings and test rules were written down and pushed before each test was run. See the `docs` folder.

## Results

### 1. GP accuracy and uncertainty (offline)

- The GP beat a degree-2 polynomial on held-out data (random 80/20 split). CL error was about 12 times smaller.
- When an early version of the GP was tested on angles it had never seen (12 to 15 degrees), its uncertainty rose with the real error. The correlation was 0.97 to 0.99 for CL and CM.
- On 29 new near-stall points (15.5 to 18 degrees), the original GP gate (threshold 0.00879) trusted 5 points, all with CL error of 0.1 or less, and refused all 10 points with CL error above 0.1.

### 2. Detector test: GP gate vs range rule (pre-registered, blind)

Rules: `docs/detector_test_rules.md`. Script: `scripts/score_detector.m`. Every test point: `data/detector_test_points.csv`.

- The GP was trained on a sparse grid (every 2 degrees, Mach 0, 0.2 and 0.4; 32 rows). Its settings were chosen by marginal likelihood on the training rows only.
- The range rule accepts every point inside -5 to 15 degrees and Mach 0 to 0.4.

| Test set | Range rule | GP gate |
|---|---|---|
| Inside the range (129 points) | Accepted all 129 | Accepted all 129 (same decisions) |
| Near stall (29 points) | Accepted 0 | Accepted 11: 10 with CL error of 0.1 or less, 1 above (0.1245) |

- **Safer?** No. The GP gate accepted one bad CL prediction, and the range rule accepted none.
- **More useful?** Yes. The GP gate accepted 10 accurate points that the range rule refused.
- No point inside the range had a CL error above 0.1, so the question "can the GP catch bad points inside the range?" could not be tested.
- Both methods accepted 5 points inside the range with CD error above 0.01.
- No validation point had a CL error above 0.1, so the threshold came from the backup rule (the largest validation uncertainty). The validation set was too easy to set a careful threshold.

### 3. Closed-loop 6DOF model

Model: `scripts/aircraft_6dof_cl.slx`.

- The angle of attack and the airspeed are computed from the aircraft's own velocity at every time step. Lift and drag are turned into body axes, and gravity uses the current attitude.
- A trim script (`scripts/trim_cl.m`) finds steady level flight at 30 m/s: angle of attack 5.235 degrees, thrust 0.732 N. The model flew straight and level for 10 seconds, which checks the force equations.
- **Finding:** at cruise (Mach 0.088), the original GP gave an uncertainty of 0.0171, about twice its threshold. The gate refused the GP in normal flight. Cruise Mach lies between the data's Mach lines, and the threshold had been set only on points lying on the grid.
- A separate flight GP (`scripts/make_gp_flight.m`, rules in `docs/flight_gp_rules.md`) uses separate length scales for angle and Mach. Its threshold (0.1055) uses the same rule as the original GP. At cruise, its uncertainty is 0.0102, so the GP is trusted.

### 4. Earlier open-loop 6DOF test

This test used a fixed angle (25 degrees) and a fixed airspeed. It is kept for the record; the closed-loop model above replaces it.

- GP with no guard failed the locked limits (altitude differed by 201.5 m and total speed by 29.3 percent). GP with fallback matched the lookup-only reference.

![Three open-loop 6DOF runs at 25 degrees](docs/screenshots/sixdof_comparison.png)

## What did not work

- The GP gate has not been shown to be safer than a range rule. In the detector test it gave more coverage but accepted one bad point.
- The GP did not predict CD reliably above its training range.
- The GP uncertainty depends mainly on distance from the training data. It is a warning signal, not a calibrated error bar. In the first extrapolation test, the real error was about 100 times larger than the uncertainty claimed.
- A threshold tuned on grid points refused the GP in normal cruise (see Results 3).

## Limits

- One airfoil (NACA 0012), with XFOIL simulation data only. XFOIL is less reliable near and past stall. One point (17 degrees, Mach 0.3) did not converge.
- The lookup table is built from the same XFOIL data. It is a bounded default, not a correct answer outside the data.
- The 12 times improvement over the polynomial used a noise setting chosen while looking at the test rows. Treat it as an upper estimate.
- Thresholds and error tolerances are placeholders. They are not from a real aircraft specification.
- The flight GP threshold has not yet been checked on a held-out test set.
- The aircraft numbers (5 kg, 0.15 m2 wing) are representative values, not a real aircraft.
- The pitching moment is still switched off in the closed-loop model, so pitch does not change. *(in progress)*
- The GP runs inside Simulink through an extrinsic MATLAB call. It cannot be turned into code for flight hardware without more work.

## Work in progress

- Add a simple illustrative tail (restoring moment and pitch damping) and switch the airfoil CM back on.
- Inject a gust during flight, so the angle of attack leaves the training range, and compare lookup only, GP only and GP with fallback against the locked limits.
- Write a short safety case: claims, evidence, what was not tested, and remaining risk.

## How to reproduce

Requires MATLAB/Simulink R2025b with Aerospace Blockset. Run from the folder that holds the scripts and data.

1. `make_gp_final` builds the original GP (`gp_final.mat`).
2. `make_gp_flight` builds the flight GP (`gp_flight.mat`).
3. `score_detector` runs the detector test.
4. Open `aircraft_6dof_cl.slx`, set the mode Constant (1 = lookup only, 2 = GP only, 3 = GP with fallback), and press Run. The trim script runs automatically.

## Repository contents

- `data/` - XFOIL results (`raw/`), the training set `naca0012_data.csv`, the near-stall test set `naca0012_hi_test.csv`, and `detector_test_points.csv`.
- `scripts/` - MATLAB scripts and Simulink models.
- `docs/` - locked rules (`safety_limits.md`, `aircraft_assumptions.md`, `hole_test_rules.md`, `detector_test_rules.md`, `flight_gp_rules.md`) and result screenshots.

Built using XFOIL 6.99 (Mark Drela, MIT) and MATLAB/Simulink R2025b.