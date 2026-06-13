#!/usr/bin/env python3
"""
Post-process medium_original_reproduction experiment results.
Generates LaTeX tables and copies figures to the report directory.

Usage:
    python scripts/medium_original_reproduction/build_assets.py
Run from the Project/ directory.
"""
import os, sys, csv, shutil, math

PROJECT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.chdir(PROJECT)

RESULTS_TABLES = "results/medium_original_reproduction/tables"
RESULTS_FIGS   = "results/medium_original_reproduction/figures"
REPORT_TABLES  = "report/tables/medium_original_reproduction"
REPORT_FIGS    = "report/figures/medium_original_reproduction"

os.makedirs(REPORT_TABLES, exist_ok=True)
os.makedirs(REPORT_FIGS, exist_ok=True)

# ---------------------------------------------------------------------------
# 1. Load metrics CSV
# ---------------------------------------------------------------------------
metrics_csv = os.path.join(RESULTS_TABLES, "medium_original_metrics.csv")
if not os.path.exists(metrics_csv):
    print(f"ERROR: {metrics_csv} not found. Run the R experiment script first.")
    sys.exit(1)

with open(metrics_csv, newline="", encoding="utf-8") as f:
    rows = list(csv.DictReader(f))
print(f"Loaded {len(rows)} metric rows")

# ---------------------------------------------------------------------------
# 2. Build summary CSV if not exists
# ---------------------------------------------------------------------------
summary_csv = os.path.join(RESULTS_TABLES, "medium_original_summary.csv")

def build_summary(rows):
    """Aggregate successful runs into summary rows."""
    from collections import defaultdict
    groups = defaultdict(list)
    for r in rows:
        if r.get("status") != "success":
            continue
        key = (r["experiment_group"], r["data_source"], r["p"], r["n"],
               r["method"], r["implementation"])
        groups[key].append(r)

    out = []
    num_cols = ["runtime","SHD","TPR","FPR","Precision","F1",
                "acceptance_rate","mean_edge_entropy","posterior_gap"]
    for k, vals in groups.items():
        eg, ds, p, n, method, impl = k
        # Count failed separately
        failed = sum(1 for r in rows
                     if r["experiment_group"] == eg and r["p"] == p and r["n"] == n
                     and r["method"] == method and r["implementation"] == impl
                     and r["status"] != "success")
        row = {
            "experiment_group": eg, "data_source": ds,
            "p": int(p), "n": int(n),
            "method": method, "implementation": impl,
            "successful_runs": len(vals), "failed_runs": failed,
        }
        for col in num_cols:
            nums = [float(v[col]) for v in vals if v.get(col) and v[col] != "NA"]
            if nums:
                row[f"{col}_mean"] = round(sum(nums) / len(nums), 4)
                row[f"{col}_sd"] = round(
                    math.sqrt(sum((x - row[f"{col}_mean"])**2 for x in nums)/(len(nums)-1)), 4
                ) if len(nums) > 1 else "NA"
            else:
                row[f"{col}_mean"] = "NA"
                row[f"{col}_sd"]   = "NA"
        out.append(row)
    return out

if not os.path.exists(summary_csv):
    summary_rows = build_summary(rows)
    with open(summary_csv, "w", newline="", encoding="utf-8") as f:
        if summary_rows:
            w = csv.DictWriter(f, fieldnames=summary_rows[0].keys())
            w.writeheader()
            w.writerows(summary_rows)
    print(f"Built summary: {len(summary_rows)} rows")
else:
    with open(summary_csv, newline="", encoding="utf-8") as f:
        summary_rows = list(csv.DictReader(f))
    print(f"Loaded {len(summary_rows)} summary rows")

# ---------------------------------------------------------------------------
# 3. Generate LaTeX summary table
# ---------------------------------------------------------------------------
def escape_tex(s):
    if s is None: return ""
    s = str(s)
    return s.replace("_", "\\_").replace("&", "\\&").replace("%", "\\%").replace("#", "\\#")

def format_val(v, digits=2):
    try:
        x = float(v)
        if math.isnan(x): return "---"
        return f"{x:.{digits}f}"
    except (ValueError, TypeError):
        return str(v) if v and v != "NA" else "---"

# Pick key columns for the LaTeX table
key_cols = [
    ("experiment_group", "Experiment", 22),
    ("p", "p", 5),
    ("n", "n", 6),
    ("method", "Method", 16),
    ("implementation", "Impl", 9),
    ("successful_runs", "OK", 4),
    ("failed_runs", "Fail", 4),
    ("runtime_mean", "Runtime", 8),
    ("SHD_mean", "SHD", 6),
    ("F1_mean", "F1", 6),
]

