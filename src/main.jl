include(joinpath(@__DIR__, "structures.jl"))
include(joinpath(@__DIR__, "utils.jl"))
include(joinpath(@__DIR__, "algorithm", "apriori_gen.jl"))
include(joinpath(@__DIR__, "algorithm", "apriori_tid.jl"))

function main()
    if length(ARGS) < 2
        println(stderr, "Usage: julia --project src/main.jl <minsup> <filepath> [output_filepath]")
        println(stderr, "  minsup:          Minimum absolute support count (integer)")
        println(stderr, "  filepath:        Path to input file in SPMF format")
        println(stderr, "  output_filepath: (Optional) Path to write output in SPMF format")
        exit(1)
    end

    minsup = parse(Int, ARGS[1])
    filepath = ARGS[2]
    output_filepath = length(ARGS) >= 3 ? ARGS[3] : nothing

    if minsup < 1
        println(stderr, "Error: minsup must be >= 1")
        exit(1)
    end

    if !isfile(filepath)
        println(stderr, "Error: file not found: $filepath")
        exit(1)
    end

    # Read transactions
    transactions = read_spmf(filepath)
    println(stderr, "Read $(length(transactions)) transactions from $filepath")

    # Run AprioriTID
    elapsed = @elapsed begin
        results = apriori_tid(transactions, minsup)
    end

    println(stderr, "Found $(length(results)) frequent itemsets in $(round(elapsed * 1000, digits=1)) ms")

    # Output results
    if output_filepath !== nothing
        write_spmf(output_filepath, results)
        println(stderr, "Results written to $output_filepath")
    else
        write_spmf_stdout(results)
    end
end

main()
