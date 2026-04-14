function apriori_gen(L_prev_sorted::Vector{Vector{Int}}, L_prev_set::Set{Vector{Int}})::Vector{Candidate}
    candidates = Candidate[]
    n = length(L_prev_sorted)
    n == 0 && return candidates

    k_minus_1 = length(L_prev_sorted[1])  # length of each itemset in L_{k-1}

    # --- Join step ---
    # L_prev_sorted is lexicographically sorted, so items sharing a prefix are adjacent
    @inbounds for i in 1:n
        p = L_prev_sorted[i]
        for j in (i+1):n
            q = L_prev_sorted[j]

            # Check if first k-2 items match
            prefix_match = true
            for m in 1:(k_minus_1 - 1)
                if p[m] != q[m]
                    prefix_match = false
                    break
                end
            end

            # If prefix doesn't match, no further q's will match either (sorted order)
            if !prefix_match
                break
            end

            # Create candidate by merging: [p..., q[end]]
            candidate = Vector{Int}(undef, k_minus_1 + 1)
            @inbounds for m in 1:k_minus_1
                candidate[m] = p[m]
            end
            candidate[k_minus_1 + 1] = q[k_minus_1]
            push!(candidates, Candidate(candidate, 0))
        end
    end

    # --- Prune step ---
    # For each candidate, check all (k-1)-subsets are in L_{k-1}
    k = k_minus_1 + 1
    if k > 2  # For k=2, all 1-subsets are guaranteed to be in L_1 by construction
        pruned = Candidate[]
        sizehint!(pruned, length(candidates))
        subset = Vector{Int}(undef, k - 1)  # reusable buffer

        @inbounds for cand in candidates
            c = cand.itemset
            is_valid = true

            # Generate each (k-1)-subset by removing one element at a time
            for skip in 1:k
                idx = 1
                for m in 1:k
                    if m != skip
                        subset[idx] = c[m]
                        idx += 1
                    end
                end

                if !(subset in L_prev_set)
                    is_valid = false
                    break
                end
            end

            if is_valid
                push!(pruned, cand)
            end
        end
        return pruned
    end

    return candidates
end
