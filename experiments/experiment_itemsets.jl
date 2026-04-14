include(joinpath(@__DIR__, "common.jl"))

function main()
    if length(ARGS) < 3
        println(stderr, "Usage: julia --project experiments/experiment_itemsets.jl <dataset> <output_csv> <minsup1> [<minsup2> ...]")
        exit(1)
    end
    dataset_path = ARGS[1]
    output_csv   = ARGS[2]
    minsup_list  = [parse(Int, s) for s in ARGS[3:end]]

    isfile(dataset_path) || (println(stderr, "Dataset not found: $dataset_path"); exit(1))

    transactions = read_spmf(dataset_path)
    println("[itemsets] dataset=$(basename(dataset_path))  |D|=$(length(transactions))")

    for minsup in minsup_list
        results = apriori_tid(transactions, minsup)
        append_csv(output_csv,
            ["dataset", "minsup", "n_trans", "n_itemsets"],
            [basename(dataset_path), minsup, length(transactions), length(results)])
        println("  minsup=$minsup  → $(length(results)) itemsets")
    end

    println("  appended $(length(minsup_list)) row(s) to $output_csv")
end

main()
