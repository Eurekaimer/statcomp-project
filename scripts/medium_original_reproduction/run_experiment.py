# Order and Structure MCMC.

import numpy as np
import csv, os, sys, time, math
from itertools import combinations

class RNG:
    def __init__(self, seed):
        self.state = seed & 0xFFFFFFFF
    def rand(self):
        self.state ^= (self.state << 13) & 0xFFFFFFFF
        self.state ^= (self.state >> 17)
        self.state ^= (self.state << 5) & 0xFFFFFFFF
        return self.state / 4294967296.0
    def randint(self, n):
        return int(self.rand() * n)
    def randn(self):
        u1 = max(self.rand(), 1e-12)
        u2 = self.rand()
        return math.sqrt(-2.0 * math.log(u1)) * math.cos(6.283185307179586 * u2)
    def uniform(self, lo, hi):
        return lo + self.rand() * (hi - lo)
    def choice_sign(self):
        return 1.0 if self.rand() < 0.5 else -1.0

def is_dag(adj):
    p = len(adj)
    indeg = np.sum(adj, axis=0)
    q = [i for i in range(p) if indeg[i] == 0]
    head = 0
    while head < len(q):
        u = q[head]; head += 1
        for v in range(p):
            if adj[u, v]:
                indeg[v] -= 1
                if indeg[v] == 0:
                    q.append(v)
    return len(q) == p

def generate_data(p, n, rng, expected_degree=2.0):
    rho = expected_degree / (p - 1.0)
    order = list(range(p))
    for i in range(p - 1, 0, -1):
        j = rng.randint(i + 1)
        order[i], order[j] = order[j], order[i]

    true_adj = np.zeros((p, p), dtype=np.int32)
    beta = np.zeros((p, p))
    for ai, a in enumerate(range(p)):
        for b in range(ai + 1, p):
            if rng.rand() < rho:
                frm, to = order[a], order[b]
                true_adj[frm, to] = 1
                beta[frm, to] = rng.uniform(0.5, 1.5) * rng.choice_sign()

    data = np.zeros((n, p))
    for a in range(p):
        j = order[a]
        for row in range(n):
            signal = 0.0
            for i in range(p):
                if true_adj[i, j]:
                    signal += beta[i, j] * data[row, i]
            data[row, j] = signal + rng.randn()
    return true_adj, data

def local_bic(y, X_parents):
    n = len(y)
    if X_parents is None or X_parents.shape[1] == 0:
        rss = np.sum((y - np.mean(y)) ** 2)
        k = 2
    else:
        X = np.column_stack([np.ones(n), X_parents])
        beta_hat = np.linalg.lstsq(X, y, rcond=None)[0]
        resid = y - X @ beta_hat
        rss = np.sum(resid ** 2)
        k = X.shape[1] + 1
    rss = max(rss, 1e-15)
    loglik = -0.5 * n * (math.log(2 * math.pi) + 1 + math.log(rss / n))
    return loglik - 0.5 * k * math.log(n)

def best_score(data, j, allowed_mask, parent_sets_cache):
    # Pick best parent set.
    best = -1e20
    best_mask = 0
    for mask, score in parent_sets_cache[j]:
        if (mask & ~allowed_mask) == 0:
            if score > best:
                best = score
                best_mask = mask
    return best, best_mask

def precompute_scores(data, max_parents):
    p = data.shape[1]
    n = data.shape[0]
    cache = [[] for _ in range(p)]
    for j in range(p):
        candidates = [i for i in range(p) if i != j]
        score = local_bic(data[:, j], None)
        cache[j].append((0, score))
        for k in range(1, max_parents + 1):
            for comb in combinations(candidates, k):
                mask = 0
                for i in comb:
                    mask |= (1 << i)
                Xp = data[:, list(comb)]
                score = local_bic(data[:, j], Xp)
                cache[j].append((mask, score))
    return cache

