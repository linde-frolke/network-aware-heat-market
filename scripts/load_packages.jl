Pkg.activate("network-aware-market")
using Gurobi
using JuMP
using Plots
using Random
using Distributions
using DelimitedFiles
# using Statistics
# import StatsPlots.groupedbar
# using CategoricalArrays
# import Permutations.RandomPermutation
# include("../functions/pu_DHN.jl")
include("functions/eval_optim_outcome.jl")
include("functions/optimization_model_functions.jl")
