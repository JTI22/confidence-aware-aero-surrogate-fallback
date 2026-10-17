# Detector test rules: GP gate vs range rule (locked before running)

Locked on: 17 Oct 2026

Question: does the GP uncertainty gate give a better trade-off than a simple range rule between refusing bad predictions and keeping good ones?

Data split (from naca0012_data.csv and naca0012_hi_test.csv):
- Training: Alpha in {-5, -3, -1, 1, 3, 5, 7, 9, 11, 13, 15} and Mach in {0, 0.2, 0.4} (sparse grid). Only rows that actually exist in naca0012_data.csv at these exact (Alpha, Mach) pairs are used for training.
- Validation: all rows at Mach 0.1. Used only to choose the GP threshold.
- Interior test: all other rows of naca0012_data.csv (off-grid angles at Mach 0, 0.2, 0.4, and all rows at Mach 0.3).
- Extrapolation test: all 29 rows of naca0012_hi_test.csv (15.5 to 18 degrees).

Model:
- Same GP form as before: quadratic trend plus squared-exponential kernel, outputs standardized.
- Input and output scaling are computed from the training rows only.
- Kernel settings are chosen by maximum log marginal likelihood on the training rows only, over this fixed grid:
  length scale for Alpha in {0.1, 0.2, 0.4, 0.8, 1.6}
  length scale for Mach in {0.2, 0.4, 0.8, 1.6, 3.2}
  sf in {0.03, 0.1, 0.3, 1}
  sn = 0.001 (fixed)

Error tolerances (placeholders, not from an aircraft specification):
- CL: 0.1   CD: 0.01   CM: 0.02
- A prediction is "bad" if its error is above the tolerance for that coefficient.

Methods:
- Range rule: accept if -5 <= Alpha <= 15 and 0 <= Mach <= 0.4. Otherwise refuse.
- GP gate: accept if uncertainty <= threshold.
- Threshold: 0.5 times the smallest uncertainty among validation points with CL error above 0.1.
  If no validation point has CL error above 0.1, the threshold is the largest uncertainty seen on validation.
- The threshold is computed from the validation set only. It is then frozen and used unchanged for both the interior and extrapolation tests.

Metrics (for CL, CD and CM separately, for each test set and for both combined):
- Bad predictions accepted
- Good predictions refused
- Worst error among accepted points
- Coverage (accepted points / all points)

How results are read:
- The GP gate is safer if it accepts fewer bad CL predictions than the range rule.
- The GP gate is more useful if it accepts good points that the range rule refuses.
- Both are reported. No single winner is forced.

One run only. The result is reported whatever it is.