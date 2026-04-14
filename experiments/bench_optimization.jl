include(joinpath(@__DIR__, "common.jl"))

function run_case(label, fpath, minsup)
    if !isfile(fpath)
        @warn "$label: $fpath not found, skipping"
        return
    end
    transactions = read_spmf(fpath)
    println("\n=== $label  (|D|=$(length(transactions)), minsup=$minsup) ===")

    t_basic, a_basic, n_basic = warm_and_measure(transactions, minsup; optimized=false)
    t_opt,   a_opt,   n_opt   = warm_and_measure(transactions, minsup; optimized=true)

    @assert n_basic == n_opt "basic and optimized disagree on itemset count"

    speedup     = t_basic / t_opt
    alloc_ratio = a_basic / a_opt

    println("  basic    : $(round(t_basic*1000, digits=2)) ms   | $(round(a_basic/1024^2, digits=2)) MiB allocated")
    println("  optimized: $(round(t_opt*1000,   digits=2)) ms   | $(round(a_opt/1024^2,   digits=2)) MiB allocated")
    println("  → speedup: $(round(speedup, digits=2))×   alloc reduction: $(round(alloc_ratio, digits=2))×")
    println("  (found $n_opt frequent itemsets)")
end

function main()
    println("AprioriTID optimization benchmark (TOY datasets)")
    println("Basic vs hash-based candidate lookup")

    toy = joinpath(@__DIR__, "..", "data", "toy")

    run_case("Example 1 (Chương 2 Ví dụ 1)", joinpath(toy, "example1.txt"),          2)
    run_case("Example 2 (Chương 2 Ví dụ 2)", joinpath(toy, "example2.txt"),          2)
    run_case("Single item",                   joinpath(toy, "test_single_item.txt"),  2)
    run_case("Empty result",                  joinpath(toy, "test_empty_result.txt"), 3)
    run_case("All frequent",                  joinpath(toy, "test_all_frequent.txt"), 2)
end

main()
