# Aircraft assumptions

Locked on: 12 Oct 2026. Updated 18 Oct to 18 Nov 2026 for the closed-loop model (changes listed below).

These numbers describe a generic light fixed-wing aircraft. They are not from a real aircraft.

- Wing area: 0.15 m2
- Chord: 0.3 m
- Air density: 1.225 kg/m3 (sea level)
- Mass: 5 kg; inertia: identity matrix (1 kg m2 about each axis)
- Mach passed to the models: airspeed / 340

Closed-loop model (aircraft_6dof_cl.slx):
- Angle of attack and airspeed come from the aircraft's own body velocity at every time step.
- Gravity is added in the force block, using the current roll and pitch (the 6DOF block does not add it).
- Trim (trim_cl.m, lookup table): level flight at 30 m/s, angle of attack 5.222 deg, thrust 2.392 N along the body x axis.
- Extra airframe drag: CD 0.02, added to the airfoil drag in all modes. Reason: the 2D airfoil data has no body, tail or wingtip drag. Without it, lift-to-drag was about 67 and the slow pitch swing (phugoid) grew. With it, lift-to-drag is about 20 and the swing slowly dies out.
- Illustrative tail (not real tail aerodynamics): restoring moment Cm_alpha = -0.5 per rad about the trim angle, pitch damping Cm_q = -10. The airfoil CM is used relative to its trim value.

Formulas:
- Lift = 0.5 * density * speed^2 * area * CL
- Drag = 0.5 * density * speed^2 * area * (CD + 0.02)
- Moment = 0.5 * density * speed^2 * area * chord * Cm

Open-loop model (aircraft_6dof_gp.slx, earlier results):
- Fixed airspeed 30 m/s, fixed angle of attack, no thrust, no airframe drag, pitching moment switched off.