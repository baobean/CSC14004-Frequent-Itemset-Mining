include(joinpath(@__DIR__, "common.jl"))

using Random

const DEFAULT_WIDTHS = [5, 8, 12, 20]
const N_TRANS        = 2000
const N_ITEMS        = 40
const REL_MINSUP     = 0.10   # 10% of |D|
const SEED_BASE      = 42

function synth_dataset(w::Int, rng::AbstractRNG)
    [sort!(randperm(rng, N_ITEMS)[1:w]) for _ in 1:N_TRANS]
end

function main()
    if length(ARGS) < 1
        println(stderr, "Usage: julia --project experiments/experiment_width.jl <output_csv> [w1,w2,...]")
        exit(1)
    end
    output_csv = ARGS[1]
    widths = length(ARGS) >= 2 ? [parse(Int, s) for s in split(ARGS[2], ",")] : DEFAULT_WIDTHS

    minsup = round(Int, REL_MINSUP * N_TRANS)
    println("[width] n_trans=$N_TRANS  n_items=$N_ITEMS  abs_minsup=$minsup  seed_base=$SEED_BASE")
    println("        widths=$(join(widths, ','))")

    for w in widths
        if w > N_ITEMS
            @warn "Skipping w=$w (greater than n_items=$N_ITEMS)"
            continue
        end
        rng = MersenneTwister(SEED_BASE + w)
        transactions = synth_dataset(w, rng)

        elapsed, allocs, n = warm_and_measure(transactions, minsup)
        append_csv(output_csv,
            ["w", "n_trans", "n_items", "minsup", "elapsed_ms", "alloc_mib", "n_itemsets"],
            [w, N_TRANS, N_ITEMS, minsup,
             round(elapsed * 1000, digits=2),
             round(allocs / 1024^2, digits=3), n])
        println("  w=$w  $(round(elapsed*1000, digits=2)) ms  $(round(allocs/1024^2, digits=3)) MiB  $n itemsets")
    end

    println("  appended $(length(widths)) row(s) to $output_csv")
end

main()
