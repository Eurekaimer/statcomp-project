"""
Generate polished LaTeX tables + figures for report.
"""
import csv, os, sys, math
from collections import defaultdict

PROJECT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
RESULTS = os.path.join(PROJECT, "results", "medium_original_reproduction")
REPORT_TABLES = os.path.join(PROJECT, "report", "tables", "medium_original_reproduction")
REPORT_FIGS   = os.path.join(PROJECT, "report", "figures", "medium_original_reproduction")

metrics_csv = os.path.join(RESULTS, "tables", "medium_original_metrics.csv")
if not os.path.exists(metrics_csv):
    print(f"ERROR: {metrics_csv} not found"); sys.exit(1)

with open(metrics_csv, newline="") as f:
    rows = list(csv.DictReader(f))
print(f"Loaded {len(rows)} rows")

os.makedirs(REPORT_TABLES, exist_ok=True)
os.makedirs(REPORT_FIGS, exist_ok=True)

def esc(s):
    return str(s).replace("_", "\\_").replace("#", "\\#").replace("%", "\\%").replace("&", "\\&")

def fmt(v, d=2):
    try:
        x = float(v)
        if math.isnan(x): return "---"
        return f"{x:.{d}f}"
    except: return "---"

# Aggregate by averaging over n within each (p, method, implementation) for compact display
agg = defaultdict(list)
for r in rows:
    if r.get("status") != "success": continue
    key = (r["experiment_group"], int(r["p"]), r["method"], r["implementation"])
    for col in ["SHD","F1","runtime","TPR","acceptance_rate","mean_edge_entropy","posterior_gap"]:
        try: agg[key].append(float(r[col]))
        except: pass

agg_rows = []
for (eg, p, method, impl), vals in sorted(agg.items()):
    d = {"exp_group": eg, "p": p, "method": method, "impl": impl, "n_runs": len(vals)}
    nums = {}
    for col in ["SHD","F1","runtime","TPR","acceptance_rate","mean_edge_entropy","posterior_gap"]:
        vs = [float(r[col]) for r in rows if r["experiment_group"]==eg and int(r["p"])==p
              and r["method"]==method and r["implementation"]==impl and r["status"]=="success"
              and r.get(col) not in (None,"","NA")]
        if vs:
            nums[f"{col}_mean"] = sum(vs)/len(vs)
            nums[f"{col}_sd"] = (sum((x-sum(vs)/len(vs))**2 for x in vs)/(len(vs)-1))**0.5 if len(vs)>1 else 0
    agg_rows.append({**d, **nums})

# =====================================================================
# TABLE A: Order MCMC experiment (p=9, 37) — compact
# =====================================================================
exp_name = {"order_mcmc": "Order MCMC (F\\&K 2003)", "partition_mcmc": "Partition MCMC (K\\&M 2017)",
            "hybrid_iterative": "Hybrid/Iter (KSM 2022)"}
impl_short = {"Python": "Py", "BiDAG": "BD", "manual_R": "mR"}

with open(os.path.join(REPORT_TABLES, "medium_original_summary.tex"), "w", encoding="utf-8") as f:
    f.write(r"\begin{table}[htbp]" + "\n")
    f.write(r"\centering\footnotesize" + "\n")
    f.write(r"\caption{中等规模原论文对照实验结果（按维度 $p$ 和方法聚合，平均所有 $n$)}" + "\n")
    f.write(r"\label{tab:medium_original_summary}" + "\n")
    f.write(r"\setlength{\tabcolsep}{3pt}" + "\n")
    f.write(r"\begin{tabular}{c c l l c c c c}" + "\n")
    f.write(r"\toprule" + "\n")
    f.write(r"$p$ & Experiment & Method & Impl & Mean SHD & F1 & TPR & Time(s) \\" + "\n")
    f.write(r"\midrule" + "\n")

    last_p = None
    exp_order = {"partition_mcmc": 0, "order_mcmc": 1, "hybrid_iterative": 2}
    impl_order = {"Python": 0, "manual_R": 1, "BiDAG": 2}
    for ar in sorted(agg_rows, key=lambda x: (x["p"], exp_order.get(x["exp_group"], 99), x["method"], impl_order.get(x["impl"], 99))):
        if ar["p"] != last_p:
            if last_p is not None:
                f.write(r"\addlinespace[2pt]" + "\n")
            last_p = ar["p"]
        f.write(f"{ar['p']} & {exp_name.get(ar['exp_group'], ar['exp_group'])} & "
                f"{esc(ar['method'])} & {impl_short.get(ar['impl'], ar['impl'])} & "
                f"{fmt(ar['SHD_mean'],1)} & {fmt(ar['F1_mean'],3)} & "
                f"{fmt(ar['TPR_mean'],3)} & {fmt(ar['runtime_mean'],1)} \\\\\n")
    f.write(r"\bottomrule" + "\n")
    f.write(r"\end{tabular}" + "\n")
    f.write(r"\begin{flushleft}\footnotesize Py = Python implementation, BD = BiDAG, mR = manual R. SHD/F1/TPR/Time averaged over all $n$ and seeds.\end{flushleft}" + "\n")
    f.write(r"\end{table}" + "\n")
