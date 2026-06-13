#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "matplotlib>=3.8",
#     "seaborn>=0.13",
#     "pandas>=2.0",
#     "numpy>=1.24",
# ]
# ///
"""
Generate publication-quality figures for Bayesian network MCMC comparison report.
Reads CSV result tables and produces combined figures.

Usage: uv run scripts/plot_results.py
Output: results/figures/py_*.png
"""

import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
import seaborn as sns
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
TABLES = PROJECT / "results" / "tables"
FIGURES = PROJECT / "results" / "figures"
FIGURES.mkdir(parents=True, exist_ok=True)

# === Style ===
plt.rcParams.update({
    "figure.dpi": 200,
    "font.size": 11,
    "axes.titlesize": 13,
    "axes.labelsize": 12,
    "legend.fontsize": 10,
    "figure.facecolor": "white",
    "axes.facecolor": "white",
    "axes.grid": True,
    "grid.alpha": 0.45,
    "grid.color": "#D8D8D8",
    "grid.linewidth": 0.6,
    "axes.edgecolor": "#222222",
    "axes.linewidth": 0.8,
})
PALETTE = {
    "order": "#222222",
    "partition": "#666666",
    "iterative": "#9A9A9A",
    "manual_order": "#222222",
    "manual_partition": "#666666",
    "manual_structure": "#9A9A9A",
}
LINESTYLES = {
    "order": "-",
    "partition": "--",
    "iterative": ":",
    "manual_order": "-",
    "manual_partition": "--",
    "manual_structure": ":",
}
MARKERS = {
    "order": "o",
    "partition": "s",
    "iterative": "^",
    "manual_order": "o",
    "manual_partition": "s",
    "manual_structure": "^",
}


def load_csv(name: str) -> pd.DataFrame:
    path = TABLES / name
    if not path.exists():
        raise FileNotFoundError(f"Missing table: {path}")
    return pd.read_csv(path)


def save(fig, name: str) -> None:
    path = FIGURES / f"py_{name}.png"
    fig.savefig(path, bbox_inches="tight", dpi=200, facecolor="white")
    plt.close(fig)
    print(f"  Saved: {path}")


# ====================================================================
# Figure 1: Small-scale comparison (p=10,20  n=200,500)
# ====================================================================
def plot_small_compare():
    df = load_csv("small_compare_metrics.csv")
    # Aggregate over seeds
    g = df.groupby(["method", "p", "n"])[["SHD", "F1", "runtime"]].mean().reset_index()
    g["label"] = g.apply(lambda r: f"p={int(r.p)}, n={int(r.n)}", axis=1)

    fig, axes = plt.subplots(1, 3, figsize=(14, 4.2))

    for ax, metric, title in zip(axes, ["SHD", "F1", "runtime"],
                                  ["SHD (lower is better)", "F1 (higher is better)",
                                   "Runtime (seconds)"]):
        for method in ["order", "partition"]:
            sub = g[g["method"] == method]
            ax.plot(sub["label"], sub[metric], marker=MARKERS[method], ms=6,
                    color=PALETTE[method], linewidth=1.6,
                    linestyle=LINESTYLES[method], label=method.capitalize())
        ax.set_title(title)
        ax.tick_params(axis="x", rotation=25)
        ax.legend(frameon=True, fancybox=False, edgecolor="#333333")

    fig.suptitle("Order MCMC vs Partition MCMC: Small-Scale Comparison",
                 fontweight="bold", y=1.02)
    fig.tight_layout()
    save(fig, "small_compare_combined")


