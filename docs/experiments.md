# Experiment Runbook — AprioriTID

Step-by-step guide to run every experiment the report needs. Numbers you produce here feed directly into **Chapter 4 — Thực nghiệm và đánh giá**. Follow it top-to-bottom once; re-run individual sections if you need fresh numbers.

> **Crash safety.** Heavy runs are clearly marked with ⚠ warnings (RAM, wall-clock time). Close your browser and other RAM-hungry apps before those steps. Press `Ctrl+C` at any time to abort a Julia run cleanly.

---

## 0. Prerequisites (one-time)

```bash
cd /home/baobean/Dev/CSC14004-Frequent-Itemset-Mining
julia --version    # should be >= 1.9
julia --project -e 'using Pkg; Pkg.instantiate()'
```

This resolves and installs every dependency listed in `Project.toml`. Run once after cloning or after editing `Project.toml`.

---

## 1. Sanity check — run the full test suite

**Time:** ~50s · **RAM:** low · **Risk:** none

```bash
julia --project tests/runtests.jl
```

**Expected output** (last lines):

```
── Overall match vs SPMF reference: 106/106 = 100.0%
Test Summary:              | Pass  Total   Time
AprioriTID Full Test Suite |   30     30  50.4s
```

If any test fails, stop and investigate before running experiments. A failing test means the algorithm is producing wrong output and every downstream number is meaningless.

**What this gives you for the report:**
- **Section 3.3.2 (b) — Tái tạo đúng kết quả:** the "Overall match vs SPMF reference" line is what you cite. Screenshot or copy the terminal output into a figure/listing in Chapter 3.
- **Chapter 4 experiment (a) Correctness** is partially covered here too (toy datasets). The benchmark-dataset correctness goes in step 3 below.

---

## 2. Optimization benchmark — basic vs optimized

**Purpose:** Section 3.3.2 (c) requires measured improvement from at least one optimization. Our optimization is hash-based prefix lookup in the count step.

### 2a. Light run (recommended first)

**Time:** ~5s · **RAM:** low · **Risk:** none

1. Open [tests/bench_optimization.jl](../tests/bench_optimization.jl) in your editor.
2. Comment out the three benchmark-dataset lines in `main()`:
   ```julia
   run_case("Example 1 (toy)",  joinpath(toy,   "example1.txt"),  2)
   run_case("Example 2 (toy)",  joinpath(toy,   "example2.txt"),  2)
   # run_case("Chess",            joinpath(bench, "chess.txt"),     2500)
   # run_case("Mushroom",         joinpath(bench, "mushrooms.txt"), 4000)
   # run_case("Retail",           joinpath(bench, "retail.txt"),    1000)
   ```
3. Run:
   ```bash
   julia --project tests/bench_optimization.jl
   ```

**Expected output per dataset:**
```
=== Example 1 (toy)  (|D|=5, minsup=2) ===
  basic    : 0.12 ms   | 0.01 MiB allocated
  optimized: 0.05 ms   | 0.00 MiB allocated
  → speedup: 2.40×   alloc reduction: 2.50×
```

Confirm `speedup > 1` and `alloc reduction > 1`. Save the output to a file:

```bash
julia --project tests/bench_optimization.jl 2>&1 | tee docs/results_optimization_toy.txt
```

### 2b. Full run (benchmark datasets)

⚠ **Time:** ~2–3 minutes · **RAM:** several hundred MB at peak · **Risk:** crash if you're low on memory. Close your browser first.

1. Un-comment the three benchmark lines you commented out in 2a (or `git checkout tests/bench_optimization.jl`).
2. Run:
   ```bash
   julia --project tests/bench_optimization.jl 2>&1 | tee docs/results_optimization_full.txt
   ```
3. If you see the system start to swap (fan spinning hard, cursor lagging), press `Ctrl+C`.

