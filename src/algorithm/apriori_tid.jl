function apriori_tid(transactions::Vector{Vector{Int}}, minsup::Int;
                     optimized::Bool=true)::Vector{Tuple{Vector{Int}, Int}}

    n_trans = length(transactions)
    results = Tuple{Vector{Int}, Int}[]

    # ========== Step 1: Find L_1 and build C̄_1 ==========
    # Count support of each individual item
    item_counts = Dict{Int, Int}()
    for trans in transactions
        @inbounds for item in trans
            item_counts[item] = get(item_counts, item, 0) + 1
        end
    end

    # L_1: frequent 1-itemsets
    L_1_items = sort!([item for (item, cnt) in item_counts if cnt >= minsup])
    L_1_set_items = Set(L_1_items)

    # Store L_1 results
    for item in L_1_items
        push!(results, ([item], item_counts[item]))
    end

    isempty(L_1_items) && return results

    # Build L_prev as sorted Vector of itemsets, and Set for lookup
    L_prev_sorted = Vector{Int}[[item] for item in L_1_items]
    L_prev_set = Set{Vector{Int}}(L_prev_sorted)

    # ========== Step 2: Build C̄_1 ==========
    # C̄_1 = database D, with each transaction mapped to its frequent 1-itemsets
    cbar_prev = CBarEntry[]
    sizehint!(cbar_prev, n_trans)
    for (tid, trans) in enumerate(transactions)
        itemsets_in_trans = Vector{Int}[]
        @inbounds for item in trans
            if item in L_1_set_items
                push!(itemsets_in_trans, [item])
            end
        end
        if !isempty(itemsets_in_trans)
            push!(cbar_prev, CBarEntry(tid, itemsets_in_trans))
        end
    end

    # ========== Steps 3-13: Main loop ==========
    k = 2
    while !isempty(L_prev_sorted)
        # Step 4: Generate candidates C_k
        C_k = apriori_gen(L_prev_sorted, L_prev_set)
        isempty(C_k) && break

        # Step 5-11: Count support using C̄_{k-1}
        cbar_k = CBarEntry[]

        if optimized
            _count_support_optimized!(cbar_k, cbar_prev, C_k, k)
        else
            _count_support_basic!(cbar_k, cbar_prev, C_k, k)
        end

        # Step 12: Filter L_k
        L_k_sorted = Vector{Int}[]
        for cand in C_k
            if cand.count >= minsup
                push!(results, (cand.itemset, cand.count))
                push!(L_k_sorted, cand.itemset)
            end
        end
        sort!(L_k_sorted)

        # Advance to next iteration
        L_prev_sorted = L_k_sorted
        L_prev_set = Set{Vector{Int}}(L_prev_sorted)
        cbar_prev = cbar_k
        k += 1
    end

    return results
end

"""
Basic (unoptimized) support counting: scan all candidates for each transaction.
"""
function _count_support_basic!(cbar_k::Vector{CBarEntry},
                               cbar_prev::Vector{CBarEntry},
                               C_k::Vector{Candidate},
                               k::Int)
    @inbounds for t in cbar_prev
        t_set = Set{Vector{Int}}(t.itemsets)
        ct_itemsets = Vector{Int}[]

        for cand in C_k
            c = cand.itemset
            # c - c[k]: remove last element
            sub1 = @view c[1:end-1]
            # c - c[k-1]: remove second-to-last element
            sub2 = vcat(@view(c[1:end-2]), @view(c[end:end]))

            if Vector{Int}(sub1) in t_set && sub2 in t_set
                cand.count += 1
                push!(ct_itemsets, copy(c))
            end
        end

        if !isempty(ct_itemsets)
            push!(cbar_k, CBarEntry(t.tid, ct_itemsets))
        end
    end
end

"""
Optimized support counting: hash-based candidate lookup using prefix mapping.
Instead of scanning all candidates for each transaction, build a Dict mapping
each prefix (c[1:end-1]) to candidate indices, then look up via transaction itemsets.
"""
function _count_support_optimized!(cbar_k::Vector{CBarEntry},
                                   cbar_prev::Vector{CBarEntry},
                                   C_k::Vector{Candidate},
                                   k::Int)
    # Build prefix -> candidate indices mapping
    prefix_map = Dict{Vector{Int}, Vector{Int}}()
    @inbounds for (idx, cand) in enumerate(C_k)
        prefix = cand.itemset[1:end-1]
        if haskey(prefix_map, prefix)
            push!(prefix_map[prefix], idx)
        else
            prefix_map[prefix] = [idx]
        end
    end

    @inbounds for t in cbar_prev
        t_set = Set{Vector{Int}}(t.itemsets)
        ct_itemsets = Vector{Int}[]

        # For each itemset in this transaction, look up candidates sharing it as prefix
        for itemset in t.itemsets
            cand_indices = get(prefix_map, itemset, nothing)
            cand_indices === nothing && continue

            for idx in cand_indices
                cand = C_k[idx]
                c = cand.itemset
                # We already know c[1:end-1] (the prefix) is in t_set (it's `itemset`)
                # Now check c - c[k-1]: remove second-to-last element
                sub2 = vcat(@view(c[1:end-2]), @view(c[end:end]))
                if sub2 in t_set
                    cand.count += 1
                    push!(ct_itemsets, copy(c))
                end
            end
        end

        if !isempty(ct_itemsets)
            push!(cbar_k, CBarEntry(t.tid, ct_itemsets))
        end
    end
end