print("Written: medium_original_summary.tex (compact)")

# =====================================================================
# TABLE B: Order vs Structure gap
# =====================================================================
with open(os.path.join(REPORT_TABLES, "order_vs_structure_gap.tex"), "w", encoding="utf-8") as f:
    f.write(r"\begin{table}[htbp]" + "\n")
    f.write(r"\centering" + "\n")
    f.write(r"\caption{Order MCMC 与 Structure MCMC 的性能差距随维度增大加速扩大（Python 实现，平均所有 $n$）}" + "\n")
    f.write(r"\label{tab:order_vs_structure}" + "\n")
    f.write(r"\begin{tabular}{c c c c c c c}" + "\n")
    f.write(r"\toprule" + "\n")
    f.write(r"$p$ & Data source & Order SHD & Order F1 & Struct SHD & Struct F1 & $\Delta$SHD \\" + "\n")
    f.write(r"\midrule" + "\n")
    for p in [5, 9, 14, 20, 37]:
        o_s = [float(r["SHD"]) for r in rows if int(r["p"])==p and r["method"]=="python_order" and r["status"]=="success"]
        s_s = [float(r["SHD"]) for r in rows if int(r["p"])==p and r["method"]=="python_structure" and r["status"]=="success"]
        o_f = [float(r["F1"]) for r in rows if int(r["p"])==p and r["method"]=="python_order" and r["status"]=="success"]
        s_f = [float(r["F1"]) for r in rows if int(r["p"])==p and r["method"]=="python_structure" and r["status"]=="success"]
        if o_s and s_s:
            ds_map = {5: "toy", 9: "flare", 14: "boston", 20: "large", 37: "alarm"}
            o_shd, s_shd = sum(o_s)/len(o_s), sum(s_s)/len(s_s)
            o_f1v, s_f1v = sum(o_f)/len(o_f), sum(s_f)/len(s_f)
            gap = s_shd - o_shd
            f.write(f"{p} & {ds_map[p]}-like & {fmt(o_shd,1)} & {fmt(o_f1v,3)} & "
                    f"{fmt(s_shd,1)} & {fmt(s_f1v,3)} & +{fmt(gap,0)} \\\\\n")
    f.write(r"\bottomrule" + "\n")
    f.write(r"\end{tabular}" + "\n")
    f.write(r"\end{table}" + "\n")
print("Written: order_vs_structure_gap.tex")

# =====================================================================
# TABLE C: Best method per dimension
# =====================================================================
with open(os.path.join(REPORT_TABLES, "implementation_comparison.tex"), "w", encoding="utf-8") as f:
    f.write(r"\begin{table}[htbp]" + "\n")
    f.write(r"\centering" + "\n")
    f.write(r"\caption{各维度 $p$ 下的最高单次 F1 及三种实现的最高 F1}" + "\n")
    f.write(r"\label{tab:impl_compare}" + "\n")
    f.write(r"\begin{tabular}{c l c c c c c}" + "\n")
    f.write(r"\toprule" + "\n")
    f.write(r"$p$ & Best Single Run & SHD & F1 & Python F1 & BiDAG F1 & manual F1 \\" + "\n")
    f.write(r"\midrule" + "\n")
    for p in [5, 9, 14, 20, 37]:
        best = max((r for r in rows if int(r["p"])==p and r["status"]=="success"),
                   key=lambda r: float(r["F1"]))
        py_f1 = max((float(r["F1"]) for r in rows if int(r["p"])==p and r["implementation"]=="Python" and r["status"]=="success"), default=0)
        bd_f1 = max((float(r["F1"]) for r in rows if int(r["p"])==p and r["implementation"]=="BiDAG" and r["status"]=="success"), default=0)
        mr_f1 = max((float(r["F1"]) for r in rows if int(r["p"])==p and r["implementation"]=="manual_R" and r["status"]=="success"), default=0)
        label = f"{esc(best['method'])} ({impl_short.get(best['implementation'], best['implementation'])})"
        f.write(f"{p} & {label} & {fmt(best['SHD'],1)} & {fmt(best['F1'],3)} & "
                f"{fmt(py_f1,3)} & {fmt(bd_f1,3)} & {fmt(mr_f1,3)} \\\\\n")
    f.write(r"\bottomrule" + "\n")
    f.write(r"\end{tabular}" + "\n")
    f.write(r"\end{table}" + "\n")
