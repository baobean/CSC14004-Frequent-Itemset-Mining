if !@isdefined(apriori_tid)
    const _SRC = joinpath(@__DIR__, "..", "src")
    include(joinpath(_SRC, "structures.jl"))
    include(joinpath(_SRC, "utils.jl"))
    include(joinpath(_SRC, "algorithm", "apriori_gen.jl"))
    include(joinpath(_SRC, "algorithm", "apriori_tid.jl"))
end

"""
    append_csv(path, header, row)

Append a row to `path`. If the file does not yet exist, write `header` first.
Values are joined with commas (no quoting — keep inputs simple).
"""
function append_csv(path::AbstractString, header::Vector{String}, row::Vector)
    mkpath(dirname(path))
    exists = isfile(path) && filesize(path) > 0
    open(path, "a") do io
        if !exists
            println(io, join(header, ","))
        end
        println(io, join(row, ","))
    end
end

"""
    warm_and_measure(transactions, minsup; optimized=true)
        -> (elapsed_sec, allocs_bytes, n_itemsets)

Run `apriori_tid` once as a JIT warm-up, force a GC pass, then measure a fresh
run for both elapsed time and allocated bytes. The final `@elapsed` is an
independent third call so the timing is not contaminated by `@allocated`'s
bookkeeping overhead.
"""
function warm_and_measure(transactions::Vector{Vector{Int}}, minsup::Int; optimized::Bool=true)
    apriori_tid(transactions, minsup; optimized=optimized)  # warm-up
    GC.gc()
    local results
    allocs = @allocated results = apriori_tid(transactions, minsup; optimized=optimized)
    elapsed = @elapsed apriori_tid(transactions, minsup; optimized=optimized)
    return elapsed, allocs, length(results)
end
