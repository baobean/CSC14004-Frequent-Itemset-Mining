include(joinpath(@__DIR__, "common.jl"))

function main()
    if length(ARGS) != 3
        println(stderr, "Usage: julia --project experiments/experiment_memory.jl <dataset> <abs_minsup> <output_csv>")
        exit(1)
    end
    dataset_path = ARGS[1]
    minsup       = parse(Int, ARGS[2])
    output_csv   = ARGS[3]

    isfile(dataset_path) || (println(stderr, "Dataset not found: $dataset_path"); exit(1))

    transactions = read_spmf(dataset_path)
    println("[memory] dataset=$(basename(dataset_path))  |D|=$(length(transactions))  minsup=$minsup")

    #for variant in (:basic, :optimized)
    for variant in (:optimized, :basic)
        opt = variant == :optimized
        elapsed, allocs, n = warm_and_measure(transactions, minsup; optimized=opt)
        append_csv(output_csv,
            ["dataset", "variant", "minsup", "n_trans", "elapsed_ms", "alloc_mib", "n_itemsets"],
            [basename(dataset_path), String(variant), minsup, length(transactions),
             round(elapsed * 1000, digits=2),
             round(allocs / 1024^2, digits=3), n])
        println("  $variant  $(round(elapsed*1000, digits=2)) ms  $(round(allocs/1024^2, digits=3)) MiB  $n itemsets")
    end

    println("  appended 2 row(s) to $output_csv")
end

main()
