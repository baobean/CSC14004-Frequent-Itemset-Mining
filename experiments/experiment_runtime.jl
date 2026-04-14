include(joinpath(@__DIR__, "common.jl"))

function main()
    if length(ARGS) < 3
        println(stderr, "Usage: julia --project experiments/experiment_runtime.jl <dataset> <output_csv> <minsup1> [<minsup2> ...]")
        exit(1)
    end
    dataset_path = ARGS[1]
    output_csv   = ARGS[2]
    minsup_list  = [parse(Int, s) for s in ARGS[3:end]]

    isfile(dataset_path) || (println(stderr, "Dataset not found: $dataset_path"); exit(1))

    transactions = read_spmf(dataset_path)
    println("[runtime] dataset=$(basename(dataset_path))  |D|=$(length(transactions))  sweeping $(length(minsup_list)) minsup value(s)")

    for minsup in minsup_list
        elapsed, allocs, n = warm_and_measure(transactions, minsup)
        append_csv(output_csv,
            ["dataset", "minsup", "n_trans", "elapsed_ms", "alloc_mib", "n_itemsets"],
            [basename(dataset_path), minsup, length(transactions),
             round(elapsed * 1000, digits=2),
             round(allocs / 1024^2, digits=3), n])
        println("  minsup=$minsup  $(round(elapsed*1000, digits=2)) ms  $(round(allocs/1024^2, digits=3)) MiB  $n itemsets")
    end

    println("  appended $(length(minsup_list)) row(s) to $output_csv")
end

main()