print("Written: implementation_comparison.tex")

# =====================================================================
# FIGURES — polished
# =====================================================================
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams.update({
    "font.size": 11, "axes.titlesize": 13, "axes.labelsize": 12,
    "legend.fontsize": 9, "xtick.labelsize": 10, "ytick.labelsize": 10,
    "figure.dpi": 150, "savefig.dpi": 200, "savefig.bbox": "tight",
    "font.family": "sans-serif",
    "axes.edgecolor": "#444444", "axes.linewidth": 0.8,
    "xtick.color": "#444444", "ytick.color": "#444444",
})

# Okabe-Ito colorblind-friendly palette (subset)
IMPL_COLORS = {"Python": "#D55E00", "BiDAG": "#0072B2", "manual_R": "#009E73"}
METHOD_MARKERS = {"python_order": "o", "python_structure": "X", "order": "D", "partition": "s",
                  "manual_order": "o", "manual_structure": "X", "manual_partition": "v",
                  "iterative": "P"}
IMPL_ALPHA = {"Python": 0.82, "BiDAG": 0.92, "manual_R": 0.72}
METHOD_ALPHA = {"python_order": 1.0, "python_structure": 0.55, "order": 1.0, "partition": 1.0,
                "manual_order": 1.0, "manual_structure": 0.55, "manual_partition": 0.8, "iterative": 1.0}

success = [r for r in rows if r["status"] == "success"]
ps = sorted(set(int(r["p"]) for r in success))

# ---- Figure 6: F1 vs p, faceted by experiment ----
fig, axes = plt.subplots(1, 2, figsize=(12, 4.8), sharey=True)
bg_color = "#F8F8F8"
for axi, eg in enumerate(["order_mcmc", "partition_mcmc"]):
    ax = axes[axi]
    ax.set_facecolor(bg_color)
    eg_label = {"order_mcmc": "Order MCMC (Friedman & Koller 2003)",
                 "partition_mcmc": "Partition MCMC (Kuipers & Moffa 2017)"}[eg]
    eg_ps = sorted(set(int(r["p"]) for r in success if r["experiment_group"] == eg))

    # Draw faint reference bands
    for p in eg_ps:
        ax.axvline(x=p, color="#CCCCCC", linewidth=0.5, linestyle=":", zorder=0)

    for impl in ["Python", "BiDAG", "manual_R"]:
        eg_methods = sorted(set(r["method"] for r in success
                                if r["experiment_group"]==eg and r["implementation"]==impl))
        for method in eg_methods:
            grouped = defaultdict(list)
            for r in success:
                if int(r["p"]) in eg_ps and r["implementation"]==impl and r["method"]==method:
                    grouped[int(r["p"])].append(float(r["F1"]))
            if not grouped: continue
            x_means = sorted(grouped.keys())
            y_means = [sum(grouped[p])/len(grouped[p]) for p in x_means]
            marker = METHOD_MARKERS.get(method, "o")
            color = IMPL_COLORS[impl]
            alpha = METHOD_ALPHA.get(method, 0.85) * IMPL_ALPHA[impl]
            # Connecting line
            ax.plot(x_means, y_means, "-", color=color, linewidth=1.3, alpha=alpha*0.7, zorder=2)
            # Mean points
            ax.scatter(x_means, y_means, marker=marker, s=70, c=color, alpha=alpha,
                      edgecolors="white", linewidth=0.8, label=f"{method} ({impl})", zorder=4)

    ax.set_title(eg_label, fontweight="bold", fontsize=12, pad=10)
    ax.set_xlabel("Number of nodes (p)")
    ax.set_xticks(eg_ps)
    ax.set_ylim(-0.05, 1.08)
    ax.grid(True, alpha=0.25, linestyle="--", linewidth=0.4)
    ax.legend(fontsize=6.5, ncol=2, loc="lower left", framealpha=0.92,
              edgecolor="#DDDDDD", fancybox=False)

