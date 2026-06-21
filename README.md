# trab-otim-2026-1

## Solver

Execute:

```bash
julia solver.jl solucao.txt adm_50_1.dat 10
```

### Parameters

| Parameter | Description |
|------------|------------|
| `solucao.txt` | Output file |
| `adm_50_1.dat` | Instance file (searched in `adm/`) |
| `10` | Time limit (seconds) |

---

## Simulated Annealing

Execute:

```bash
julia simulated_annealing.jl solucao.txt adm_50_1.dat 60 1000.0 0.995 750
```

### Parameters

| Parameter | Description |
|------------|------------|
| `solucao.txt` | Output file |
| `adm_50_1.dat` | Instance file (searched in `adm/`) |
| `60` | Time limit (seconds) |
| `1000.0` | Initial temperature |
| `0.995` | Cooling rate |
| `750` | Maximum iterations without improvement |

---

## Parameter Tests

### Initial Temperature

```bash
julia initial_temp.jl results.txt
```

### Maximum Iterations Without Improvement

```bash
julia max_iter_no_improv.jl results.txt
```

### Cooling Rate

```bash
julia cooling_rate.jl results.txt
```

All test results are written to the specified output file.

---

## Greedy Search

Execute:

```bash
julia simulated_annealing.jl solucao.txt adm_50_1.dat 60 0.001 0.999 750
```

### Parameters

| Parameter | Description |
|------------|------------|
| `solucao.txt` | Output file |
| `adm_50_1.dat` | Instance file (searched in `adm/`) |
| `60` | Time limit (seconds) |
| `0.001` | Initial temperature |
| `0.999` | Cooling rate |
| `750` | Maximum iterations without improvement |

This configuration behaves as a greedy local search due to the very low initial temperature.