# ====================================================================
# Figure 2: Sample size effect (p=20, n=100,200,500,1000)
# ====================================================================
def plot_sample_size():
    df = load_csv("sample_size_metrics.csv")
    g = df.groupby(["method", "n"])[["SHD", "F1", "runtime"]].mean().reset_index()

    fig, axes = plt.subplots(1, 3, figsize=(14, 4.2))

    for ax, metric, title in zip(axes, ["SHD", "F1", "runtime"],
                                  ["SHD vs Sample Size", "F1 vs Sample Size",
                                   "Runtime vs Sample Size"]):
        for method in ["order", "partition"]:
            sub = g[g["method"] == method]
            ax.plot(sub["n"], sub[metric], marker=MARKERS[method], ms=6,
                    color=PALETTE[method], linewidth=1.6,
                    linestyle=LINESTYLES[method], label=method.capitalize())
        ax.set_xlabel("Sample size (n)")
        ax.set_ylabel(metric)
        ax.set_title(title)
        ax.legend(frameon=True, fancybox=False, edgecolor="#333333")
        ax.set_xticks([100, 200, 500, 1000])

    fig.suptitle("Effect of Sample Size on Structure Recovery (p=20)",
                 fontweight="bold", y=1.02)
    fig.tight_layout()
    save(fig, "sample_size_combined")


# ====================================================================
# Figure 3: Manual MCMC sensitivity to max_parents
# ====================================================================
def plot_manual_sensitivity():
    df = load_csv("manual_sensitivity_metrics.csv")
    g = df.groupby(["method", "max_parents"])[["F1", "SHD", "runtime"]].mean().reset_index()

    fig, axes = plt.subplots(1, 3, figsize=(14, 4.2))

    for ax, metric, title in zip(axes, ["SHD", "F1", "runtime"],
                                  ["SHD vs Max Parents", "F1 vs Max Parents",
                                   "Runtime vs Max Parents"]):
        for method in sorted(g["method"].unique()):
            sub = g[g["method"] == method]
            ax.plot(sub["max_parents"], sub[metric],
                    marker=MARKERS.get(method, "D"), ms=6,
                    color=PALETTE.get(method, "#777777"), linewidth=1.6,
                    linestyle=LINESTYLES.get(method, "-"),
                    label=method.replace("manual_", "").capitalize())
        ax.set_xlabel("Max parents (K)")
        ax.set_ylabel(metric)
        ax.set_title(title)
        ax.legend(frameon=True, fancybox=False, edgecolor="#333333")
        ax.set_xticks([1, 2, 3])

    fig.suptitle("Effect of Parent-Set Constraint on Manual MCMC (p=8, n=120)",
                 fontweight="bold", y=1.02)
    fig.tight_layout()
    save(fig, "manual_sensitivity_combined")


# ====================================================================
# Figure 4: Posterior uncertainty summary (entropy heatmap)
# ====================================================================
def plot_posterior_uncertainty():
    df = load_csv("posterior_uncertainty_metrics.csv")
    g = df.groupby(["method", "p", "n"])[["mean_entropy", "true_edge_mean_posterior",
                                           "false_edge_mean_posterior"]].mean().reset_index()

    fig, axes = plt.subplots(1, 2, figsize=(13, 4.8))

    # Left: entropy by p
    ax = axes[0]
    for method in sorted(g["method"].unique()):
        sub = g[g["method"] == method]
        ax.scatter(sub["p"], sub["mean_entropy"], s=44, alpha=0.9,
                   marker=MARKERS.get(method, "o"),
                   color=PALETTE.get(method, "#777777"), label=method.capitalize())
        if len(sub) > 1:
            sub_sorted = sub.sort_values("p")
            ax.plot(sub_sorted["p"], sub_sorted["mean_entropy"],
                    color=PALETTE.get(method, "#777777"), linewidth=1.4,
                    linestyle=LINESTYLES.get(method, "-"), alpha=0.85)
    ax.set_xlabel("Number of nodes (p)")
    ax.set_ylabel("Mean Edge Posterior Entropy")
    ax.set_title("Structural Uncertainty by Dimension")
    ax.legend(frameon=True, fancybox=False, edgecolor="#333333")

    # Right: posterior gap by n
    ax = axes[1]
    g["posterior_gap"] = g["true_edge_mean_posterior"] - g["false_edge_mean_posterior"]
    for method in sorted(g["method"].unique()):
        sub = g[g["method"] == method].dropna(subset=["n", "posterior_gap"])
        ax.scatter(sub["n"], sub["posterior_gap"], s=44, alpha=0.9,
                   marker=MARKERS.get(method, "o"),
                   color=PALETTE.get(method, "#777777"), label=method.capitalize())
        if len(sub) > 1:
            sub_sorted = sub.sort_values("n")
            ax.plot(sub_sorted["n"], sub_sorted["posterior_gap"],
                    color=PALETTE.get(method, "#777777"), linewidth=1.4,
                    linestyle=LINESTYLES.get(method, "-"), alpha=0.85)
    ax.set_xlabel("Sample size (n)")
    ax.set_ylabel("True - False Edge Posterior")
    ax.set_title("Posterior Separation by Sample Size")
    ax.legend(frameon=True, fancybox=False, edgecolor="#333333")

    fig.suptitle("Posterior Uncertainty Quantification Across Methods",
                 fontweight="bold", y=1.02)
    fig.tight_layout()
    save(fig, "posterior_uncertainty_combined")