axes[0].set_ylabel("F1 Score", fontweight="bold")
fig.suptitle("F1 Score by Dimension and Implementation", fontsize=14, fontweight="bold", y=1.02)
plt.tight_layout()
fig.savefig(os.path.join(REPORT_FIGS, "medium_f1_shd_compare.png"))
plt.close()
print("Generated: medium_f1_shd_compare.png")

# ---- Figure 7: SHD vs runtime bubble chart ----
fig, ax = plt.subplots(figsize=(9, 5.5))
ax.set_facecolor("#F8F8F8")
for impl in ["Python", "BiDAG", "manual_R"]:
    impl_data = [(float(r["SHD"]), float(r["runtime"]), float(r["F1"]), int(r["p"]), r["method"])
                 for r in success if r["implementation"] == impl]
    if not impl_data: continue
    xs = [d[0] for d in impl_data]
    ys = [d[1] for d in impl_data]
    sz = [d[2]*140+25 for d in impl_data]
    ax.scatter(xs, ys, s=sz, c=IMPL_COLORS[impl], alpha=0.55,
               edgecolors="white", linewidth=0.6, label=impl, zorder=4)
    # Annotate outliers
    for d in impl_data:
        if d[1] > 10 or d[0] > 50:
            ax.annotate(f"p={d[3]}", (d[0], d[1]), fontsize=7, color="#555555",
                       textcoords="offset points", xytext=(5, 2), zorder=5)

ax.set_xlabel("SHD (lower → better)", fontweight="bold")
ax.set_ylabel("Runtime (seconds, log scale)", fontweight="bold")
ax.set_yscale("log")
ax.set_title("SHD vs Runtime Trade-off", fontweight="bold", fontsize=13)
ax.legend(fontsize=9, framealpha=0.92, edgecolor="#DDDDDD", fancybox=False,
          title="Bubble size = F1 score", title_fontsize=8)
ax.grid(True, alpha=0.25, linestyle="--", linewidth=0.4)
plt.tight_layout()
fig.savefig(os.path.join(REPORT_FIGS, "medium_runtime_compare.png"))
plt.close()
print("Generated: medium_runtime_compare.png")

# ---- SHD gap bar chart ----
fig, ax = plt.subplots(figsize=(7.5, 4.5))
ax.set_facecolor("#F8F8F8")
ps_plot = [5, 9, 14, 20, 37]
gaps, f1_drops = [], []
for p in ps_plot:
    o_s = [float(r["SHD"]) for r in rows if int(r["p"])==p and r["method"]=="python_order" and r["status"]=="success"]
    s_s = [float(r["SHD"]) for r in rows if int(r["p"])==p and r["method"]=="python_structure" and r["status"]=="success"]
    o_f = [float(r["F1"]) for r in rows if int(r["p"])==p and r["method"]=="python_order" and r["status"]=="success"]
    s_f = [float(r["F1"]) for r in rows if int(r["p"])==p and r["method"]=="python_structure" and r["status"]=="success"]
    if o_s and s_s:
        gaps.append(sum(s_s)/len(s_s) - sum(o_s)/len(o_s))
        f1_drops.append(sum(o_f)/len(o_f) - sum(s_f)/len(s_f))

# Sequential warm-to-hot gradient
bar_colors = ["#FDD49E", "#FDAE61", "#F46D43", "#D73027", "#A50026"]
bars = ax.bar(range(len(ps_plot)), gaps, color=bar_colors[:len(gaps)],
              edgecolor="white", linewidth=0.8, width=0.6)
ax.set_xticks(range(len(ps_plot)))
ax.set_xticklabels([f"p={p}" for p in ps_plot], fontsize=11)
ax.set_ylabel("SHD Gap (Structure − Order)", fontweight="bold")
ax.set_title("Order MCMC vs Structure MCMC: Accelerating Divergence", fontweight="bold", fontsize=13)
ax.grid(axis="y", alpha=0.25, linestyle="--", linewidth=0.4)

# F1 drop labels on bars
for i, (gap, drop) in enumerate(zip(gaps, f1_drops)):
    ax.text(i, gap + max(gaps)*0.03, f"ΔF1\n={drop:.2f}",
            fontsize=8, ha="center", va="bottom", color="#444444", fontweight="bold")

plt.tight_layout()
fig.savefig(os.path.join(REPORT_FIGS, "order_structure_gap.png"))
plt.close()
print("Generated: order_structure_gap.png")

print(f"\nAll assets ready in {REPORT_TABLES} and {REPORT_FIGS}")
