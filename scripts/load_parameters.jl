#=
script to load and create all needed parameters / model inputs
=#
using Random
using Distributions
using DelimitedFiles
using DataFrames
include("../functions/get_network_inputs.jl")

#--- basic settings
n_a = 28
n_t = 24
scale_util = 0.5*10^(-3)

#--- constant
ρ = 0.997*10^3  # density of water  in kg/m³
cf = 4179.6  # water specific heat capacity (J/kg/K)
#flex = "chunk"

#--- consumer parameters
include("load_prosumer_parameters.jl")

#--- DHN data
# collected in a structure, contains network configuration
dhn = get_network_inputs()

# flow limits
ṁ̲ = 0 * ones(dhn.nₚ)   # min flow, kg/s
max_flow_speed = 2  # m/s
m̅̇ = max_flow_speed * ρ *pi * (dhn.Rₚ).^2

#--- parameters: nodal supply and return temp!
Tˢ = zeros(dhn.nₙ) # [90.0 - n  for n in 1:dhn.nₙ]
Tˢ[1] = 90.0
Tᴿ = zeros(dhn.nₙ)
Tᴿ[1] = 40.0  # * ones(dhn.nₙ)

degree_per_km = 2.2
degree_per_m = degree_per_km/1000

for n in 2:dhn.nₙ
    Tˢ[n] = (Tˢ[[n-1]] .- degree_per_m*dhn.Lₚ[dhn.n2 .== n])[1]
    Tᴿ[n] = (Tᴿ[[n-1]] .- 0.5*degree_per_m*dhn.Lₚ[dhn.n2 .== n])[1]
end
reverse!(Tᴿ)

#--- import prices
# heat import price = constant
ciᵍᴴ = 524 / 7.5 .* ones(n_t) #  ./ 10^6  # EUR/MWh without MOMS
# el price from Nord Pool, multiply by 3 to get real consumer price
ciᵍᴱ = 2.5 .* [49.31, 47.38, 45.78,44.51,45.69,50.33,59.71,79.56,103.54,
                     107.80,107.32,104.26,99.91,95.27,92.72,95.42,95.00,110.00,
                     99.95,80.12,64.24,59.43,56.22,51.75] #./10^6 # EUR / MWh

#--- locatoins of agents in the grid
# grid connection node
g_loc = 1
non_grid_nodes = setdiff(Vector(1:dhn.nₙ), g_loc)

# prosumer and HP-prosumer locations
Random.seed!(1244)
a_loc = Int.(zeros(n_a))
# place HP agents over the network.
a_loc[hp_agents] = [1, 2, 4, 6, 8, 10]
a_loc[nonhp_agents] = vcat(repeat(reverse(Vector([3, 5, 7, 9, 11])),6)...)[1:(length(nonhp_agents))]
ag_loc = [a_loc; g_loc]

# agents present at certain node
Iₙ = Dict()
for n in 1:dhn.nₙ
   Iₙ[n] = findall(a_loc .== n) # vector with id nr of prosumers that are at node n
end

#--- make w̃_ij
w̃_ij = zeros(n_a+1, n_a+1)
for i in 1:(n_a+1), j in 1:(n_a+1)
    w̃_ij[i,j] = (Tˢ[ag_loc[i]] - Tᴿ[ag_loc[i]])/(Tˢ[ag_loc[j]] - Tᴿ[ag_loc[j]])
end
w̃_gi = w̃_ij[n_a+1,:]

# define loss per node
w̃_nm = zeros(dhn.nₙ, dhn.nₙ)
for n in 1:dhn.nₙ, m in 1:dhn.nₙ
    w̃_nm[n,m] = (Tˢ[n] - Tᴿ[n])/(Tˢ[m] - Tᴿ[m])
end
