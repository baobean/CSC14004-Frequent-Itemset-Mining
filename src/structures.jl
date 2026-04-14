const Itemset = Vector{Int}

mutable struct Candidate
    itemset::Vector{Int}
    count::Int
end

struct CBarEntry
    tid::Int
    itemsets::Vector{Vector{Int}}
end
