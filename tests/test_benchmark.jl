using Test

if !@isdefined(apriori_tid)
    include(joinpath(@__DIR__, "..", "src", "structures.jl"))
    include(joinpath(@__DIR__, "..", "src", "utils.jl"))
    include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_gen.jl"))
    include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_tid.jl"))
end

@testset "Benchmark Performance Tests" begin

    @testset "Chess (minsup=2500)" begin
        fpath = joinpath(@__DIR__, "..", "data", "benchmark", "chess.txt")
        if isfile(fpath)
            transactions = read_spmf(fpath)
            @test length(transactions) > 0

            elapsed = @elapsed begin
                results = apriori_tid(transactions, 2500)
            end
            @test length(results) > 0
            println("  Chess (minsup=2500): $(length(results)) itemsets in $(round(elapsed*1000, digits=1)) ms")
        else
            @warn "chess.txt not found, skipping"
        end
    end

    @testset "Mushroom (minsup=4000)" begin
        fpath = joinpath(@__DIR__, "..", "data", "benchmark", "mushrooms.txt")
        if isfile(fpath)
            transactions = read_spmf(fpath)
            @test length(transactions) > 0

            elapsed = @elapsed begin
                results = apriori_tid(transactions, 4000)
            end
            @test length(results) > 0
            println("  Mushroom (minsup=4000): $(length(results)) itemsets in $(round(elapsed*1000, digits=1)) ms")
        else
            @warn "mushrooms.txt not found, skipping"
        end
    end

    @testset "Retail (minsup=1000)" begin
        fpath = joinpath(@__DIR__, "..", "data", "benchmark", "retail.txt")
        if isfile(fpath)
            transactions = read_spmf(fpath)
            @test length(transactions) > 0

            elapsed = @elapsed begin
                results = apriori_tid(transactions, 1000)
            end
            @test length(results) > 0
            println("  Retail (minsup=1000): $(length(results)) itemsets in $(round(elapsed*1000, digits=1)) ms")
        else
            @warn "retail.txt not found, skipping"
        end
    end

    @testset "T10I4D100K (minsup=1000)" begin
        fpath = joinpath(@__DIR__, "..", "data", "benchmark", "T10I4D100K.txt")
        if isfile(fpath)
            transactions = read_spmf(fpath)
            @test length(transactions) > 0

            elapsed = @elapsed begin
                results = apriori_tid(transactions, 1000)
            end
            @test length(results) > 0
            println("  T10I4D100K (minsup=1000): $(length(results)) itemsets in $(round(elapsed*1000, digits=1)) ms")
        else
            @warn "T10I4D100K.txt not found, skipping"
        end
    end

end
