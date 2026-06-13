"""
Step 3: Merge Python results + R results into final metrics and summary CSVs.
"""
import csv, os, sys
from collections import defaultdict

BASE = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(BASE))
RESULTS = os.path.join(PROJECT, "results", "medium_original_reproduction")
TABLES  = os.path.join(RESULTS, "tables")

python_csv = os.path.join(TABLES, "python_results.csv")
r_csv      = os.path.join(TABLES, "r_results.csv")
hybrid_csv = os.path.join(TABLES, "hybrid_results.csv")
out_csv    = os.path.join(TABLES, "medium_original_metrics.csv")
sum_csv    = os.path.join(TABLES, "medium_original_summary.csv")

all_rows = []
FIELDS = ["paper","experiment_group","data_source","p","n","seed",
          "method","implementation","runtime","SHD","TPR","FPR",
          "Precision","F1","acceptance_rate","mean_edge_entropy",
          "posterior_gap","status","error","comparable_level",
          "original_paper_trend","comment"]

# Load Python results
if os.path.exists(python_csv):
    with open(python_csv, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            row = dict(row)
            all_rows.append({k: row.get(k, "") for k in FIELDS})
    print(f"Loaded {sum(1 for _ in open(python_csv))-1} Python rows")
else:
    print(f"WARNING: {python_csv} not found")

# Load R results
if os.path.exists(r_csv):
    with open(r_csv, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            # Normalize fields to match
            nr = dict(row)
            # R may write extra columns, keep only needed ones
            clean = {k: nr.get(k, "") for k in FIELDS}
            all_rows.append(clean)
    print(f"Loaded {sum(1 for _ in open(r_csv))-1} R rows")
else:
    print(f"WARNING: {r_csv} not found")

# Load hybrid results
if os.path.exists(hybrid_csv):
    with open(hybrid_csv, newline="", encoding="utf-8-sig") as f:
        for row in csv.DictReader(f):
            nr = dict(row)
            clean = {k: nr.get(k, "") for k in FIELDS}
            all_rows.append(clean)
    print(f"Loaded {sum(1 for _ in open(hybrid_csv))-1} hybrid rows")

if not all_rows:
    print("No data. Run run_python_and_save_data.py first, then R, then this.")
    sys.exit(1)

# Write merged metrics
with open(out_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=FIELDS)
    w.writeheader()
    w.writerows(all_rows)
print(f"Merged: {len(all_rows)} rows → {out_csv}")

# ---- Analysis ----
print("\n=== Three-way comparison ===")
groups = defaultdict(list)
for r in all_rows:
    if r.get("status") != "success":
        continue
    key = (int(r["p"]), r["method"])
    groups[key].append((float(r["SHD"]), float(r["F1"]), float(r["runtime"]), r["implementation"]))

current_p = None
for key in sorted(groups.keys()):
    p, method = key
    if p != current_p:
        print(f"\n--- p={p} ---")
        current_p = p
    for impl in ["Python", "BiDAG", "manual_R"]:
        vals = [v for v in groups[key] if v[3] == impl]
        if vals:
            shd = sum(v[0] for v in vals)/len(vals)
            f1  = sum(v[1] for v in vals)/len(vals)
            rt  = sum(v[2] for v in vals)/len(vals)
            print(f"  {method:<20s} {impl:<8s} SHD={shd:>6.1f} F1={f1:.3f} {rt:.1f}s ({len(vals)} runs)")

# ---- Build summary CSV ----
print(f"\nSummary → {sum_csv}")
num_cols = ["runtime","SHD","TPR","FPR","Precision","F1",
            "acceptance_rate","mean_edge_entropy","posterior_gap"]

sum_groups = defaultdict(list)
for r in all_rows:
    if r.get("status") != "success":
        continue
    k = (r["experiment_group"], r["data_source"], int(r["p"]), int(r["n"]),
         r["method"], r["implementation"])
    sum_groups[k].append(r)

sum_rows = []
for k, vals in sum_groups.items():
    eg, ds, p, n, method, impl = k
    # Count failures
    failed = sum(1 for r in all_rows
                 if r["experiment_group"]==eg and int(r["p"])==p and int(r["n"])==n
                 and r["method"]==method and r["implementation"]==impl
                 and r.get("status")!="success")
    sr = {"experiment_group": eg, "data_source": ds, "p": p, "n": n,
          "method": method, "implementation": impl,
          "successful_runs": len(vals), "failed_runs": failed}
    for col in num_cols:
        nums = [float(v[col]) for v in vals if v.get(col) not in (None, "", "NA")]
        if nums:
            sr[f"{col}_mean"] = round(sum(nums)/len(nums), 4)
            sr[f"{col}_sd"] = round(
                (sum((x-sr[f"{col}_mean"])**2 for x in nums)/(len(nums)-1))**0.5, 4
            ) if len(nums) > 1 else ""
        else:
            sr[f"{col}_mean"] = ""; sr[f"{col}_sd"] = ""
    sum_rows.append(sr)

with open(sum_csv, "w", newline="") as f:
    w = csv.DictWriter(f, fieldnames=sum_rows[0].keys())
    w.writeheader()
    w.writerows(sum_rows)

print("Done.")
