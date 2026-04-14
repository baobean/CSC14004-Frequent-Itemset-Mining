using Test

@testset "AprioriTID - test" begin
    include("test_correctness.jl")
    include("test_io.jl")
end
