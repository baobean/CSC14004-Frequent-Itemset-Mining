using Test

if !@isdefined(apriori_tid)
    include(joinpath(@__DIR__, "..", "src", "structures.jl"))
    include(joinpath(@__DIR__, "..", "src", "utils.jl"))
    include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_gen.jl"))
    include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_tid.jl"))
end

"""
Compare algorithm results against an SPMF reference and return match percentage
(fraction of reference itemsets — with matching support — that are reproduced).
"""
function match_percentage(results::Vector{Tuple{Vector{Int}, Int}},
                          reference::Vector{Tuple{Vector{Int}, Int}})
    ref_set = Set([(sort(is), sup) for (is, sup) in reference])
    res_set = Set([(sort(is), sup) for (is, sup) in results])
    isempty(ref_set) && return (isempty(res_set) ? 1.0 : 0.0), 0, 0
    matched = length(intersect(ref_set, res_set))
    return matched / length(ref_set), matched, length(ref_set)
end

"""
Generate example2 reference from closed-form spec: every non-empty subset S of
{1..7} with |S ∩ {4,5,6,7}| ≤ 2 is frequent (minsup=2), with support = 4 - |S ∩ {4,5,6,7}|.
"""
function example2_reference()
    ref = Tuple{Vector{Int}, Int}[]
    tail = Set([4, 5, 6, 7])
    for mask in 1:(2^7 - 1)
        itemset = Int[]
        for i in 1:7
            if (mask >> (i - 1)) & 1 == 1
                push!(itemset, i)
            end
        end
        tail_count = count(x -> x in tail, itemset)
        if tail_count <= 2
            push!(ref, (itemset, 4 - tail_count))
        end
    end
    return ref
end

@testset "SPMF Reference Comparison" begin
    ref_dir = joinpath(@__DIR__, "..", "data", "toy", "spmf_reference")
    toy_dir = joinpath(@__DIR__, "..", "data", "toy")

    cases = [
        ("example1.txt",          2, "Example 1"),
        ("test_single_item.txt",  2, "Single item"),
        ("test_empty_result.txt", 3, "Empty result"),
        ("test_all_frequent.txt", 2, "All frequent"),
    ]

    total_matched = 0
    total_ref = 0

    for (fname, minsup, label) in cases
        transactions = read_spmf(joinpath(toy_dir, fname))
        reference = read_spmf_output(joinpath(ref_dir, fname))
        results = apriori_tid(transactions, minsup)
        pct, matched, nref = match_percentage(results, reference)

        println("  $label (minsup=$minsup): $matched/$nref matched ($(round(pct*100, digits=1))%)")
        @test pct == 1.0
        @test length(results) == length(reference)
        total_matched += matched
        total_ref += nref
    end

    # Example 2: reference generated from closed-form specification
    @testset "Example 2 (minsup=2, closed-form reference)" begin
        transactions = read_spmf(joinpath(toy_dir, "example2.txt"))
        reference = example2_reference()
        results = apriori_tid(transactions, 2)
        pct, matched, nref = match_percentage(results, reference)

        println("  Example 2 (minsup=2): $matched/$nref matched ($(round(pct*100, digits=1))%)")
        @test pct == 1.0
        @test length(results) == 87
        total_matched += matched
        total_ref += nref
    end

    overall = total_matched / total_ref
    println("  ── Overall match vs SPMF reference: $total_matched/$total_ref = $(round(overall*100, digits=2))%")
    @test overall == 1.0
end
