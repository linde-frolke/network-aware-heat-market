#=
General useful functions
=#
using ColorSchemes

# plot help functions
function my_colmap(n; cs=:thermal, rev=false)
    colrs = [cgrad(cs, [0.01, 0.99],rev=rev)[z]
                    for z ∈ range(0.0, 1.0, length = n)]
    colmat = reshape(colrs, 1, n)
    return colmat
end
