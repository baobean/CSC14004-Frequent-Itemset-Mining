include(joinpath(@__DIR__, "market_basket.jl"))

function main()
    minsup  = length(ARGS) >= 1 ? parse(Int, ARGS[1])     : 500
    minconf = length(ARGS) >= 2 ? parse(Float64, ARGS[2]) : 0.30

    data_path = joinpath(@__DIR__, "..", "data", "benchmark", "retail.txt")
    out_dir   = joinpath(@__DIR__, "..", "experiment_results")
    isdir(out_dir) || mkpath(out_dir)
    out_path = joinpath(out_dir, "retail_rules.csv")

    println(stderr, "Reading $data_path")
    transactions = read_spmf(data_path)
    n_trans = length(transactions)
    println(stderr, "|D| = $n_trans transactions")

    println(stderr, "Running AprioriTID with minsup=$minsup ...")
    t_fim = @elapsed freq_itemsets = apriori_tid(transactions, minsup)
    println(stderr, "  -> $(length(freq_itemsets)) frequent itemsets in $(round(t_fim * 1000, digits=1)) ms")

    n_multi = count(x -> length(x[1]) >= 2, freq_itemsets)
    println(stderr, "  -> $n_multi itemsets with |F| >= 2 (used for rule mining)")

    println(stderr, "Generating rules with minconf=$minconf ...")
    t_rule = @elapsed rules = generate_rules(freq_itemsets, n_trans, minconf)
    println(stderr, "  -> $(length(rules)) rules in $(round(t_rule * 1000, digits=1)) ms")

    write_rules_csv(out_path, rules)
    println(stderr, "Rules written to $out_path")

    # Print short textual summary to stdout
    println("# Retail Market Basket Analysis")
    println("|D| = $n_trans, minsup (abs) = $minsup, minconf = $minconf")
    println("Frequent itemsets: $(length(freq_itemsets)) total, $n_multi with k>=2")
    println("Rules generated  : $(length(rules))")
    println()

    println("## Top 10 rules by confidence")
    for r in top_rules_by(rules, :confidence; n=10)
        println("  {", join(r.antecedent, ","), "} => {", join(r.consequent, ","), "}  ",
                "sup=", round(r.support, digits=4),
                "  conf=", round(r.confidence, digits=3),
                "  lift=", round(r.lift, digits=2))
    end
    println()

    println("## Top 10 rules by lift")
    for r in top_rules_by(rules, :lift; n=10)
        println("  {", join(r.antecedent, ","), "} => {", join(r.consequent, ","), "}  ",
                "sup=", round(r.support, digits=4),
                "  conf=", round(r.confidence, digits=3),
                "  lift=", round(r.lift, digits=2))
    end
end

main()
