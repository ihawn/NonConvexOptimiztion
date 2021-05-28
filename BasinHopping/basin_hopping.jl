using Plots
using Calculus
using LinearAlgebra
include("C:/Users/Isaac/Documents/Optimization/NonConvex/NonConvexOptimization/NonConvexOptimiztion/testobjectives.jl")


function Compute_Gradient(_f, _x)
    return Calculus.gradient(g -> _f(g),_x)
end


function Compute_Hessian(_f, _x)
    return hessian(h -> _f(h),_x)
end


function Back_Line_Search(_x, _f, _fx, _∇f, _Δx, _α, _β, _κ)
    _t = _κ

    while _f((_x + _t*_Δx)) > _fx + _α*_t*transpose(_∇f)*_Δx && _t > 1e-8
        _t *= _β
    end

    return _t
end


function Newton_Step(_∇f, _∇2f, _x)
    return _∇2f\-_∇f
end


function Newton_Decrement(_∇2f, _Δxnt)
    return transpose(_Δxnt)*_∇2f*_Δxnt
end


function Unconstrained_Newton(_f, _x, _α, _β, _κ, _ϵ, maxIt)

    λ2 = 1
    it = 0
    val = _f(_x)

    while λ2 > _ϵ && it <= maxIt
        val = _f(_x)
        ∇f = Compute_Gradient(_f, _x)
        ∇2f = Compute_Hessian(_f, _x)
        Δxnt = Newton_Step(∇f, ∇2f, _x)
        λ2 = Newton_Decrement(∇2f, Δxnt)
        t = Back_Line_Search(_x, _f, val, ∇f, Δxnt, _α, _β, _κ)
        _x += t*Δxnt
        it+=1
    end


    push!(minsX, _x[1])
    push!(minsY, _x[2])

    return _x, val
end


function Grad_Descent(_f, _x, _α, _β, _ϵ, _κ, maxIt)
    it = 0;
    t = 1
    ∇f = Compute_Gradient(_f, _x)

    normGrad = norm(∇f)

    val = _f(_x)

    push!(xPlot, _x[1])
    push!(yPlot, _x[2])

    while normGrad > _ϵ && it < 1e2
        ∇f = Compute_Gradient(_f, _x)
        normGrad = norm(∇f)

        bls = Back_Line_Search(_x, _f, val, ∇f, -∇f, _α, _β, _κ)
        t = bls[1]
        _x -= t*∇f
        val = _f(_x)

        push!(xPlot, _x[1])
        push!(yPlot, _x[2])

        it+=1
    end

    push!(solPlotX, _x[1])
    push!(solPlotY, _x[2])

    return _x, val
end


function Generate_ℓ_Vector(_x, _ℓ)
    return (rand(length(_x)) .- 0.5) * _ℓ
end


function Metropolis_Accept(val_new, val_old, _T)

    if val_new < val_old
        return true
    else
        return rand() >= exp(min(0, (val_old - val_new)/_T))
    end
end


function Monte_Carlo_Step(old_val, _f, _x, _ℓ, _η, _α, _β, _κ, _T, maxIt)

    vec = Generate_ℓ_Vector(_x, _ℓ)
    local_sol = Grad_Descent(_f, _x + vec, _α, _β, _η, _κ, maxIt)
    accept = Metropolis_Accept(local_sol[2], old_val, _T)

    push!(searchX, (local_sol[1] + vec)[1])
    push!(searchY, (local_sol[1] + vec)[2])

    return accept, local_sol
end


function Adjust_Step_Length(target_rate, rate, scale_factor, _ϕ, _ℓ, _ℓ_range)

    if rate > target_rate + _ϕ #stuck in a local min so increase step length
        _ℓ = min(_ℓ_range[2], _ℓ/scale_factor)
    elseif rate < target_rate - _ϕ #random search is all over the place so take smaller steps
        _ℓ = max(_ℓ_range[1], _ℓ*scale_factor)
    end

    return _ℓ
end


