# Flight GP rules (locked before any gust run)

Locked on: 20 Oct 2026

Why a new GP:
In the closed-loop trim run (5.2 deg, Mach 0.088), the original GP gave an uncertainty of 0.0171, about twice the threshold 0.00879. The gate refused the GP in normal cruise. The cause: cruise Mach lies between the data's Mach lines, and the original single length scale (0.4) is small compared with that gap. The threshold had been set only on points lying on the grid.

Flight GP:
- Trained on all rows of naca0012_data.csv.
- Same form as before: quadratic trend plus squared-exponential kernel, outputs standardized.
- Separate length scales for Alpha and Mach, chosen by maximum log marginal likelihood over the same grid as the detector test:
  ls_alpha in {0.1, 0.2, 0.4, 0.8, 1.6}, ls_mach in {0.2, 0.4, 0.8, 1.6, 3.2}, sf in {0.03, 0.1, 0.3, 1}, sn = 0.001.

Threshold (same rule as the original GP):
- Train on Alpha <= 12, predict Alpha 12 to 15.
- Threshold = 0.5 x the smallest uncertainty among those points with CL error above 0.1.

Checks done before locking (development data only, no flight or test runs):
- The rule finds bad development points and gives a threshold.
- At cruise, the uncertainty is below the threshold. At 16 deg and above, it is far above it.

The original GP (gp_final.mat, threshold 0.00879) and all earlier results are kept unchanged.