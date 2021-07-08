# data from Liu2016Combined
using DataFrames

struct DHN
    nₙ::Int64                   # number of heat nodes
    n1::Array{Int64,1}          # starting node for each pipe
    n2::Array{Int64,1}          # end node for each pipe
    nₚ::Int64                   # number of pipes
    Lₚ::Array{Float64,1}        # pipe length
    Rₚ::Array{Float64,1}        # pipe radius

    ## incoming/outgoing pipes pernode
    Sₙ⁺::Dict
    Sₙ⁻::Dict
end

function get_network_inputs()
    colnames = ["p_nr", "from", "to", "L_m", "D_mm", "HTC_W/mK", "Rough_mm"]
    data = reshape([01, 01, 02, 257.6, 125, 0.321, 0.4,
                    02, 02, 03, 97.5, 40, 0.21, 0.4,
                    03, 02, 04, 51, 40, 0.21, 0.4,
                    04, 02, 05, 59.5, 100, 0.327, 0.4,
                    05, 05, 06, 271.3, 32, 0.189, 0.4,
                    06, 05, 07, 235.4, 65, 0.236, 0.4,
                    07, 07, 08, 177.3, 40, 0.21, 0.4,
                    08, 07, 09, 102.8, 40, 0.21, 0.4,
                    09, 07, 10, 247.7, 40, 0.21, 0.4,
                    10, 05, 11, 160.8, 100, 0.327, 0.4,
                    11, 11, 12, 129.1, 40, 0.21, 0.4,
                    12, 11, 13, 186.1, 100, 0.327, 0.4,
                    13, 13, 14, 136.2, 80, 0.278, 0.4,
                    14, 14, 15, 41.8, 50, 0.219, 0.4,
                    15, 15, 16, 116.8, 32, 0.189, 0.4,
                    16, 15, 17, 136.4, 32, 0.189, 0.4,
                    17, 14, 18, 136.4, 32, 0.189, 0.4,
                    18, 14, 19, 44.9, 80, 0.278, 0.4,
                    19, 19, 20, 136.4, 32, 0.189, 0.4,
                    20, 19, 21, 134.1, 32, 0.189, 0.4,
                    21, 19, 22, 41.7, 65, 0.236, 0.4,
                    22, 22, 23, 161.1, 32, 0.189, 0.4,
                    23, 22, 24, 134.2, 32, 0.189, 0.4,
                    24, 22, 25, 52.1, 65, 0.236, 0.4,
                    25, 25, 26, 136, 32, 0.189, 0.4,
                    26, 25, 27, 123.3, 32, 0.189, 0.4,
                    27, 25, 28, 61.8, 40, 0.21, 0.4,
                    28, 28, 29, 95.2, 32, 0.189, 0.4,
                    29, 28, 30, 105.1, 32, 0.189, 0.4,
                    30, 31, 28, 70.6, 125, 0.321, 0.4,
                    31, 31, 7, 261.8, 125, 0.321, 0.4,
                    32, 32, 11, 201.3, 125, 0.321, 0.4], (7, 32))
    data = transpose(data)
    network = DataFrame(data, :auto)
    DataFrames.rename!(network, colnames)


    # select smaller system
    pipes = [1,4,10,12, 13, 18, 21,24,27,30]
    nodes = [1,2,5,11,13,14, 19, 22, 25, 28, 31]
    small_dhn = network[pipes, :]
    small_dhn.from[10] = 28  # reverse flow in last pipe.
    small_dhn.to[10] = 31

    # rename nodes
    nodesnew = Vector(1:length(nodes))

    for n in nodes
        index = nodesnew[nodes .== n][1]
        if length(findall(small_dhn.from .== n)) > 0
            small_dhn.from[findfirst(small_dhn.from .== n)] = Int(index)
        end
        if length(findall(small_dhn.to .== n)) > 0
            small_dhn.to[findfirst(small_dhn.to .== n)] = Int(index)
        end
    end

    small_dhn.p_nr = Vector(1:length(pipes))
    network = small_dhn

    # pipe/DHN data --------------------------------------------------------------
    nₙ = max(maximum(network.from[:,1]), maximum(network.to[:,1]))
    n1 = network.from
    n2 = network.to
    startstop = hcat(n1, n2)      #  number of heat nodes
    nₚ = length(network.p_nr)          # number of pipes
    Lₚ = network.L_m   # pipe length
    Rₚ = (network.D_mm/2)/1000   # pipe radius
    #
    Sₙ⁺ = Dict()
    Sₙ⁻ = Dict()
    for n in 1:nₙ
        Sₙ⁺[n] = network.p_nr[startstop[:, 1] .== n]
        Sₙ⁻[n] = network.p_nr[startstop[:, 2] .== n]
    end
    dhn = DHN(nₙ, n1, n2, nₚ, Lₚ, Rₚ, Sₙ⁺, Sₙ⁻)
    return dhn
end
