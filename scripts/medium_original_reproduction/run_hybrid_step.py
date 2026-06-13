"""
Generate p=40 data for hybrid/iterative MCMC experiment (Kuipers et al. 2022).
Saves data for R to consume, then R script picks it up automatically.
"""
import numpy as np, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from run_experiment import RNG, generate_data

BASE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(BASE))
DATA_DIR = os.path.join(PROJECT, "data", "simulated")
os.makedirs(DATA_DIR, exist_ok=True)

for p in [40]:
    for n_factor in [5]:
        n = p * n_factor
        for seed in [1, 2]:
            prefix = os.path.join(DATA_DIR, f"p{p}_n{n}_seed{seed}")
            if os.path.exists(f"{prefix}_data.csv"):
                print(f"SKIP p={p} n={n} seed={seed} (exists)")
                continue
            rng = RNG(seed + 10000)
            true_adj, data_arr = generate_data(p, n, rng, expected_degree=2.0)
            np.savetxt(f"{prefix}_data.csv", data_arr, delimiter=",",
                       header=",".join(f"X{i}" for i in range(p)), comments="")
            np.savetxt(f"{prefix}_adj.csv", true_adj.astype(int), delimiter=",", fmt="%d")
            print(f"Generated p={p} n={n} seed={seed}")

print("Done. Now run in RStudio:")
print("  source('scripts/medium_original_reproduction/run_r_hybrid.R')")
