using Test

# Include source files once
include(joinpath(@__DIR__, "..", "src", "structures.jl"))
include(joinpath(@__DIR__, "..", "src", "utils.jl"))
include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_gen.jl"))
include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_tid.jl"))

@testset "AprioriTID Full Test Suite" begin
    include("test_correctness.jl")
    include("test_spmf_reference.jl")
    include("test_benchmark.jl")
end