# ====================================================================
# Figure 5: All-methods SHD comparison bar chart
# ====================================================================
def plot_all_methods_comparison():
    fig, ax = plt.subplots(figsize=(10, 4.5))

    # Collect data from multiple sources
    sources = {
        "Small (10,200)": ("small_compare_metrics.csv", None),
        "Small (20,500)": ("small_compare_metrics.csv", None),
        "Medium (30,500)": ("medium_compare_metrics.csv", None),
        "Manual (8,120)": ("manual_validation_metrics.csv", None),
    }

    records = []
    for label, (csv_name, _) in sources.items():
        try:
            df = pd.read_csv(TABLES / csv_name)
            for _, row in df.iterrows():
                records.append({
                    "Experiment": label,
                    "Method": row["method"],
                    "SHD": row["SHD"],
                    "F1": row["F1"],
                })
        except Exception:
            pass

    if records:
        all_df = pd.DataFrame(records)
        all_df = all_df.dropna(subset=["SHD", "F1"])
        g = all_df.groupby(["Experiment", "Method"])[["SHD", "F1"]].mean().reset_index()

        x = np.arange(len(g["Experiment"].unique()))
        width = 0.25
        methods = sorted(g["Method"].unique())

        for i, method in enumerate(methods):
            sub = g[g["Method"] == method]
            vals = []
            for exp in g["Experiment"].unique():
                m = sub[sub["Experiment"] == exp]
                vals.append(m["SHD"].values[0] if len(m) > 0 else np.nan)
            ax.bar(x + i * width, vals, width, label=method.capitalize(),
                   color=PALETTE.get(method, "#777777"), alpha=0.95,
                   edgecolor="#222222", linewidth=0.5)

        ax.set_xticks(x + width * (len(methods) - 1) / 2)
        ax.set_xticklabels(g["Experiment"].unique(), rotation=15)
        ax.set_ylabel("Mean SHD")
        ax.set_title("Structure Recovery (SHD) Across Experiments")
        ax.legend(frameon=True, fancybox=False, edgecolor="#333333")
        fig.tight_layout()
        save(fig, "all_methods_shd")


# ====================================================================
# Figure 6: Manual MCMC validation (3 methods comparison)
# ====================================================================
def plot_manual_validation():
    df = load_csv("manual_validation_metrics.csv")
    g = df.groupby("method")[["SHD", "F1", "runtime"]].mean().reset_index()

    fig, axes = plt.subplots(1, 3, figsize=(13, 4.0))

    for ax, metric, title, color_map in zip(
        axes,
        ["SHD", "F1", "runtime"],
        ["SHD (lower is better)", "F1 (higher is better)", "Runtime (seconds)"],
        [None, None, None],
    ):
        methods = g["method"].str.replace("manual_", "").str.capitalize()
        colors = [PALETTE.get(m, "#777777") for m in g["method"]]
        bars = ax.bar(methods, g[metric], color=colors, alpha=0.95,
                      width=0.5, edgecolor="#222222", linewidth=0.5)
        for bar, val in zip(bars, g[metric]):
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + max(g[metric]) * 0.02,
                    f"{val:.2f}", ha="center", fontsize=9)
        ax.set_title(title)
        ax.tick_params(axis="x", rotation=0)

    fig.suptitle("Manual MCMC Validation (p=8, n=120)", fontweight="bold", y=1.02)
    fig.tight_layout()
    save(fig, "manual_validation_combined")


