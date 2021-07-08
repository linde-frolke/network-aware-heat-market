# setting up environment for the package
Pkg.activate("network-aware-heat-market")

# add the needed modules
Pkg.add(["JuMP", "Gurobi", "Random", "Distributions", "DataFrames", "PyPlot",
         "ColorSchemes", "Plots", "Colors"])
