using Test

if !@isdefined(apriori_tid)
    const _SRC = joinpath(@__DIR__, "..", "src")
    include(joinpath(_SRC, "structures.jl"))
    include(joinpath(_SRC, "utils.jl"))
    include(joinpath(_SRC, "algorithm", "apriori_gen.jl"))
    include(joinpath(_SRC, "algorithm", "apriori_tid.jl"))
end

@testset "SPMF I/O format" begin
    toy = joinpath(@__DIR__, "..", "data", "toy")

    @testset "read_spmf parses space-separated items per line" begin
        transactions = read_spmf(joinpath(toy, "example1.txt"))
        @test length(transactions) == 5
        @test eltype(transactions) == Vector{Int}
        @test all(issorted.(transactions))
    end

    @testset "read_spmf skips empty lines" begin
        tmp = tempname() * ".txt"
        open(tmp, "w") do io
            println(io, "1 2 3")
            println(io, "")
            println(io, "4 5")
            println(io, "")
        end
        transactions = read_spmf(tmp)
        rm(tmp)
        @test length(transactions) == 2
        @test transactions[1] == [1, 2, 3]
        @test transactions[2] == [4, 5]
    end

    @testset "write_spmf roundtrip preserves (itemset, support)" begin
        transactions = read_spmf(joinpath(toy, "example1.txt"))
        results = apriori_tid(transactions, 2)
        tmp = tempname() * ".txt"
        write_spmf(tmp, results)
        read_back = read_spmf_output(tmp)
        rm(tmp)
        orig = Set([(sort(is), sup) for (is, sup) in results])
        back = Set([(sort(is), sup) for (is, sup) in read_back])
        @test orig == back
    end

    @testset "write_spmf output is sorted by length then lexicographically" begin
        results = [([2, 3], 5), ([1], 10), ([1, 2], 7), ([4], 6)]
        tmp = tempname() * ".txt"
        write_spmf(tmp, results)
        lines = readlines(tmp)
        rm(tmp)
        @test lines[1] == "1 #SUP: 10"
        @test lines[2] == "4 #SUP: 6"
        @test lines[3] == "1 2 #SUP: 7"
        @test lines[4] == "2 3 #SUP: 5"
    end

    @testset "read_spmf_output parses #SUP: format correctly" begin
        tmp = tempname() * ".txt"
        open(tmp, "w") do io
            println(io, "1 #SUP: 10")
            println(io, "1 2 3 #SUP: 5")
        end
        parsed = read_spmf_output(tmp)
        rm(tmp)
        @test length(parsed) == 2
        @test parsed[1] == ([1], 10)
        @test parsed[2] == ([1, 2, 3], 5)
    end
end