**What this gives you for the report:**
- **Section 3.3.2 (c):** cite speedup and alloc-reduction factors. Put them in a small table in Chapter 3.
- **Chapter 4 experiment (d) Peak memory:** the `MiB allocated` columns are your peak-memory numbers per variant per dataset.

---

## 3. Chapter 4 experiments (mandatory, brief 3.4.2)

Brief 3.4.2 requires **six experiments**. Steps 3.a–3.f below map one-to-one. Outputs go into `docs/results_chapter4/` (created as we go).

```bash
mkdir -p docs/results_chapter4
```

### 3.a. Correctness (Experiment a)

**Goal:** For each of the 4 benchmark datasets, compare itemset count + supports to the SPMF reference; report match percentage.

**Status:** **script does not exist yet.** You need an `scripts/experiment_a_correctness.jl` that:
1. For each dataset (chess, mushroom, retail, T10I4D100K), reads the transaction file and a pre-computed SPMF reference output.
2. Runs `apriori_tid` at the same minsup SPMF was run at.
3. Reports `matched / total` and lists any itemsets that differ (there should be none).

**Before you can run this:** you must obtain SPMF reference outputs. Two options:

- **(Easier)** Download SPMF jar from <https://www.philippe-fournier-viger.com/spmf/> and run `java -jar spmf.jar run AprioriTID <input> <output> <minsup_relative>` on each dataset. Place outputs in `data/benchmark/spmf_reference/{chess,mushrooms,retail,T10I4D100K}_msX.txt`.
- **(Harder)** Use the closed-form check from step 1 as the only correctness evidence and argue in the report that the toy datasets cover all structural cases.

**Time:** minutes (SPMF runs) + seconds (Julia comparison).

**What this gives you for the report:** a table in Chapter 4 with columns `[Dataset, minsup, #itemsets (ours), #itemsets (SPMF), match %]`.

### 3.b. Runtime vs minsup (Experiment b)

**Goal:** For each benchmark dataset, plot elapsed time (ms) against minsup for 5–7 minsup values.

**Status:** **script does not exist yet.** You need `scripts/experiment_b_runtime.jl` that:
1. For each dataset, iterate over 5–7 minsup values (high → low).
2. For each `(dataset, minsup)`, run `apriori_tid` **twice** — first untimed (JIT warm-up), then `@elapsed` for the real measurement.
3. Write `docs/results_chapter4/runtime_vs_minsup.csv` with columns `dataset,minsup,elapsed_ms,n_itemsets`.

**Suggested minsup sweeps** (adjust after first run if too slow or too trivial):

| Dataset      | minsup values (absolute counts) |
|--------------|---------------------------------|
| Chess (3196 trans) | 3000, 2800, 2500, 2200, 2000, 1800, 1600 |
| Mushroom (8124)    | 6000, 5000, 4000, 3500, 3000, 2500, 2000 |
| Retail (88162)     | 2000, 1500, 1200, 1000, 800, 600, 500    |
| T10I4D100K (10^5)  | 2000, 1500, 1200, 1000, 800, 600, 500    |

⚠ **The lowest minsup per dataset is the risky one.** Start the sweep from the highest minsup and let it run downward. If you see a single run take >2 minutes or RAM climb dangerously, kill it and raise that minsup.

**Time:** chess and T10I4D100K dominate — budget 5–15 minutes total for all 4 datasets. **RAM risk medium.**

**What this gives you for the report:** one line chart per dataset (or one chart with 4 lines), x-axis = minsup, y-axis = elapsed ms. Also feeds 3.c below (same runs).

### 3.c. #itemsets vs minsup (Experiment c)

**Goal:** Same minsup sweep as 3.b but plot count of frequent itemsets.

**Status:** **reuses data from 3.b.** The `n_itemsets` column of `runtime_vs_minsup.csv` is your y-axis. No additional runs needed.

**What this gives you for the report:** one line chart per dataset showing how the output explodes as minsup drops. Comment on which datasets are "dense" (itemset count explodes sharply — chess, mushroom) vs "sparse" (retail, T10I4D100K grow more gradually).

