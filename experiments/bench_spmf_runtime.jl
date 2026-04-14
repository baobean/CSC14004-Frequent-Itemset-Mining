include(joinpath(@__DIR__, "common.jl"))

function parse_spmf_stats(stdout_text::String)
    m_time = match(r"Total time\s*~?\s*(\d+)\s*ms", stdout_text)
    m_count = match(r"Frequent itemsets count\s*:\s*(\d+)", stdout_text)
    elapsed_ms = m_time === nothing ? -1 : parse(Int, m_time.captures[1])
    n_itemsets = m_count === nothing ? -1 : parse(Int, m_count.captures[1])
    return elapsed_ms, n_itemsets
end

function main()
    if length(ARGS) < 4
        println(stderr, "Usage: julia --project experiments/bench_spmf_runtime.jl <dataset> <spmf.jar> <output_csv> <minsup1> [<minsup2> ...]")
        exit(1)
    end
    dataset_path = ARGS[1]
    spmf_jar     = ARGS[2]
    output_csv   = ARGS[3]
    minsup_list  = [parse(Int, s) for s in ARGS[4:end]]

    isfile(dataset_path) || (println(stderr, "Dataset not found: $dataset_path"); exit(1))
    isfile(spmf_jar)     || (println(stderr, "SPMF jar not found: $spmf_jar"); exit(1))

    n_trans = length(read_spmf(dataset_path))
    println("[spmf] dataset=$(basename(dataset_path))  |D|=$n_trans  sweeping $(length(minsup_list)) value(s)")

    tmp_out = tempname() * ".txt"

    for minsup in minsup_list
        rel = minsup / n_trans
        rel_str = string(round(rel, digits=6))

        cmd = `java -jar $spmf_jar run Apriori_TID $dataset_path $tmp_out $rel_str`
        buf = IOBuffer()
        try
            run(pipeline(cmd, stdout=buf, stderr=buf))
        catch err
            println(stderr, "SPMF failed at minsup=$minsup (rel=$rel_str): $err")
            continue
        end
        stdout_text = String(take!(buf))
        elapsed_ms, n_itemsets = parse_spmf_stats(stdout_text)

        append_csv(output_csv,
            ["dataset", "minsup", "n_trans", "elapsed_ms", "n_itemsets", "source"],
            [basename(dataset_path), minsup, n_trans, elapsed_ms, n_itemsets, "SPMF"])
        println("  minsup=$minsup (rel=$rel_str)  $elapsed_ms ms  $n_itemsets itemsets")
    end

    isfile(tmp_out) && rm(tmp_out)
    println("  appended $(length(minsup_list)) row(s) to $output_csv")
end

main()