def run_order_mcmc(data, mcmc_steps, burnin, max_parents, rng):
    p = data.shape[1]
    n = data.shape[0]
    cache = precompute_scores(data, max_parents)
    t0 = time.time()

    order = list(range(p))
    for i in range(p - 1, 0, -1):
        jj = rng.randint(i + 1)
        order[i], order[jj] = order[jj], order[i]

    def order_score(ord):
        allowed = 0
        total = 0.0
        for pos, j in enumerate(ord):
            sc, _ = best_score(data, j, allowed, cache)
            total += sc
            allowed |= (1 << j)
        return total

    cur_score = order_score(order)
    best_order = order[:]
    best_sc = cur_score
    edge_count = np.zeros((p, p))
    kept = 0
    accepted = 0

    for it in range(mcmc_steps):
        a, b = rng.randint(p), rng.randint(p)
        if a == b:
            continue
        prop = order[:]
        prop[a], prop[b] = prop[b], prop[a]
        prop_score = order_score(prop)
        if math.log(max(rng.rand(), 1e-15)) < prop_score - cur_score:
            order = prop
            cur_score = prop_score
            accepted += 1
        if cur_score > best_sc:
            best_order = order[:]
            best_sc = cur_score
        if it >= burnin:
            allowed = 0
            for pos, j in enumerate(order):
                _, mask = best_score(data, j, allowed, cache)
                for i in range(p):
                    if mask & (1 << i):
                        edge_count[i, j] += 1
                allowed |= (1 << j)
            kept += 1

    map_adj = np.zeros((p, p), dtype=np.int32)
    allowed = 0
    for pos, j in enumerate(best_order):
        _, mask = best_score(data, j, allowed, cache)
        for i in range(p):
            if mask & (1 << i):
                map_adj[i, j] = 1
        allowed |= (1 << j)

    edge_post = edge_count / max(kept, 1)
    runtime = time.time() - t0
    return map_adj, edge_post, runtime, accepted / max(mcmc_steps, 1), best_sc

def run_structure_mcmc(data, mcmc_steps, burnin, max_parents, rng):
    p = data.shape[1]
    n = data.shape[0]
    cache = precompute_scores(data, max_parents)
    t0 = time.time()

    adj = np.zeros((p, p), dtype=np.int32)

    def dag_score(adj_mat):
        total = 0.0
        for j in range(p):
            mask = 0
            for i in range(p):
                if adj_mat[i, j]:
                    mask |= (1 << i)
            sc, _ = best_score(data, j, mask, cache)
            total += sc
        return total

    cur_score = dag_score(adj)
    best_adj = adj.copy()
    best_sc = cur_score
    edge_count = np.zeros((p, p))
    kept = 0
    accepted = 0

    for it in range(mcmc_steps):
        move = rng.randint(3)
        prop = adj.copy()
        non_edges = [(i, j) for i in range(p) for j in range(p) if i != j and not adj[i, j]]
        edges = [(i, j) for i in range(p) for j in range(p) if adj[i, j]]

        if move == 0 and non_edges:  # add
            i, j = non_edges[rng.randint(len(non_edges))]
            if np.sum(prop[:, j]) < max_parents:
                prop[i, j] = 1
        elif move == 1 and edges:  # delete
            i, j = edges[rng.randint(len(edges))]
            prop[i, j] = 0
        elif move == 2 and edges:  # reverse
            i, j = edges[rng.randint(len(edges))]
            prop[i, j] = 0
            if np.sum(prop[:, i]) < max_parents:
                prop[j, i] = 1

        if not is_dag(prop):
            continue

        prop_score = dag_score(prop)
        if math.log(max(rng.rand(), 1e-15)) < prop_score - cur_score:
            adj = prop
            cur_score = prop_score
            accepted += 1
        if cur_score > best_sc:
            best_adj = adj.copy()
            best_sc = cur_score
        if it >= burnin:
            edge_count += adj
            kept += 1

    map_adj = best_adj
    edge_post = edge_count / max(kept, 1)
    runtime = time.time() - t0
    return map_adj, edge_post, runtime, accepted / max(mcmc_steps, 1), best_sc

def compute_metrics(true_adj, est_adj):
    p = true_adj.shape[0]
    tp = fp = tn = fn = 0
    for i in range(p):
        for j in range(p):
            if i == j: continue
            t = true_adj[i, j]
            e = est_adj[i, j]
            if t and e: tp += 1
            if not t and e: fp += 1
            if not t and not e: tn += 1
            if t and not e: fn += 1
    tpr = tp / (tp + fn) if (tp + fn) > 0 else 0.0
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0.0
    prec = tp / (tp + fp) if (tp + fp) > 0 else 0.0
    rec = tpr
    f1 = 2 * prec * rec / (prec + rec) if (prec + rec) > 0 else 0.0

    shd = 0
    for i in range(p):
        for j in range(i + 1, p):
            if (true_adj[i, j], true_adj[j, i]) != (est_adj[i, j], est_adj[j, i]):
                shd += 1
    return shd, tpr, fpr, prec, f1