function Basin_Hopping(_f, _x, _α, _β, _η, _ϵ, _κ, _ℓ, _ℓ_range, _γ, _ϕ, _T, target_rate, maxIt, stat_thresh)


    static_count = 0
    acceptance = 0
    rejection = 0

    println("Computing first solution")
    min_sol = Grad_Descent(_f, _x, _α, _β, _η, _κ, maxIt)
    push!(minsX, _x[1])
    push!(minsY, _x[2])

    println("Starting Basin Hopping")

    for i = 1:maxIt
        sol = Grad_Descent(_f, _x, _α, _β, _η, _κ, maxIt)
        val = sol[2]
        accept = Monte_Carlo_Step(sol[2], _f, _x, _ℓ, _η, _α, _β, _κ, _T, maxIt)

        if accept[1]
            _x = accept[2][1]
            val = accept[2][2]

            if val < min_sol[2] - _η
                min_sol = accept[2]
                push!(minsX, _x[1])
                push!(minsY, _x[2])

                static_count = 0
            else
                static_count += 1
            end

            acceptance += 1
        else
            rejection += 1
            static_count += 1
        end

        if static_count >= stat_thresh
            break
        end

        acceptance_rate = acceptance/(acceptance + rejection)
        _ℓ = Adjust_Step_Length(target_rate, acceptance_rate, _γ, _ϕ, _ℓ, _ℓ_range,)


        println("\nIteration ", i)
        println("Step Acceptance Rate = ", 100*acceptance_rate, "%")
        println("Step size = ", _ℓ)
        println("x = ", _x)
        println("Objective = ", val)
    end

    min_sol = Unconstrained_Newton(_f, min_sol[1], _α, _β, _κ, _ϵ, maxIt)



    return min_sol
end


xPlot = []
yPlot = []
solPlotX = []
solPlotY = []
searchX = []
searchY = []
minsX = []
minsY = []
finalSolX = []
finalSolY = []

flush(stdout)

n = 2
x0 = 2*(rand(n) .- 0.5) * 100.0
ϵ = 1e-8
η = 1e-5
α = 0.5
β = 0.8
κ = 1
ℓ = 1
ℓ_range = (1, 5) #min should not exceed the smallest distance between convex regions
γ = 0.9
ϕ = 0.0
T = 1
static_threshold = 5e2 #number of iterations that we allow the solution to stay the same. Used as a stopping condition
target_acc_rate = 0.6
maxIterations = 2e3

#f(x) = x[1]^2 + x[2]^2 + 7*sin(x[1] + x[2]) + 10*sin(5x[1])
#f(x) = (x[2] - 0.129*x[1]^2 + 1.6*x[1] - 6)^2 + 6.07*cos(x[1]) + 10
#f(x) = Rastrigin(x, n)
#f(x) = Ackley(x)
#f(x) = Bukin(x)
#f(x) = Holder_Table(x)
f(x) = Schaffer_N2(x)
#f(x) = Styblinski_Tang(x,n)
#f(x) = Beale(x)
#f(x) = Rosenbrock(x, n)
#f(x) = Easom(x)
#f(x) = Three_Hump_Camel(x)
#f(x) = Matyas(x)
#f(x) = Himmelblau(x)
#f(x) = Levi(x)
#f(x) = Michalewicz(x, n)


minSol = Basin_Hopping(f, x0, α, β, η, ϵ, κ, ℓ, ℓ_range, γ, ϕ, T,
                        target_acc_rate, maxIterations, static_threshold)
for i = 1:10
    sol = Basin_Hopping(f, x0, α, β, η, ϵ, κ, ℓ, ℓ_range, γ, ϕ, T,
                            target_acc_rate, maxIterations, static_threshold)
    if sol[2] < minSol[2]
        minSol = sol
    end

    x0 = 2*(rand(n) .- 0.5) * 10.0
end

push!(finalSolX, minSol[1][1])
push!(finalSolY, minSol[1][2])

println("\nFinal Solution: ", minSol)

if n == 2
    plotf(x,y) = f([x, y])
    _x = -10.0:0.02:10.0
    _y = -10.0:0.02:10.0
    X = repeat(reshape(_x, 1, :), length(_y), 1)
    Y = repeat(_y, 1, length(_x))
    Z = map(plotf, X, Y)
    p1 = Plots.contour(_x,_y, plotf, fill = true)
    plot(p1, legend = false, xrange = (-10,10), yrange = (-10,10), title = "Global Minimization With Basin Hopping")
    scatter!(searchX, searchY, markersize = 2.5, color = "blue")
    scatter!(xPlot, yPlot, markersize = 2, color = "red")
    scatter!(solPlotX, solPlotY, color = "green", markersize = 2)
    plot!(minsX, minsY, color = "white")
    scatter!(minsX, minsY, color = "green")
    scatter!(finalSolX, finalSolY, color = "white")
end