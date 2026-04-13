# Standalone benchmark: basic vs optimized support counting.
# Run with: julia --project tests/bench_optimization.jl
#
# Reports elapsed time and allocations for each variant so we can quantify the
# improvement of the hash-based prefix lookup over the naive full-candidate scan.

include(joinpath(@__DIR__, "..", "src", "structures.jl"))
include(joinpath(@__DIR__, "..", "src", "utils.jl"))
include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_gen.jl"))
include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_tid.jl"))

function bench_variant(transactions, minsup; optimized::Bool)
    # Warm-up to trigger JIT compilation
    apriori_tid(transactions, minsup; optimized=optimized)
    # Measure
    allocs = @allocated results = apriori_tid(transactions, minsup; optimized=optimized)
    elapsed = @elapsed apriori_tid(transactions, minsup; optimized=optimized)
    return elapsed, allocs, length(results)
end

function run_case(label, fpath, minsup)
    if !isfile(fpath)
        @warn "$label: $fpath not found, skipping"
        return
    end
    transactions = read_spmf(fpath)
    println("\n=== $label  (|D|=$(length(transactions)), minsup=$minsup) ===")

    t_basic, a_basic, n_basic = bench_variant(transactions, minsup; optimized=false)
    t_opt,   a_opt,   n_opt   = bench_variant(transactions, minsup; optimized=true)

    @assert n_basic == n_opt "basic and optimized disagree on itemset count"

    speedup = t_basic / t_opt
    alloc_ratio = a_basic / a_opt

    println("  basic    : $(round(t_basic*1000, digits=2)) ms   | $(round(a_basic/1024^2, digits=2)) MiB allocated")
    println("  optimized: $(round(t_opt*1000,   digits=2)) ms   | $(round(a_opt/1024^2,   digits=2)) MiB allocated")
    println("  → speedup: $(round(speedup, digits=2))×   alloc reduction: $(round(alloc_ratio, digits=2))×")
    println("  (found $n_opt frequent itemsets)")
end

function main()
    println("AprioriTID optimization benchmark: basic vs hash-based candidate lookup")

    toy   = joinpath(@__DIR__, "..", "data", "toy")
    bench = joinpath(@__DIR__, "..", "data", "benchmark")

    run_case("Example 1 (toy)",  joinpath(toy,   "example1.txt"),  2)
    run_case("Example 2 (toy)",  joinpath(toy,   "example2.txt"),  2)
    run_case("Chess",            joinpath(bench, "chess.txt"),     2500)
    run_case("Mushroom",         joinpath(bench, "mushrooms.txt"), 4000)
    run_case("Retail",           joinpath(bench, "retail.txt"),    1000)
end

main()
