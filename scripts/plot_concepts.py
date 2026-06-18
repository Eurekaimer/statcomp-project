#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["matplotlib>=3.8", "numpy>=1.24"]
# ///
# Draw concept figures.

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.font_manager as fm
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
FIGURES = PROJECT / "results" / "figures"
FIGURES.mkdir(parents=True, exist_ok=True)

for name in ["Microsoft YaHei", "SimHei", "SimSun", "WenQuanYi Micro Hei", "Noto Sans CJK SC"]:
    for f in fm.fontManager.ttflist:
        if f.name == name:
            plt.rcParams["font.sans-serif"] = [name, "DejaVu Sans"]
            plt.rcParams["axes.unicode_minus"] = False
            print(f"Using font: {name}")
            break
    else:
        continue
    break

plt.rcParams["figure.dpi"] = 180
plt.rcParams["font.size"] = 10


def draw_arrow(ax, x1, y1, x2, y2, color="gray", lw=2):
    ax.annotate("", xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle="->", color=color, lw=lw))


def fig1_structure_mcmc():
    # Structure MCMC.
    fig, ax = plt.subplots(figsize=(10, 1.2))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 1.2)
    ax.axis("off")

    boxes = [
        (0.3, "当前图 G"),
        (2.3, "生成候选图\n(Add/Delete/Reverse)"),
        (4.5, "无环检查\n(含环则拒绝)"),
        (6.8, "MH 接受判定"),
        (9.0, "累积边后验"),
    ]
    for x, text in boxes:
        rect = mpatches.FancyBboxPatch((x, 0.35), 1.8, 0.55, boxstyle="round,pad=0.15",
                                        facecolor="#E8F0FE", edgecolor="#555", linewidth=1.2)
        ax.add_patch(rect)
        ax.text(x + 0.9, 0.625, text, ha="center", va="center", fontsize=9)

    for i in range(len(boxes) - 1):
        x1 = boxes[i][0] + 1.8
        x2 = boxes[i + 1][0]
        draw_arrow(ax, x1, 0.625, x2, 0.625)

    ax.set_title("Structure MCMC 单步迭代流程", fontweight="bold", pad=8)
    fig.tight_layout()
    fig.savefig(FIGURES / "py_concept_structure_mcmc.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)
    print("  Saved: py_concept_structure_mcmc.png")


def fig2_state_spaces():
    # State spaces.
    fig, ax = plt.subplots(figsize=(10, 1.5))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 1.5)
    ax.axis("off")

    boxes = [
        (0.5,  "DAG 空间\n需显式检查无环", "#FFE0E0"),
        (3.6,  "排列空间\n自动无环，有排序偏差", "#E0E0FF"),
        (6.7,  "有序 Partition 空间\n粗粒度分组，缓解偏差", "#E0FFE0"),
    ]
    for x, text, color in boxes:
        rect = mpatches.FancyBboxPatch((x, 0.35), 2.8, 0.7, boxstyle="round,pad=0.2",
                                        facecolor=color, edgecolor="#666", linewidth=1.2)
        ax.add_patch(rect)
        ax.text(x + 1.4, 0.7, text, ha="center", va="center", fontsize=9)

    draw_arrow(ax, 3.3, 0.7, 3.6, 0.7)
    ax.text(3.45, 1.1, "状态重构", ha="center", fontsize=8, color="#555")
    draw_arrow(ax, 6.4, 0.7, 6.7, 0.7)
    ax.text(6.55, 1.1, "合并冗余", ha="center", fontsize=8, color="#555")

    ax.set_title("三种状态空间的递进关系", fontweight="bold", pad=8)
    fig.tight_layout()
    fig.savefig(FIGURES / "py_concept_state_spaces.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)
    print("  Saved: py_concept_state_spaces.png")


def fig3_hybrid_flow():
    # Hybrid MCMC.
    fig, ax = plt.subplots(figsize=(10, 1.2))
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 1.2)
    ax.axis("off")

    boxes = [
        (0.3, "条件独立筛选"),
        (2.5, "约束 MCMC 搜索"),
        (5.0, "边后验收敛判断"),
        (7.5, "输出 MAP 图\n与边后验概率"),
    ]
    for x, text in boxes:
        rect = mpatches.FancyBboxPatch((x, 0.35), 1.9, 0.55, boxstyle="round,pad=0.15",
                                        facecolor="#FFF8E0", edgecolor="#555", linewidth=1.2)
        ax.add_patch(rect)
        ax.text(x + 0.95, 0.625, text, ha="center", va="center", fontsize=9)

    for i in range(len(boxes) - 1):
        x1 = boxes[i][0] + 1.9
        x2 = boxes[i + 1][0]
        draw_arrow(ax, x1, 0.625, x2, 0.625)

    ax.annotate("未收敛，扩展候选集", xy=(3.45, 1.0), xytext=(5.95, 1.0),
                fontsize=8, color="#888", ha="center", va="center",
                arrowprops=dict(arrowstyle="->", color="#AAA", lw=1.2,
                                connectionstyle="arc3,rad=0.4"))

    ax.set_title("Hybrid / Iterative MCMC 工作流程", fontweight="bold", pad=8)
    fig.tight_layout()
    fig.savefig(FIGURES / "py_concept_hybrid_flow.png", facecolor="white", bbox_inches="tight")
    plt.close(fig)
    print("  Saved: py_concept_hybrid_flow.png")


if __name__ == "__main__":
    print("Generating concept diagrams...")
    fig1_structure_mcmc()
    fig2_state_spaces()
    fig3_hybrid_flow()
    print("Done.")
