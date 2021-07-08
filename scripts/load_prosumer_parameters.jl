#=
All parameters / settings related to prosumers.
=#

#--- from data
SH_ref = readdlm("network-aware-heat-market/data/SH_ref.csv", ',')
L̂ᴴ = readdlm("network-aware-heat-market/data/L_hat.csv", ',')
 # load from file
DHW = readdlm("network-aware-heat-market/data/DHW.csv", ',')

#--- other consumer variables
Random.seed!(1234)

# heat pump placement
nr_of_hp = 6
hp_agents = sort(shuffle(1:n_a)[1:nr_of_hp])
nonhp_agents = setdiff(1:n_a, hp_agents)
have_hp = zeros(n_a)
have_hp[hp_agents] .= 1

# max load
mean_Lmax = 1.0*10^6
Lmax = rand(Normal(mean_Lmax, mean_Lmax / 10), n_a)

# max generation
mean_Gmax = 6.0*10^4
G̅ᴴ = rand(Normal(mean_Gmax, mean_Gmax / 100), n_a) .* have_hp

# COP
mean_cop = 4.5 # 3.5
cop = mean_cop * ones(n_a) .* have_hp #
cop[hp_agents] = reverse([mean_cop - i*0.05 for i in 1:length(hp_agents)]) .*
                (163.02 ./ 524 ) .* 2.5

# utility
# average (relative) utility per time of day for SH
mean_u_t = Vector([1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
                   8.0, 9.0, 4.0,
                   2.0, 2.0, 2.0, 2.0, 4.0, 5.0,
                   9.0, 9.0, 9.0, 9.0,
                   8.0, 7.0, 4.0, 3.0 ])
u_t = reduce(hcat, [rand(Normal(mean_u_t[t], mean_u_t[t]/100), n_a)
        for t in range(1, length=n_t)])
