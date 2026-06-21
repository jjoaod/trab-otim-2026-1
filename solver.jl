using JuMP, HiGHS

function define_model(p::Vector{Int}, time_limit::Float64, mip_gap::Float64)
    n = length(p)

    model = Model(HiGHS.Optimizer)

    set_attribute(model, "time_limit", time_limit)
    set_attribute(model, "mip_rel_gap", mip_gap)

    @variable(model, s[1:n] >= 0)
    @variable(model, Y >= 0)
    @variable(model, t[1:n, 1:n], Bin)

    @objective(model, Min, Y)

    @constraint(model, [i=1:n], s[i] + p[i] <= Y)

    M = sum(p)

    @constraint(model,
        [i=1:n, j=1:n; i != j],
        s[i] - s[j] >= min(p[i], p[j]) - M * (1 - t[i,j]))

    @constraint(model,
        [i=1:n, j=1:n; i != j],
        s[j] - s[i] >= min(p[i], p[j]) - M * t[i,j])

    @constraint(model, [i=1:n, j=i+1:n], t[i,j] + t[j,i] == 1)
    @constraint(model, [i=1:n], t[i,i] == 0)

    return model, s, Y
end


if length(ARGS) < 2
    println(stderr, "Uso: julia adm.jl arquivo_saida instancia [time_limit]")
    exit(1)
end

output_file = ARGS[1]
instance_file = joinpath("adm", ARGS[2])

time_limit = length(ARGS) >= 3 ?
    parse(Float64, ARGS[3]) : 1800.0

const MIP_GAP = 0.01

lines = readlines(instance_file)

n = parse(Int, strip(lines[1]))
p = [parse(Int, strip(lines[i + 1])) for i in 1:n]

model, s, Y = define_model(p, time_limit, MIP_GAP)

optimize!(model)

status = termination_status(model)

if status == OPTIMAL || status == TIME_LIMIT

    makespan = objective_value(model)
    starts = value.(s)

    println(makespan)
    for i in 1:n
        println(i, " ", starts[i])
    end

    open(output_file, "w") do io
        println(io, makespan)
        for i in 1:n
            println(io, i, " ", starts[i])
        end
    end

else
    println(stderr, "Nenhuma solução encontrada. Status: ", status)
    exit(1)
end