# I/O utilities for SPMF format and CLI argument parsing
# Requires: structures.jl to be included first

"""
    read_spmf(filepath::String) -> Vector{Vector{Int}}

Read a transaction database in SPMF format.
Each line contains space-separated item integers. Each line is one transaction.
Items within each transaction are sorted in ascending order.
Empty lines are skipped.
"""
function read_spmf(filepath::String)::Vector{Vector{Int}}
    transactions = Vector{Int}[]
    open(filepath, "r") do f
        for line in eachline(f)
            stripped = strip(line)
            isempty(stripped) && continue
            items = sort!(parse.(Int, split(stripped)))
            push!(transactions, items)
        end
    end
    return transactions
end

"""
    write_spmf(filepath::String, results::Vector{Tuple{Vector{Int}, Int}})

Write frequent itemsets in SPMF output format.
Each line: space-separated items followed by " #SUP: count".
Output is sorted by itemset length, then lexicographically.
"""
function write_spmf(filepath::String, results::Vector{Tuple{Vector{Int}, Int}})
    sorted_results = sort(results, by = x -> (length(x[1]), x[1]))
    open(filepath, "w") do f
        for (itemset, support) in sorted_results
            println(f, join(itemset, " "), " #SUP: ", support)
        end
    end
end

"""
    write_spmf_stdout(results::Vector{Tuple{Vector{Int}, Int}})

Write frequent itemsets to stdout in SPMF output format.
"""
function write_spmf_stdout(results::Vector{Tuple{Vector{Int}, Int}})
    sorted_results = sort(results, by = x -> (length(x[1]), x[1]))
    for (itemset, support) in sorted_results
        println(join(itemset, " "), " #SUP: ", support)
    end
end

"""
    read_spmf_output(filepath::String) -> Vector{Tuple{Vector{Int}, Int}}

Read SPMF output format (itemset #SUP: count) for comparison/testing.
"""
function read_spmf_output(filepath::String)::Vector{Tuple{Vector{Int}, Int}}
    results = Tuple{Vector{Int}, Int}[]
    open(filepath, "r") do f
        for line in eachline(f)
            stripped = strip(line)
            isempty(stripped) && continue
            parts = split(stripped, " #SUP: ")
            length(parts) == 2 || continue
            itemset = sort!(parse.(Int, split(parts[1])))
            support = parse(Int, parts[2])
            push!(results, (itemset, support))
        end
    end
    return results
end