# ====================================================================
# Figure 7: Manual implementation versus BiDAG on small p
# ====================================================================
def plot_manual_bidag_comparison():
    g = load_csv("manual_bidag_compare_summary.csv").copy()
    g["K"] = g["K"].fillna("N/A").astype(str)
    g["K"] = g["K"].str.replace(r"\.0$", "", regex=True)

    def label(row):
        method = row["method"].replace("manual_", "").replace("_", " ").title()
        if row["implementation"] == "manual":
            short = {"Structure": "Struct.", "Order": "Order", "Partition": "Part."}.get(method, method)
            return f"Manual\n{short} K{row['K']}"
        short = {"Order": "Order", "Partition": "Part."}.get(method, method)
        return f"BiDAG\n{short}"

    order = [
        ("BiDAG", "order", "N/A"),
        ("BiDAG", "partition", "N/A"),
        ("manual", "manual_structure", "2"),
        ("manual", "manual_order", "2"),
        ("manual", "manual_order", "3"),
        ("manual", "manual_partition", "2"),
        ("manual", "manual_partition", "3"),
    ]
    rank = {key: i for i, key in enumerate(order)}
    g["_rank"] = g.apply(lambda r: rank[(r["implementation"], r["method"], str(r["K"]))], axis=1)
    g = g.sort_values("_rank")
    g["label"] = g.apply(label, axis=1)
    colors = ["#2B2B2B", "#4A4A4A", "#9A9A9A", "#777777", "#555555", "#888888", "#666666"]

    fig, axes = plt.subplots(1, 3, figsize=(14, 4.2))
    for ax, metric, title in zip(
        axes,
        ["SHD", "F1", "runtime"],
        ["SHD (lower is better)", "F1 (higher is better)", "Runtime (seconds)"],
    ):
        bars = ax.bar(g["label"], g[metric], color=colors,
                      edgecolor="#222222", linewidth=0.5, width=0.62)
        offset = max(g[metric]) * 0.025 if max(g[metric]) > 0 else 0.02
        for bar, val in zip(bars, g[metric]):
            ax.text(bar.get_x() + bar.get_width() / 2,
                    bar.get_height() + offset,
                    f"{val:.2f}", ha="center", va="bottom", fontsize=8)
        ax.set_title(title)
        ax.tick_params(axis="x", labelsize=8)
        ax.margins(y=0.18)

    fig.suptitle("Matched Manual Implementation vs BiDAG Comparison",
                 fontweight="bold", y=1.02)
    fig.tight_layout()
    save(fig, "manual_bidag_comparison")


# ====================================================================
# Main
# ====================================================================
if __name__ == "__main__":
    print("Generating Python-based figures...")
    try:
        plot_small_compare()
    except Exception as e:
        print(f"  [SKIP] small_compare: {e}")
    try:
        plot_sample_size()
    except Exception as e:
        print(f"  [SKIP] sample_size: {e}")
    try:
        plot_manual_sensitivity()
    except Exception as e:
        print(f"  [SKIP] sensitivity: {e}")
    try:
        plot_posterior_uncertainty()
    except Exception as e:
        print(f"  [SKIP] posterior: {e}")
    try:
        plot_all_methods_comparison()
    except Exception as e:
        print(f"  [SKIP] all_methods: {e}")
    try:
        plot_manual_validation()
    except Exception as e:
        print(f"  [SKIP] manual_validation: {e}")
    try:
        plot_manual_bidag_comparison()
    except Exception as e:
        print(f"  [SKIP] manual_bidag_comparison: {e}")
    print("Done.")
