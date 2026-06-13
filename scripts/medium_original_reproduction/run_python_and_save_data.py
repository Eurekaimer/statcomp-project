"""
Step 1: Run pure Python/numpy MCMC methods and save shared data for R.
Output: results/medium_original_reproduction/tables/python_results.csv
"""
import csv, os, sys, numpy as np
from run_experiment import (
    RNG, generate_data, run_order_mcmc, run_structure_mcmc,
    compute_metrics, edge_entropy, posterior_gap
)

BASE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(BASE))
RESULTS = os.path.join(PROJECT, "results", "medium_original_reproduction")
DATA_DIR = os.path.join(PROJECT, "data", "simulated")
os.makedirs(os.path.join(RESULTS, "tables"), exist_ok=True)
os.makedirs(DATA_DIR, exist_ok=True)

CASES = [
    # (p, n, seed, exp_group, paper, data_source)
    (9, 500, 1, "order_mcmc", "Friedman and Koller (2003)", "simulated_flare_like"),
    (9, 500, 2, "order_mcmc", "Friedman and Koller (2003)", "simulated_flare_like"),
    (9, 1000, 1, "order_mcmc", "Friedman and Koller (2003)", "simulated_flare_like"),
    (9, 1000, 2, "order_mcmc", "Friedman and Koller (2003)", "simulated_flare_like"),
    (37, 500, 1, "order_mcmc", "Friedman and Koller (2003)", "simulated_alarm_like"),
    (37, 500, 2, "order_mcmc", "Friedman and Koller (2003)", "simulated_alarm_like"),
    (37, 1000, 1, "order_mcmc", "Friedman and Koller (2003)", "simulated_alarm_like"),
    (37, 1000, 2, "order_mcmc", "Friedman and Koller (2003)", "simulated_alarm_like"),
    (5, 200, 1, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_toy_like"),
    (5, 200, 2, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_toy_like"),
    (5, 500, 1, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_toy_like"),
    (5, 500, 2, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_toy_like"),
    (14, 200, 1, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_boston_like"),
    (14, 200, 2, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_boston_like"),
    (14, 500, 1, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_boston_like"),
    (14, 500, 2, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_boston_like"),
    (20, 200, 1, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_large_like"),
    (20, 200, 2, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_large_like"),
    (20, 500, 1, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_large_like"),
    (20, 500, 2, "partition_mcmc", "Kuipers and Moffa (2017)", "simulated_large_like"),
]

csv_path = os.path.join(RESULTS, "tables", "python_results.csv")
rows = []

for idx, (p, n, seed, exp_group, paper, ds) in enumerate(CASES):
    print(f"[{idx+1}/{len(CASES)}] {exp_group} p={p} n={n} seed={seed}", end="", flush=True)

    # Generate + save data (shared with R)
    rng = RNG(seed + 10000)
    true_adj, data_arr = generate_data(p, n, rng)
    prefix = os.path.join(DATA_DIR, f"p{p}_n{n}_seed{seed}")
    np.savetxt(f"{prefix}_data.csv", data_arr, delimiter=",",
               header=",".join(f"X{i}" for i in range(p)), comments="")
    np.savetxt(f"{prefix}_adj.csv", true_adj.astype(int), delimiter=",", fmt="%d")

    for method_name, method_fn in [("python_order", run_order_mcmc), ("python_structure", run_structure_mcmc)]:
        rng2 = RNG(seed)
        est, ep, rt, ar, bs = method_fn(data_arr, 800, 150, 2, rng2)
        shd, tpr, fpr, prec, f1 = compute_metrics(true_adj, est)
        ent = edge_entropy(ep)
        pgap = posterior_gap(true_adj, ep)
        rows.append({
            "paper": paper, "experiment_group": exp_group, "data_source": ds,
            "p": p, "n": n, "seed": seed,
            "method": method_name, "implementation": "Python",
            "runtime": round(rt, 3), "SHD": shd,
            "TPR": round(tpr, 4), "FPR": round(fpr, 4),
            "Precision": round(prec, 4), "F1": round(f1, 4),
            "acceptance_rate": round(ar, 4),
            "mean_edge_entropy": round(ent, 6),
            "posterior_gap": round(pgap, 4),
            "status": "success", "error": "",
            "comparable_level": "approximate",
            "original_paper_trend": "", "comment": "",
        })
        print(f"  {method_name} SHD={shd} F1={f1:.3f} {rt:.1f}s", flush=True)

with open(csv_path, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=rows[0].keys())
    w.writeheader()
    w.writerows(rows)
print(f"\nDone. {len(rows)} Python rows → {csv_path}")
print(f"Data saved to {DATA_DIR}/")
print("\nNext: open RStudio, setwd to Project, then:")
print("  source('scripts/medium_original_reproduction/run_r_biag_manual.R')")
