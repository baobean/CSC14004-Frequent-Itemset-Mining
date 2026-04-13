# Data structures for AprioriTID algorithm
# All struct fields use concrete types for Julia compiler specialization

"""Alias for itemset representation — always a sorted Vector{Int}."""
const Itemset = Vector{Int}

"""
Candidate itemset with its support count.
Mutable because count is incremented during the counting phase.
"""
mutable struct Candidate
    itemset::Vector{Int}
    count::Int
end

"""
Entry in C̄_k — the encoded transaction set.
Each entry stores a TID and the set of k-itemset candidates present in that transaction.
Transactions with no candidates are dropped entirely (transaction reduction).
"""
struct CBarEntry
    tid::Int
    itemsets::Vector{Vector{Int}}
end
