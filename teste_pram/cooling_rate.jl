using Statistics

function compute_makespan(order::Vector{Int}, p::Vector{Int})
    n = length(order)
    s = zeros(n)

    for idx in 1:n
        i = order[idx]

        earliest_start = 0.0

        for prev_idx in 1:(idx - 1)
            j = order[prev_idx]

            earliest_start = max(
                earliest_start,
                s[j] + min(p[i], p[j])
            )
        end

        s[i] = earliest_start
    end

    C = maximum(s[i] + p[i] for i in 1:n)

    return s, C
end

function evaluate_makespan(
    order::Vector{Int},
    i::Int,
    j::Int,
    p::Vector{Int}
)
    test_order = copy(order)

    test_order[i], test_order[j] =
        test_order[j], test_order[i]

    _, makespan = compute_makespan(test_order, p)

    return makespan
end

function simulated_annealing_with_swaps(
    p::Vector{Int},
    initial_order::Vector{Int},
    time_limit::Float64;
    max_iterations_no_improvement::Int = 100,
    T0::Float64 = 1000.0,
    T_min::Float64 = 1e-6,
    cooling_rate::Float64 = 0.995
)

    n = length(p)

    current_order = copy(initial_order)

    _, current_makespan =
        compute_makespan(current_order, p)

    best_order = copy(current_order)
    best_makespan = current_makespan

    T = T0

    iterations_per_temp = max(10, n)

    iterations_no_improvement = 0

    start_time = time()

    while time() - start_time < time_limit &&
          T > T_min

        for _ in 1:iterations_per_temp

            a = rand(1:n - 1)
            b = rand(a + 1:n)

            new_makespan =
                evaluate_makespan(
                    current_order,
                    a,
                    b,
                    p
                )

            delta =
                new_makespan -
                current_makespan

            accept = false

            if delta < 0

                accept = true
                iterations_no_improvement = 0

            else

                acceptance_prob =
                    exp(-delta / T)

                if rand() < acceptance_prob
                    accept = true
                end
            end

            if accept

                current_order[a],
                current_order[b] =
                    current_order[b],
                    current_order[a]

                current_makespan =
                    new_makespan

                if current_makespan <
                   best_makespan

                    best_order =
                        copy(current_order)

                    best_makespan =
                        current_makespan
                end

            else

                iterations_no_improvement += 1

            end
        end

        T *= cooling_rate

        if iterations_no_improvement >=
           max_iterations_no_improvement
            break
        end
    end

    return best_order,
           best_makespan
end

function load_instance(filename)

    lines = readlines(filename)

    n = parse(Int, strip(lines[1]))

    p = [
        parse(Int, strip(lines[i + 1]))
        for i in 1:n
    ]

    return p
end

if length(ARGS) < 1
    println("Usage: julia study.jl output_file")
    exit(1)
end

OUTPUT_FILE = ARGS[1]

TIME_LIMIT = 1800.0

instances = [
    ("adm_1000_1.dat", 35035.0),
    ("adm_1000_2.dat", 34148.0),
    ("adm_100_1.dat", 3558.0),
    ("adm_100_2.dat", 3220.0)
]

cooling_rates = [
    0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45,
    0.50, 0.55, 0.60, 0.65, 0.70, 0.75, 0.80, 0.85,
    0.90, 0.945, 0.99
]

results = []

avg_optimalities = Float64[]

println()
println("======================================")
println("COOLING RATE STUDY")
println("======================================")
println()

println(
    "CoolingRate\tInstance\tBestKnown\tObtained\tOptimality\tTime"
)

for cooling_rate in cooling_rates

    current_optimalities = Float64[]

    println()
    println(
        "Testing cooling_rate = ",
        round(cooling_rate, digits = 4)
    )

    for (file, best_known) in instances

        p = load_instance(file)

        initial_order =
            collect(1:length(p))

        start_t = time()

        _, obtained =
            simulated_annealing_with_swaps(
                p,
                initial_order,
                TIME_LIMIT;
                max_iterations_no_improvement = 1000,
                T0 = 100.0,
                T_min = 1e-6,
                cooling_rate = cooling_rate
            )

        elapsed = time() - start_t

        optimality =
            best_known / obtained

        push!(
            current_optimalities,
            optimality
        )

        push!(
            results,
            (
                cooling_rate,
                file,
                best_known,
                obtained,
                optimality,
                elapsed
            )
        )

        println(
            round(cooling_rate, digits = 4), "\t",
            file, "\t",
            Int(best_known), "\t",
            Int(obtained), "\t",
            round(optimality, digits = 6), "\t",
            round(elapsed, digits = 2)
        )
    end

    avg_opt =
        mean(current_optimalities)

    push!(
        avg_optimalities,
        avg_opt
    )

    println(
        "Average Optimality = ",
        round(avg_opt, digits = 6)
    )
end

println()
println("======================================")
println("AVERAGE OPTIMALITY BY COOLING RATE")
println("======================================")

for i in eachindex(cooling_rates)

    println(
        "Cooling Rate = ",
        round(cooling_rates[i], digits = 4),
        " | Average Optimality = ",
        round(avg_optimalities[i], digits = 6)
    )
end

open(OUTPUT_FILE, "w") do io

    println(
        io,
        "CoolingRate\tInstance\tBestKnown\tObtained\tOptimality\tTime"
    )

    for r in results

        println(
            io,
            round(r[1], digits = 4), "\t",
            r[2], "\t",
            Int(r[3]), "\t",
            Int(r[4]), "\t",
            round(r[5], digits = 6), "\t",
            round(r[6], digits = 2)
        )
    end

    println(io)
    println(io)
    println(io, "AVERAGE OPTIMALITY BY COOLING RATE")
    println(io, "CoolingRate\tAverageOptimality")

    for i in eachindex(cooling_rates)

        println(
            io,
            round(cooling_rates[i], digits = 4), "\t",
            round(avg_optimalities[i], digits = 6)
        )
    end
end

println()
println("======================================")
println("FINISHED")
println("======================================")
println("Results saved to ", OUTPUT_FILE)