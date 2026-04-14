include(joinpath(@__DIR__, "common.jl"))

const FRACTIONS = [0.10, 0.25, 0.50, 0.75, 1.00]

function main()
    if length(ARGS) != 3
        println(stderr, "Usage: julia --project experiments/experiment_scalability.jl <dataset> <rel_minsup_pct> <output_csv>")
        exit(1)
    end
    dataset_path = ARGS[1]
    rel_pct      = parse(Float64, ARGS[2])
    output_csv   = ARGS[3]

    isfile(dataset_path) || (println(stderr, "Dataset not found: $dataset_path"); exit(1))

    transactions = read_spmf(dataset_path)
    println("[scalability] dataset=$(basename(dataset_path))  |D|=$(length(transactions))  rel_minsup=$rel_pct%")

    for frac in FRACTIONS
        n_trans = max(1, round(Int, frac * length(transactions)))
        subset  = transactions[1:n_trans]
        abs_minsup = max(1, round(Int, rel_pct / 100.0 * n_trans))

        elapsed, allocs, n = warm_and_measure(subset, abs_minsup)
        append_csv(output_csv,
            ["dataset", "fraction", "n_trans", "minsup", "elapsed_ms", "alloc_mib", "n_itemsets"],
            [basename(dataset_path), frac, n_trans, abs_minsup,
             round(elapsed * 1000, digits=2),
             round(allocs / 1024^2, digits=3), n])
        println("  frac=$frac  n_trans=$n_trans  minsup=$abs_minsup  $(round(elapsed*1000, digits=2)) ms  $n itemsets")
    end

    println("  appended $(length(FRACTIONS)) row(s) to $output_csv")
end

main()
