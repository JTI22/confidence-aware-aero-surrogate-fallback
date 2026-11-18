# Safety case (short): uncertainty-gated aerodynamic surrogate

Date: 18 Nov 2026. Scope: simulation study only. This is not a certification document.

## 1. System

- A Gaussian Process (GP) predicts CL, CD and CM of the NACA 0012 airfoil from angle of attack and Mach. Training data: XFOIL 6.99, -5 to 15 deg, Mach 0 to 0.4, Re 1,000,000.
- A gate checks the GP uncertainty. If it is above a locked threshold, a lookup table built from the same XFOIL data is used instead.
- The gate is tested offline and inside a closed-loop Simulink 6DOF model of a representative 5 kg aircraft (docs/aircraft_assumptions.md).

## 2. Claims

- **C1.** In the tested simulation, the gate prevented a loss of control that the GP alone caused when the aircraft stayed beyond the training data.
- **C2.** Inside the training range, the gate kept the same coverage as a simple range rule.

## 3. What is NOT claimed

- That the aircraft is safe, or that any real aircraft would be safe with this gate.
- That the gate is better than a simple range rule. It was not shown to be.
- That the lookup fallback is correct outside its data. It is only bounded.

## 4. Evidence for the claims

All test rules were written and pushed to GitHub before each test was run (see the commit dates).

| ID | Test | Result | Supports |
|---|---|---|---|
| E1 | Trim-runaway fault, closed loop, blind (docs/fault_test_rules.md) | GP alone lost control at about 76 s: pitch reached 180 deg, altitude 62.6 m and speed 90% away from the truth run. GP with gate stayed controlled: pitch 26.1 deg, speed within 7.0%. | C1 |
| E2 | Gust fault, closed loop (predicted offline, not blind) | All modes within limits. Gate run closest to truth (altitude 2.28 m, speed 1.9%). | C1 (weak) |
| E3 | Detector test, blind (docs/detector_test_rules.md) | Inside the range: gate and range rule made the same decisions on all 129 points. | C2 |
| E4 | Closed-loop checks | Trim at 30 m/s flew level. A pitch nudge settled, so the model is stable. | Model validity |

The reference ("truth") in E1 and E2 is a lookup built from all XFOIL data, including near-stall points (15.5 to 18 deg) that neither the GP nor the fallback was trained on.

## 5. Evidence against, or limits on, the claims

- **The gate behaved like a range rule near stall.** In E1 it refused the GP for 58.4 s, exactly while the angle was above 15 deg. The gated run and the lookup-only run were almost identical.
- **The fallback was not fully safe.** In E1, both the lookup-only and the gated runs drifted 10.5 m from the truth run, just over the 10 m limit, because the lookup holds its 15 deg values beyond its data.
- **The gate can accept a bad prediction.** In E3, outside the range it accepted 11 of 29 near-stall points: 10 accurate, 1 with CL error 0.1245 (tolerance 0.1).
- **The threshold was set on a weak validation set.** In E3, no validation point had a large error, so the backup rule set the threshold.
- **The uncertainty is not a calibrated error bar.** In an early test, real errors were about 100 times larger than the stated uncertainty.
- **CD is predicted poorly outside the data.** The gate is tuned on CL error only.
- **A threshold tuned on grid points refused the GP in normal cruise.** This was fixed with a separate flight GP (docs/flight_gp_rules.md), whose threshold has not been checked on a held-out set.

## 6. Not tested

- Other airfoils, other Reynolds numbers, wind-tunnel or flight data.
- Angles above 18 deg (no truth data there).
- Sideways (lateral) motion, sensor noise, a pilot or autopilot, real tail aerodynamics.
- Faults other than one gust and one trim runaway; each test was run once.
- Code generation and real-time execution (the GP runs through an extrinsic MATLAB call).

## 7. Test conduct notes

- The first run of the fault script was stopped by hand before any result was shown, because the variable-step solver stalled near the gust. It was rerun once with a fixed-step solver (ode4; step 0.005 s for the gust test and 0.01 s for the trim runaway). The rules did not specify a solver.
- In the gust test, the truth run reached 18.16 deg for a fraction of a second, slightly beyond its data.

## 8. Remaining risk

- Safety depends on the fallback, and the fallback is only as good as its own data near and beyond stall.
- Near stall, a simple range rule gave the same protection as the gate. The extra value of the GP uncertainty in flight was not shown.
- Limits, thresholds, aircraft numbers and the tail model are placeholders, not from a real aircraft specification.

## 9. Conclusion

In this simulation, the uncertainty gate stopped a GP that was unaware of stall from causing a loss of control. The protection came from switching to the fallback beyond the data, which a range rule would also do. The fallback itself still drifted outside one limit. A real benefit of GP uncertainty over a range rule, and a fallback that is valid beyond the data, remain open problems.