using Test

if !@isdefined(apriori_tid)
    const _SRC = joinpath(@__DIR__, "..", "src")
    include(joinpath(_SRC, "structures.jl"))
    include(joinpath(_SRC, "utils.jl"))
    include(joinpath(_SRC, "algorithm", "apriori_gen.jl"))
    include(joinpath(_SRC, "algorithm", "apriori_tid.jl"))
end

function as_set(results::Vector{Tuple{Vector{Int}, Int}})
    Set([(sort(is), sup) for (is, sup) in results])
end

const TOY_CASES = [
    ("example1.txt",          2, "Example 1"),
    ("example2.txt",          2, "Example 2"),
    ("test_single_item.txt",  2, "Single item"),
    ("test_empty_result.txt", 3, "Empty result"),
    ("test_all_frequent.txt", 2, "All frequent"),
]

const TOY_DIR = joinpath(@__DIR__, "..", "data", "toy")
const REF_DIR = joinpath(TOY_DIR, "spmf_reference")

@testset "Correctness vs SPMF reference (5 toy datasets)" begin
    total_matched = 0
    total_ref = 0

    for (fname, minsup, label) in TOY_CASES
        @testset "$label (minsup=$minsup)" begin
            transactions = read_spmf(joinpath(TOY_DIR, fname))
            reference = read_spmf_output(joinpath(REF_DIR, fname))

            # Optimized variant must match the SPMF reference exactly.
            results_opt = apriori_tid(transactions, minsup; optimized=true)
            ref_set = as_set(reference)
            opt_set = as_set(results_opt)

            @test opt_set == ref_set
            @test length(results_opt) == length(reference)

            # Basic variant must agree with the optimized one.
            results_basic = apriori_tid(transactions, minsup; optimized=false)
            @test as_set(results_basic) == opt_set

            matched = length(intersect(opt_set, ref_set))
            println("  $label: $matched/$(length(ref_set)) matched " *
                    "($(round(100 * matched / max(length(ref_set), 1), digits=1))%)")
            total_matched += matched
            total_ref += length(ref_set)
        end
    end

    overall = total_ref == 0 ? 1.0 : total_matched / total_ref
    println("  ── Overall match vs SPMF reference: " *
            "$total_matched/$total_ref = $(round(overall * 100, digits=2))%")
    @test overall == 1.0
end
