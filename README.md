# CSC14004 - Frequent Itemset Mining: AprioriTID

Implementation of the AprioriTID algorithm in Julia 1.9 for the CSC14004 Data Mining course.

## Prerequisites

- **Julia >= 1.9** ([download](https://julialang.org/downloads/))
- IJulia kernel (for Jupyter notebooks)

## Setup

```bash
# Clone the repository
git clone <repo-url>
cd CSC14004-Frequent-Itemset-Mining

# Install Julia dependencies
julia --project -e 'using Pkg; Pkg.instantiate()'
```

## Project Structure

```
.
|-- Project.toml              # Julia dependencies
|-- src/
|   |-- main.jl               # CLI entry point
|   |-- structures.jl         # Data structures
|   |-- utils.jl              # SPMF I/O utilities
|   |-- algorithm/
|       |-- apriori_tid.jl    # Main AprioriTID algorithm
|       |-- apriori_gen.jl    # Candidate generation (join + prune)
|-- tests/
|   |-- runtests.jl           # Test entry point
|   |-- test_correctness.jl   # Correctness tests on toy datasets
|   |-- test_benchmark.jl     # Benchmark performance tests
|-- data/
|   |-- toy/                  # Small datasets for examples
|   |-- benchmark/            # Benchmark datasets (Chess, Mushroom, Retail, T10I4D100K)
|-- notebooks/
|   |-- demo.ipynb            # Experiments notebook (Chapter 4)
|-- report/
|   |-- report.tex            # LaTeX report source
|-- docs/                     # Generated charts (PDF)
```

## Usage

### Run the algorithm via CLI

```bash
# Basic usage: outputs to stdout
julia --project src/main.jl <minsup> <input_file>

# Example: find frequent itemsets with minimum support 2
julia --project src/main.jl 2 data/toy/example1.txt

# Save output to a file
julia --project src/main.jl 2 data/toy/example1.txt output.txt

# Run on benchmark dataset
julia --project src/main.jl 2500 data/benchmark/chess.txt results_chess.txt
```

**Arguments:**
- `minsup`: Minimum absolute support count (integer >= 1)
- `input_file`: Path to input file in SPMF format (one transaction per line, space-separated item integers)
- `output_file` (optional): Path to write results in SPMF output format

**Output format (SPMF):**
```
1 #SUP: 4
2 #SUP: 3
1 2 #SUP: 3
1 2 4 #SUP: 2
```

### Run tests

```bash
# Run full test suite (correctness + benchmark)
julia --project tests/runtests.jl

# Run only correctness tests
julia --project tests/test_correctness.jl

# Run only benchmark tests
julia --project tests/test_benchmark.jl
```

### Run experiments notebook

```bash
# Install IJulia if not already installed
julia --project -e 'using Pkg; Pkg.add("IJulia")'

# Start Jupyter
julia --project -e 'using IJulia; notebook(dir="notebooks")'
```

Then open `demo.ipynb` and run all cells (**Kernel > Restart & Run All**).

### Extracting charts to PDF for LaTeX

The notebook automatically saves all charts as PDF files in the `docs/` directory. To use them in the LaTeX report:

```latex
\usepackage{graphicx}

% Example: include a runtime chart
\begin{figure}[htbp]
    \centering
    \includegraphics[width=0.8\textwidth]{../docs/runtime_chess.pdf}
    \caption{Thoi gian chay theo minsup -- Chess}
    \label{fig:runtime-chess}
\end{figure}
```

Generated chart files:
- `docs/runtime_<dataset>.pdf` — Runtime vs minsup
- `docs/itemset_count_<dataset>.pdf` — Number of itemsets vs minsup
- `docs/memory_comparison.pdf` — Memory usage: basic vs optimized
- `docs/scalability_retail.pdf` — Scalability test on Retail
- `docs/transaction_length_effect.pdf` — Effect of transaction length
- `docs/optimization_comparison.pdf` — Runtime: basic vs optimized

## Input Format

SPMF transaction database format:
- One transaction per line
- Items are space-separated integers
- Example:
```
1 2 3 4
1 2
1 4 5
```

## Algorithm

AprioriTID (Agrawal & Srikant, 1994) is a variant of Apriori that avoids rescanning the original database after the first pass. Instead, it uses an encoded intermediate structure C_bar_k to track which candidates appear in each transaction. Transactions with no candidates are dropped (transaction reduction), making later passes faster.

### Optimization

The implementation includes a hash-based candidate lookup optimization. Instead of checking every candidate against every transaction, a dictionary maps prefix itemsets to candidate indices, reducing the per-transaction work from O(|C_k|) to O(matching candidates). This can be toggled via the `optimized` parameter.
