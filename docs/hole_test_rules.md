# Hole test rules (locked before running)

Locked on: 13 Oct 2026 (revised the same day, before any run)

Revision note: the first version used a hole at 6 to 10 degrees. The lift curve is nearly straight there, so the test was likely too easy. The hole now covers the region where the lift curve bends.

Question: can the GP uncertainty flag a gap inside the data range that a plain range rule cannot?

Setup:
- Remove all training rows with Alpha from 10 to 14 degrees, all Mach values.
- Train the GP with the final settings (quadratic trend, sf=0.1, ls=0.4, sn=0.001) on the remaining rows.
- Test on the removed rows only.
- naca0012_hi_test.csv is not used.

Threshold: 0.00879 (the locked value, not retuned).

Pass rule:
- Every point the GP trusts must have CL error of 0.1 or less.
- Report how many points the GP refuses, and how many of those refused points were actually within 0.1.
- The range rule (trust everything between -5 and 15 degrees) trusts all points. Report its worst CL error and how many points it lets through with CL error above 0.1.

The GP adds value only if the range rule lets a point with CL error above 0.1 through and the GP refuses it.
If no point has CL error above 0.1, say so honestly: the hole was still too easy.

One run only. The result is reported whatever it is.