### 3.d. Peak memory (Experiment d)

**Goal:** For each dataset at a medium minsup, measure peak RAM for basic vs optimized variant.

**Status:** **partially covered by step 2b above** — the `MiB allocated` column is peak allocation per run. For a more rigorous "peak RSS" (actual OS memory), run each variant in its own Julia process and read `/proc/self/status` or use `GC.gc(); Base.summarysize(...)`. For this project, `@allocated` is sufficient.

If step 2b is already done and saved, you have this experiment's data. Otherwise, run it (see step 2b).

**What this gives you for the report:** a bar chart comparing basic vs optimized MiB per dataset, plus commentary on why the optimization reduces allocations (fewer candidate scans per transaction).

### 3.e. Scalability (Experiment e)

**Goal:** Pick one dataset (Retail recommended — large, sparse, quick), run at 10/25/50/75/100% of its transactions at a fixed minsup, plot runtime vs |D|.

**Status:** **script does not exist yet.** You need `scripts/experiment_e_scalability.jl` that:
1. `transactions = read_spmf("data/benchmark/retail.txt")`
2. For each fraction `f` in `[0.10, 0.25, 0.50, 0.75, 1.00]`:
   - `subset = transactions[1:round(Int, f * length(transactions))]`
   - Warm up, then `@elapsed apriori_tid(subset, minsup_scaled)`. **Scale minsup with f** so the ratio `minsup / |D|` stays constant — otherwise you're changing two variables at once.
3. Write `docs/results_chapter4/scalability_retail.csv` with `[fraction, n_trans, minsup, elapsed_ms, n_itemsets]`.

**Time:** ~30s. **RAM:** low.

**What this gives you for the report:** line chart x=|D|, y=elapsed ms. Comment on whether growth is linear (expected) or super-linear (problem).

### 3.f. Transaction length impact (Experiment f)

**Goal:** Generate synthetic datasets with increasing average transaction width `w`, run at fixed minsup, show how runtime/memory scale.

**Status:** **script does not exist yet.** You need `scripts/experiment_f_width.jl` that:
1. Uses a **fixed random seed** (required by brief section 4.1): `using Random; rng = MersenneTwister(42)`.
2. For each `w` in `[5, 10, 15, 20, 25, 30]`:
   - Generate 5000 transactions, each of length `w`, drawn uniformly from a 50-item universe.
   - Run `apriori_tid` at e.g. `minsup = 500` (10% of |D|).
3. Write `docs/results_chapter4/width_impact.csv` with `[w, elapsed_ms, n_itemsets, peak_mib]`.

⚠ **Risky.** As `w` grows, `|C̄_2|` grows quadratically (see Chapter 2, Example 2). **Start small.** If `w=30` takes more than 2 minutes or balloons memory, stop the sweep there and report the trend up to where you stopped.

**What this gives you for the report:** ties directly to the theoretical discussion in Chapter 1 (space complexity of `C̄_2`) and the Example 2 warning in Chapter 2 — your experiment empirically confirms the theory.

---

## 4. Generate charts for the report

All CSVs from section 3 live under `docs/results_chapter4/`. Chart them in the existing [notebooks/demo.ipynb](../notebooks/demo.ipynb) using Plots.jl. Each experiment becomes one figure in Chapter 4.

**Chart checklist (one per experiment):**
- [ ] `fig:exp-a-correctness` — table, not chart
- [ ] `fig:exp-b-runtime` — line chart, 4 datasets
- [ ] `fig:exp-c-itemset-count` — line chart, 4 datasets
- [ ] `fig:exp-d-memory` — bar chart, basic vs optimized
- [ ] `fig:exp-e-scalability` — line chart, Retail subsets
- [ ] `fig:exp-f-width` — line chart, synthetic data