def edge_entropy(edge_post):
    ep = edge_post.copy()
    ep = np.clip(ep, 1e-15, 1 - 1e-15)
    p_diag = np.diag_indices(ep.shape[0])
    ep[p_diag[0], p_diag[1]] = np.nan
    flat = ep[~np.isnan(ep)]
    return float(np.mean(-flat * np.log(flat) - (1 - flat) * np.log(1 - flat)))

def posterior_gap(true_adj, edge_post):
    p = true_adj.shape[0]
    true_vals, false_vals = [], []
    for i in range(p):
        for j in range(p):
            if i == j: continue
            if true_adj[i, j]:
                true_vals.append(edge_post[i, j])
            else:
                false_vals.append(edge_post[i, j])
    if true_vals and false_vals:
        return float(np.mean(true_vals) - np.mean(false_vals))
    return 0.0

EXPERIMENTS = {
    "order_mcmc": {
        "paper": "Friedman and Koller (2003)",
        "settings": [(p, n, seed)
            for p in [9, 37]
            for n in [500, 1000]
            for seed in range(1, 3)],
        "methods": ["order", "structure"],
        "data_source": lambda p: "simulated_flare_like" if p == 9 else "simulated_alarm_like"
    },
    "partition_mcmc": {
        "paper": "Kuipers and Moffa (2017)",
        "settings": [(p, n, seed)
            for p in [5, 14, 20]
            for n in [200, 500]
            for seed in range(1, 3)],
        "methods": ["order", "structure"],
        "data_source": lambda p: {5: "simulated_toy_like", 14: "simulated_boston_like", 20: "simulated_large_like"}[p]
    },
}

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT  = os.path.dirname(os.path.dirname(BASE_DIR))
RESULTS  = os.path.join(PROJECT, "results", "medium_original_reproduction")

def main():
    os.makedirs(os.path.join(RESULTS, "tables"), exist_ok=True)
    os.makedirs(os.path.join(RESULTS, "figures"), exist_ok=True)
    os.makedirs(os.path.join(RESULTS, "logs"), exist_ok=True)

    metrics_csv = os.path.join(RESULTS, "tables", "medium_original_metrics.csv")
    rows = []
    total = sum(len(v["settings"]) for v in EXPERIMENTS.values())

    n_done = 0
    for exp_name, exp in EXPERIMENTS.items():
        for (p, n, seed) in exp["settings"]:
            n_done += 1
            rng = RNG(seed + 10000)
            ds = exp["data_source"](p)

            print(f"[{n_done}/{total}] {exp_name} p={p} n={n} seed={seed}", end="", flush=True)

            true_adj, data = generate_data(p, n, rng)
            for method in exp["methods"]:
                rng2 = RNG(seed)
                try:
                    if method == "order":
                        est, ep, rt, ar, bs = run_order_mcmc(data, 800, 150, 2, rng2)
                    else:
                        est, ep, rt, ar, bs = run_structure_mcmc(data, 800, 150, 2, rng2)
                    shd, tpr, fpr, prec, f1 = compute_metrics(true_adj, est)
                    ent = edge_entropy(ep)
                    pgap = posterior_gap(true_adj, ep)
                    status, error, clevel = "success", "", "approximate"
                except Exception as e:
                    est, ep, rt, ar, bs = np.zeros((p,p),dtype=np.int32), np.zeros((p,p)), 0, 0, 0
                    shd, tpr, fpr, prec, f1, ent, pgap = 0, 0, 0, 0, 0, 0, 0
                    status, error, clevel = "failed", str(e), "failed"

                rows.append({
                    "paper": exp["paper"],
                    "experiment_group": exp_name,
                    "data_source": ds,
                    "p": p, "n": n, "seed": seed,
                    "method": f"python_{method}",
                    "implementation": "Python",
                    "runtime": rt,
                    "SHD": shd, "TPR": tpr, "FPR": fpr,
                    "Precision": prec, "F1": f1,
                    "acceptance_rate": ar,
                    "mean_edge_entropy": ent,
                    "posterior_gap": pgap,
                    "status": status,
                    "error": error,
                    "comparable_level": clevel,
                    "original_paper_trend": "",
                    "comment": "",
                })
                print(f"  {method}: {status} SHD={shd} F1={f1:.3f} {rt:.1f}s", flush=True)

    with open(metrics_csv, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=rows[0].keys())
        w.writeheader()
        w.writerows(rows)
    print(f"\nDone. {len(rows)} rows written to {metrics_csv}")

if __name__ == "__main__":
    main()
