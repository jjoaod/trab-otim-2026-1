function compute_makespan(order::Vector{Int}, p::Vector{Int})
    n = length(order)
    s = zeros(n)

    for idx in 1:n
        i = order[idx]
        earliest_start = 0.0

        for prev_idx in 1:idx-1
            j = order[prev_idx]
            earliest_start = max(earliest_start, s[j] + min(p[i], p[j]))
        end

        s[i] = earliest_start
    end

    C = maximum(s[i] + p[i] for i in 1:n)

    return s, C
end

function evaluate_makespan(order::Vector{Int}, i::Int, j::Int, p::Vector{Int})
    test_order = copy(order)
    test_order[i], test_order[j] = test_order[j], test_order[i]

    _, makespan = compute_makespan(test_order, p)

    return makespan
end

function simulated_annealing_with_swaps(
    p::Vector{Int},
    initial_order::Vector{Int},
    time_limit::Float64,
    initial_temp::Float64,
    cooling_rate::Float64,
    max_iterations_no_improvement::Int
)

    n = length(p)

    current_order = copy(initial_order)
    _, initial_makespan = compute_makespan(current_order, p)

    current_makespan = initial_makespan
    best_order = copy(current_order)
    best_makespan = current_makespan

    T0 = initial_temp
    T = T0

    iterations_no_improvement = 0

    start_time = time()

    total_iterations = 0
    accepted_moves = 0

    println("\n=== Starting Simulated Annealing ===")
    println("Initial makespan: $current_makespan")
    println("Initial temperature: $T0")
    println("Cooling rate: $cooling_rate")

    while time() - start_time < time_limit

        if time() - start_time >= time_limit
            break
        end

        total_iterations += 1

        a = rand(1:n-1)
        b = rand(a+1:n)

        new_makespan = evaluate_makespan(current_order, a, b, p)
        delta = new_makespan - current_makespan

        accept = false

        if delta < 0
            accept = true
            accepted_moves += 1
            iterations_no_improvement = 0
        else
            acceptance_prob = exp(-delta / T)
            if rand() < acceptance_prob
                accept = true
                accepted_moves += 1
            end
        end

        if accept
            current_order[a], current_order[b] = current_order[b], current_order[a]
            current_makespan = new_makespan

            if current_makespan < best_makespan
                best_order = copy(current_order)
                best_makespan = current_makespan
            end
        else
            iterations_no_improvement += 1
        end

        T *= cooling_rate

        if iterations_no_improvement >= max_iterations_no_improvement
            break
        end
    end

    println("\n=== Simulated Annealing Completed ===")
    println("Total iterations: $total_iterations")

    if total_iterations > 0
        println("Accepted moves: $accepted_moves (acceptance rate: $(round(accepted_moves/total_iterations*100, digits=2))%)")
    end

    println("Time elapsed: $(round(time() - start_time, digits=2)) seconds")
    println("Best makespan found: $best_makespan")
    println("Initial makespan: $initial_makespan")
    println("Improvement: $(round((initial_makespan - best_makespan) / initial_makespan * 100, digits=2))%")

    return best_order, best_makespan, initial_makespan
end

if length(ARGS) < 5
    println(stderr,
        "Usage: julia sa.jl output_file instance_file time_limit initial_temp cooling_rate max_iterations_no_improvement")
    exit(1)
end

output_file = ARGS[1]
instance_file = joinpath("adm", ARGS[2])

time_limit = parse(Float64, ARGS[3])
initial_temp = parse(Float64, ARGS[4])
cooling_rate = parse(Float64, ARGS[5])
max_iterations_no_improvement = parse(Int, ARGS[6])

println("Parsing file: ", instance_file)

lines = readlines(instance_file)

n = parse(Int, strip(lines[1]))
p = [parse(Int, strip(lines[i + 1])) for i in 1:n]

println("n: ", n)
println("M: ", sum(p))

initial_order = collect(1:n)

println("\n" * "="^50)

best_order, best_makespan, initial_makespan =
    simulated_annealing_with_swaps(
        p,
        initial_order,
        time_limit,
        initial_temp,
        cooling_rate,
        max_iterations_no_improvement
    )

println("\n" * "="^50)
println("=== Final Results ===")
println("Initial makespan: $initial_makespan")
println("Final makespan after simulated annealing: $best_makespan")
println("Improvement: $(round((initial_makespan - best_makespan) / initial_makespan * 100, digits=2))%")

println(best_makespan)

for x in best_order
    println(x)
end

open(output_file, "w") do io
    println(io, best_makespan)

    for x in best_order
        println(io, x)
    end
end