**Export each chart as PDF** (not PNG — vector graphics look sharper in LaTeX):
```julia
savefig(p, joinpath(@__DIR__, "..", "report", "Figures", "exp_b_runtime.pdf"))
```

Then in the LaTeX:
```latex
\begin{figure}[htbp]
    \centering
    \includegraphics[width=0.9\textwidth]{Figures/exp_b_runtime.pdf}
    \caption{Thời gian chạy theo \textit{minsup} trên bốn tập dữ liệu benchmark.}
    \label{fig:exp-b-runtime}
\end{figure}
```

---

## 5. Writing Chapter 4 (report prose)

Brief 3.4.3 says **for every experiment** you must:
1. **Giải thích kết quả** dựa trên lý thuyết Chapter 1 (e.g., "thời gian tăng theo $|\overline{C}_k|$, phù hợp với công thức ở mục 1.x").
2. **Điểm mạnh/yếu** của cài đặt của bạn vs SPMF.
3. **≥2 hướng tối ưu** khả thi tiếp theo (e.g., bitset tidset, FP-Growth conversion, parallel candidate counting).

Draft these paragraphs **while the numbers are fresh** — don't wait until all experiments are done. For each experiment, write the analysis paragraph the same day you run it.

---

## 6. Cross-cutting safety tips

- **Always warm up before timing.** Julia's JIT compiles on first call. The second call is the real measurement. All scripts above already do this — follow the pattern if you write new ones.
- **Fix the random seed** in any script that uses randomness. Brief 4.1 requires reproducibility.
- **Never commit `docs/results_chapter4/` to git** until you're confident the numbers are final — or version them deliberately. Add to `.gitignore` if unsure.
- **Keep a log.** Every time you run an experiment, append a line to `docs/experiment_log.md` with the date, command, dataset, and headline result. When you go to write Chapter 4 two weeks later, you'll thank yourself.
- **If a run crashes your machine:** raise the minsup, shrink the dataset, or skip that specific `(dataset, minsup)` cell and note the omission in the report. A reported-but-incomplete experiment is better than a crashed machine.

---

## 7. Mapping experiments to report sections

| Script / command                           | Feeds brief section | Report location                              |
|--------------------------------------------|---------------------|----------------------------------------------|
| `tests/runtests.jl`                        | 3.3.2 (a), (b)      | Chapter 3 (Cài đặt), short listing           |
| `tests/bench_optimization.jl`              | 3.3.2 (c)           | Chapter 3, small table                       |
| Experiment a (correctness vs SPMF)         | 3.4.2 (a)           | Chapter 4, Table `tab:exp-a`                 |
| Experiment b (runtime vs minsup)           | 3.4.2 (b)           | Chapter 4, Figure `fig:exp-b-runtime`        |
| Experiment c (#itemsets vs minsup)         | 3.4.2 (c)           | Chapter 4, Figure `fig:exp-c-itemset-count`  |
| Experiment d (peak memory)                 | 3.4.2 (d)           | Chapter 4, Figure `fig:exp-d-memory`         |
| Experiment e (scalability)                 | 3.4.2 (e)           | Chapter 4, Figure `fig:exp-e-scalability`    |
| Experiment f (transaction width)           | 3.4.2 (f)           | Chapter 4, Figure `fig:exp-f-width`          |

---

## 8. Status at time of writing

**Ready now:**
- Step 1 (runtests.jl) — ✓ tested, 30/30 passing
- Step 2a / 2b (bench_optimization.jl) — ✓ script exists, not yet executed by you

**To build before Chapter 4:**
- `scripts/experiment_a_correctness.jl` (needs SPMF reference outputs for benchmarks)
- `scripts/experiment_b_runtime.jl` (feeds both 3.b and 3.c)
- `scripts/experiment_e_scalability.jl`
- `scripts/experiment_f_width.jl`
- Chart-generation cells in `notebooks/demo.ipynb`

Ask Claude to scaffold any of these when you're ready to run them.
