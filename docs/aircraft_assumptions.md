# Aircraft assumptions (locked before the 6DOF runs)

Locked on: 12 Oct 2026

These numbers describe a generic light fixed-wing aircraft. They are not from a real aircraft.

- Wing area: 1 m2
- Chord: 0.3 m
- Air density: 1.225 kg/m3 (sea level)
- Airspeed: 30 m/s (fixed, so only angle of attack changes)
- Mach passed to the GP: 0.1 (about 30 m/s; inside the training data)
- Mass: 5 kg (test value)

Formulas:
- Lift = 0.5 * density * speed^2 * area * CL
- Drag = 0.5 * density * speed^2 * area * CD
- Moment = 0.5 * density * speed^2 * area * chord * CM