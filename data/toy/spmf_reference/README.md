# SPMF Reference Outputs (Toy Datasets)

Reference outputs in SPMF format (`items #SUP: count`) for the toy datasets under `data/toy/`.
Each file corresponds to running AprioriTID on the input of the same name with the minsup
listed below, and is used by `tests/test_spmf_reference.jl` to report match percentage.

These references were derived independently from hand/specification computation (not by
running our own implementation), so they serve as an external oracle.

| File                       | Input                      | minsup |
|----------------------------|----------------------------|--------|
| `example1.txt`             | `example1.txt`             | 2      |
| `test_single_item.txt`     | `test_single_item.txt`     | 2      |
| `test_empty_result.txt`    | `test_empty_result.txt`    | 3      |
| `test_all_frequent.txt`    | `test_all_frequent.txt`    | 2      |

The reference for `example2.txt` (87 itemsets) is generated at test time in
`test_spmf_reference.jl` from its closed-form specification.
