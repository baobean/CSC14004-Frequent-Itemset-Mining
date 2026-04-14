# Khai thác tập phổ biến

Đồ án môn học **CSC14004 – Khai thác Dữ liệu và Ứng dụng**, tập trung vào tìm hiểu, cài đặt, và đánh giá thuật toán khai thác tập phổ biến (FIM).

Thuật toán được chọn là AprioriTID.

---

## 1. Yêu cầu môi trường

| Thành phần | Phiên bản |
|---|---|
| [Julia](https://julialang.org/downloads/) | ≥ 1.9 |
| Jupyter (tuỳ chọn, để chạy notebook) | bất kỳ, dùng kernel `IJulia` |

Các gói Julia được khai báo trong [Project.toml](Project.toml): `BenchmarkTools`, `CSV`, `DataFrames`, `IJulia`, `Plots`, `PrettyTables`, `Random`, `StatsBase`, `Test`.

## 2. Cài đặt

```bash
# Cài các gói phụ thuộc dựa trên Project.toml / Manifest.toml
julia --project -e 'using Pkg; Pkg.instantiate()'
```

Thư mục `data/benchmark/` chứa bốn bộ dữ liệu chuẩn (Chess, Mushrooms, Retail, T10I4D100K) lấy từ [FIMI Repository](http://fimi.uantwerpen.be/) và [SPMF](https://www.philippe-fournier-viger.com/spmf/).

## 3. Cấu trúc thư mục

```
Group_1/
├── README.md                      # Tài liệu này
├── Project.toml                   # Khai báo gói phụ thuộc Julia
├── Manifest.toml                  # Khóa phiên bản để tái lập
│
├── src/                           # Mã nguồn thuật toán
│   ├── main.jl                    # CLI entry point
│   ├── structures.jl              # Kiểu dữ liệu (Candidate, CBarEntry, ...)
│   ├── utils.jl                   # I/O định dạng SPMF
│   └── algorithm/
│       ├── apriori_gen.jl         # Sinh ứng viên (join + prune)
│       └── apriori_tid.jl         # Thuật toán AprioriTID chính
│
├── tests/                         # Kiểm thử tự động
│   ├── runtests.jl                # Entry point cho @testset
│   ├── test_correctness.jl        # Đối chiếu với SPMF trên toy + benchmark
│   └── test_io.jl                 # Kiểm thử đọc/ghi định dạng SPMF
│
├── data/
│   ├── toy/
│   │   ├── example1.txt           # Ví dụ 1
│   │   ├── example2.txt           # Ví dụ 2
│   │   ├── test_single_item.txt
│   │   ├── test_empty_result.txt
│   │   ├── test_all_frequent.txt
│   │   └── spmf_reference/        # Kết quả tham chiếu từ SPMF
│   └── benchmark/                 # Chess, Mushrooms, Retail, T10I4D100K
│       └── spmf_reference/
│
├── notebooks/
│   └── demo.ipynb                 # Notebook demo (cài đặt, kiểm thử, ứng dụng)
│
├── experiments/                   # Script chạy thực nghiệm Chương 4
├── experiment_results/            # CSV/biểu đồ kết xuất từ experiments
│
├── application/                   # Ứng dụng Chương 5: phân tích giỏ hàng
│   ├── market_basket.jl           # Sinh luật kết hợp từ tập phổ biến
│   └── run_retail.jl              # CLI trên dataset Retail
│
└── docs/                        # Báo cáo LaTeX (xelatex + biber)
    └── report.pdf
```

## 4. Chạy thuật toán qua CLI

```bash
# Cú pháp chung
julia --project src/main.jl <minsup> <input_file> [<output_file>]
```

Trong đó:

- `<minsup>`: Ngưỡng hỗ trợ tuyệt đối (số nguyên ≥ 1).
- `<input_file>`: Đường dẫn CSDL giao dịch ở định dạng SPMF (mỗi dòng một giao dịch, các item là số nguyên cách nhau bởi khoảng trắng).
- `<output_file>` (tuỳ chọn): Nếu có, kết quả sẽ được ghi vào file theo định dạng SPMF (`<items> #SUP: <count>`); nếu không, chương trình in ra `stdout`.

**Ví dụ:**

```bash
# Ví dụ 1 trong báo cáo (5 giao dịch, minsup = 2)
julia --project src/main.jl 2 data/toy/example1.txt

# Ghi kết quả ra file
julia --project src/main.jl 2 data/toy/example1.txt output.txt

# Chạy trên bộ benchmark Chess với minsup = 2500
julia --project src/main.jl 2500 data/benchmark/chess.txt results_chess.txt
```

Một phần kết quả mẫu (SPMF) trên `example1.txt`:

```
1 #SUP: 2
2 #SUP: 3
3 #SUP: 3
1 3 #SUP: 2
2 3 #SUP: 2
2 3 5 #SUP: 2
...
```

## 5. Chạy kiểm thử tự động

Toàn bộ test (cả đối chiếu đúng đắn và I/O) được gọi qua một entry point duy nhất:

```bash
julia --project tests/runtests.jl
```

Nội dung test gồm:

- `tests/test_correctness.jl` — Chạy AprioriTID trên cả 5 bộ dữ liệu toy và so từng tập phổ biến (kèm support) với kết quả SPMF tham chiếu trong `data/toy/spmf_reference/`. Tỷ lệ khớp phải đạt 100%.
- `tests/test_io.jl` — Kiểm thử hai chiều cho hàm đọc/ghi định dạng SPMF.

**Kết quả**:

```
  Example 1:     11/11 matched (100.0%)
  Example 2:     87/87 matched (100.0%)
  Single item:    1/1  matched (100.0%)
  Empty result:   0/0  matched (—)
  All frequent:   7/7  matched (100.0%)
  ── Overall match vs SPMF reference: 106/106 = 100.0%

Test Summary:     | Pass  Total  Time
AprioriTID - test |   30     30   2.5s
```

## 6. Chạy notebook demo

Notebook `notebooks/demo.ipynb` được viết bằng tiếng Việt, gồm 3 phần:

1. **Cài đặt cơ bản** — Chạy AprioriTID trên `example1.txt` để minh hoạ đầu ra.
2. **Kiểm thử đơn vị** — Chạy lại 5 bộ dữ liệu toy và hiển thị phần trăm khớp với SPMF.
3. **Ứng dụng — Phân tích giỏ hàng** — Sinh luật kết hợp trên bộ dữ liệu Retail (nội dung Chương 5).

Cách chạy:

```bash
# Cài kernel IJulia lần đầu nếu chưa có
julia --project -e 'using Pkg; Pkg.add("IJulia")'

# Mở Jupyter
julia --project -e 'using IJulia; notebook(dir="notebooks")'
```

Mở `demo.ipynb` rồi chọn **Kernel → Restart & Run All** để thực thi toàn bộ notebook từ đầu (yêu cầu của Mục 6 về việc nộp bài).

## 7. Chạy thực nghiệm

Các script trong `experiments/` dựng lại các biểu đồ thực nghiệm trong Chương 4 của báo cáo (thời gian chạy, số tập phổ biến, bộ nhớ, khả năng mở rộng). Kết quả (CSV + PDF biểu đồ) được ghi vào `experiment_results/`. Xem file tương ứng trong thư mục `experiments/` để biết cú pháp chạy từng thí nghiệm.

## 8. Chạy ứng dụng phân tích giỏ hàng

```bash
# Cú pháp: julia --project application/run_retail.jl <minsup> <minconf>
julia --project application/run_retail.jl 500 0.30
```

Lệnh trên chạy AprioriTID trên bộ Retail với `minsup = 500`, sau đó sinh luật kết hợp với ngưỡng độ tin cậy `minconf = 0.30`. Kết quả được ghi vào `experiment_results/retail_rules.csv` (gồm các cột `antecedent`, `consequent`, `support`, `confidence`, `lift`). Nội dung phân tích tương ứng nằm ở Chương 5 của báo cáo.