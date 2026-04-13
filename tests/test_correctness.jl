using Test

# Include source files (skipped if already loaded via runtests.jl)
if !@isdefined(apriori_tid)
    include(joinpath(@__DIR__, "..", "src", "structures.jl"))
    include(joinpath(@__DIR__, "..", "src", "utils.jl"))
    include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_gen.jl"))
    include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_tid.jl"))
end

"""Helper to convert results to a comparable set of (sorted itemset, support) tuples."""
function results_to_set(results::Vector{Tuple{Vector{Int}, Int}})
    Set([(sort(is), sup) for (is, sup) in results])
end

@testset "AprioriTID Correctness Tests" begin

    @testset "Example 1: Basic (minsup=2)" begin
        transactions = read_spmf(joinpath(@__DIR__, "..", "data", "toy", "example1.txt"))
        results = apriori_tid(transactions, 2)

        expected = Set([
            ([1], 4), ([2], 3), ([4], 3), ([5], 3),
            ([1, 2], 3), ([1, 4], 3), ([1, 5], 2), ([2, 4], 2), ([4, 5], 2),
            ([1, 2, 4], 2), ([1, 4, 5], 2)
        ])

        @test results_to_set(results) == expected
        @test length(results) == 11
    end

    @testset "Example 2: Dense dataset (minsup=2)" begin
        transactions = read_spmf(joinpath(@__DIR__, "..", "data", "toy", "example2.txt"))
        results = apriori_tid(transactions, 2)

        # All 7 items appear >= 2 times, so all 1-itemsets are frequent
        freq_1 = [(is, sup) for (is, sup) in results if length(is) == 1]
        @test length(freq_1) == 7

        # Total frequent itemsets should be substantial for this dense dataset
        @test length(results) > 20
    end

    @testset "Single item transactions (minsup=2)" begin
        transactions = read_spmf(joinpath(@__DIR__, "..", "data", "toy", "test_single_item.txt"))
        results = apriori_tid(transactions, 2)

        # Only item 1 appears >= 2 times
        @test results_to_set(results) == Set([([1], 3)])
        @test length(results) == 1
    end

    @testset "Empty result (minsup=3)" begin
        transactions = read_spmf(joinpath(@__DIR__, "..", "data", "toy", "test_empty_result.txt"))
        results = apriori_tid(transactions, 3)

        @test isempty(results)
    end

    @testset "All frequent (minsup=2)" begin
        transactions = read_spmf(joinpath(@__DIR__, "..", "data", "toy", "test_all_frequent.txt"))
        results = apriori_tid(transactions, 2)

        expected = Set([
            ([1], 3), ([2], 3), ([3], 3),
            ([1, 2], 3), ([1, 3], 3), ([2, 3], 3),
            ([1, 2, 3], 3)
        ])

        @test results_to_set(results) == expected
        @test length(results) == 7
    end

    @testset "Optimized vs basic give same results" begin
        transactions = read_spmf(joinpath(@__DIR__, "..", "data", "toy", "example1.txt"))
        results_opt = apriori_tid(transactions, 2; optimized=true)
        results_basic = apriori_tid(transactions, 2; optimized=false)

        @test results_to_set(results_opt) == results_to_set(results_basic)
    end

    @testset "SPMF I/O round-trip" begin
        transactions = read_spmf(joinpath(@__DIR__, "..", "data", "toy", "example1.txt"))
        results = apriori_tid(transactions, 2)

        # Write to temp file and read back
        tmpfile = tempname() * ".txt"
        write_spmf(tmpfile, results)
        read_back = read_spmf_output(tmpfile)
        rm(tmpfile)

        @test results_to_set(results) == Set([(sort(is), sup) for (is, sup) in read_back])
    end

end
