include(joinpath(@__DIR__, "..", "src", "structures.jl"))
include(joinpath(@__DIR__, "..", "src", "utils.jl"))
include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_gen.jl"))
include(joinpath(@__DIR__, "..", "src", "algorithm", "apriori_tid.jl"))

struct AssociationRule
    antecedent::Vector{Int}
    consequent::Vector{Int}
    support::Float64      # sup(X ∪ Y) / N
    confidence::Float64   # sup(X ∪ Y) / sup(X)
    lift::Float64         # confidence / (sup(Y) / N)
    sup_count::Int        # absolute count of X ∪ Y
end

function generate_rules(freq_itemsets::Vector{Tuple{Vector{Int}, Int}},
                        n_trans::Int,
                        minconf::Float64)::Vector{AssociationRule}
    support_of = Dict{Vector{Int}, Int}()
    for (iset, cnt) in freq_itemsets
        support_of[iset] = cnt
    end

    rules = AssociationRule[]
    N = Float64(n_trans)

    for (F, sup_F) in freq_itemsets
        k = length(F)
        k < 2 && continue

        # Enumerate every non-empty proper subset via bitmask
        for mask in 1:(1 << k - 2)
            antecedent = Int[]
            consequent = Int[]
            @inbounds for i in 1:k
                if (mask >> (i - 1)) & 1 == 1
                    push!(antecedent, F[i])
                else
                    push!(consequent, F[i])
                end
            end

            sup_X = support_of[antecedent]
            sup_Y = support_of[consequent]
            conf = sup_F / sup_X
            conf < minconf && continue

            lift = conf / (sup_Y / N)
            push!(rules, AssociationRule(antecedent, consequent,
                                         sup_F / N, conf, lift, sup_F))
        end
    end

    return rules
end

function write_rules_csv(filepath::String, rules::Vector{AssociationRule})
    open(filepath, "w") do f
        println(f, "antecedent;consequent;support;confidence;lift;sup_count")
        for r in rules
            a = join(r.antecedent, " ")
            c = join(r.consequent, " ")
            println(f, a, ";", c, ";",
                    round(r.support, digits=6), ";",
                    round(r.confidence, digits=6), ";",
                    round(r.lift, digits=6), ";",
                    r.sup_count)
        end
    end
end

function top_rules_by(rules::Vector{AssociationRule}, key::Symbol; n::Int=10)
    keyfn = key === :confidence ? (r -> r.confidence) :
            key === :lift        ? (r -> r.lift) :
                                   (r -> r.support)
    sorted = sort(rules, by=keyfn, rev=true)
    return sorted[1:min(n, length(sorted))]
end
