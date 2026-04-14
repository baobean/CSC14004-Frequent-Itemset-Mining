include(joinpath(@__DIR__, "common.jl"))

function main()
    if length(ARGS) != 4
        println(stderr, "Usage: julia --project experiments/experiment_correctness.jl <dataset> <spmf_ref> <abs_minsup> <output_csv>")
        exit(1)
    end
    dataset_path = ARGS[1]
    ref_path     = ARGS[2]
    minsup       = parse(Int, ARGS[3])
    output_csv   = ARGS[4]

    isfile(dataset_path) || (println(stderr, "Dataset not found: $dataset_path"); exit(1))
    isfile(ref_path)     || (println(stderr, "SPMF reference not found: $ref_path"); exit(1))

    transactions = read_spmf(dataset_path)
    reference    = read_spmf_output(ref_path)

    println("[correctness] dataset=$(basename(dataset_path))  |D|=$(length(transactions))  minsup=$minsup")

    results = apriori_tid(transactions, minsup)

    ref_set = Set([(sort(is), sup) for (is, sup) in reference])
    res_set = Set([(sort(is), sup) for (is, sup) in results])
    matched  = length(intersect(ref_set, res_set))
    missing_ = length(setdiff(ref_set, res_set))
    extra_   = length(setdiff(res_set, ref_set))
    match_pct = isempty(ref_set) ? (isempty(res_set) ? 100.0 : 0.0) :
                100.0 * matched / length(ref_set)

    append_csv(output_csv,
        ["dataset", "minsup", "n_trans", "n_ours", "n_spmf", "matched", "missing", "extra", "match_pct"],
        [basename(dataset_path), minsup, length(transactions),
         length(results), length(reference), matched, missing_, extra_,
         round(match_pct, digits=2)])

    println("  ours=$(length(results))  spmf=$(length(reference))  matched=$matched  missing=$missing_  extra=$extra_  → $(round(match_pct, digits=2))%")
    println("  appended to $output_csv")
end

main()