summary_tex = os.path.join(REPORT_TABLES, "medium_original_summary.tex")
with open(summary_tex, "w", encoding="utf-8") as f:
    f.write(r"\begin{table}[htbp]" + "\n")
    f.write(r"\centering" + "\n")
    f.write(r"\footnotesize" + "\n")
    f.write(r"\caption{中等规模原论文对照实验汇总结果}" + "\n")
    f.write(r"\label{tab:medium_original_summary}" + "\n")
    f.write(r"\begin{tabular}{" + "c" * len(key_cols) + "}\n")
    f.write(r"\toprule" + "\n")
    # header
    header = " & ".join(escape_tex(c[1]) for c in key_cols) + r" \\" + "\n"
    f.write(header)
    f.write(r"\midrule" + "\n")
    for row in summary_rows:
        cells = []
        for col, _, _ in key_cols:
            val = row.get(col, "")
            if col == "method":
                val = escape_tex(val).replace("manual\\_", "manual\\_")
            elif col == "implementation":
                val = "BiDAG" if val == "BiDAG" else "manual" if val == "manual_R" else val
            elif col == "experiment_group":
                m = {"order_mcmc": "Order", "partition_mcmc": "Partition",
                     "hybrid_iterative": "Hybrid"}
                val = m.get(val, val)
            elif col == "data_source":
                val = val if val else ""
            elif col in ("runtime_mean", "SHD_mean", "F1_mean"):
                val = format_val(val, 2)
            elif col in ("successful_runs", "failed_runs"):
                val = format_val(val, 0)
            cells.append(val)
        f.write(" & ".join(cells) + r" \\" + "\n")
    f.write(r"\bottomrule" + "\n")
    f.write(r"\end{tabular}" + "\n")
    f.write(r"\end{table}" + "\n")
print(f"Written: {summary_tex}")

# ---------------------------------------------------------------------------
# 4. Generate trend comparison LaTeX table
# ---------------------------------------------------------------------------
trend_csv_path = os.path.join(RESULTS_TABLES, "original_trend_comparison.csv")
trend_tex = os.path.join(REPORT_TABLES, "original_trend_comparison.tex")
if os.path.exists(trend_csv_path):
    with open(trend_csv_path, newline="", encoding="utf-8") as f:
        trend_rows = list(csv.DictReader(f))

    with open(trend_tex, "w", encoding="utf-8") as f:
        f.write(r"\begin{table}[htbp]" + "\n")
        f.write(r"\centering" + "\n")
        f.write(r"\footnotesize" + "\n")
        f.write(r"\caption{原论文趋势对照表}" + "\n")
        f.write(r"\label{tab:original_trend}" + "\n")
        f.write(r"\setlength{\tabcolsep}{3pt}" + "\n")
        f.write(r"\begin{tabularx}{\linewidth}{p{3.2cm}p{3.0cm}p{3.0cm}Yp{1.5cm}}" + "\n")
        f.write(r"\toprule" + "\n")
        f.write("Paper & Original Scale & Original Trend & Our Comparison & Level \\\\\n")
        f.write(r"\midrule" + "\n")
        for row in trend_rows:
            paper = escape_tex(row.get("paper", ""))
            scale = escape_tex(row.get("original_scale", ""))
            trend = escape_tex(row.get("original_trend", ""))
            comp  = escape_tex(row.get("our_comparison", ""))
            level = escape_tex(row.get("comparable_level", ""))
            # abbreviate level
            lvl_map = {
                "scale_only": "scale-only",
                "approximate": "approx.",
                "direct": "direct",
                "failed": "failed",
            }
            level = lvl_map.get(level, level)
            f.write(f"{paper} & {scale} & {trend} & {comp} & {level} \\\\\n")
        f.write(r"\bottomrule" + "\n")
        f.write(r"\end{tabularx}" + "\n")
        f.write(r"\end{table}" + "\n")
    print(f"Written: {trend_tex}")
else:
    print(f"WARNING: {trend_csv_path} not found; skipping trend table")

# ---------------------------------------------------------------------------
# 5. Copy figures to report directory
# ---------------------------------------------------------------------------
for fname in os.listdir(RESULTS_FIGS):
    src = os.path.join(RESULTS_FIGS, fname)
    dst = os.path.join(REPORT_FIGS, fname)
    if os.path.isfile(src) and fname.endswith(".png"):
        shutil.copy2(src, dst)
        print(f"Copied: {fname}")

print("\nDone. Tables in", REPORT_TABLES)
print("Figures in", REPORT_FIGS)
print("\nNext: recompile Report.tex with xelatex")
