#=
compute quantities needed for figures as in article
=#

# fit models and compute LMPs
include("../functions/loss-allocation.jl")
# include("article_dual_relations.jl")

#--- the models and model names
models = [m_DLG_awa_p2p_flex, m_CLG_awa_p2p_flex, m_CLG_ign_p2p_flex]
model_names = ["loss-aware DLG", "loss-aware CLG", "loss-ignorant CLG"]


#--- compuate LMPs
# m_DLG_awa_p2p_flex
mod_ = m_DLG_awa_p2p_flex
L_is_nonzero = value.(mod_[:Lᴴ]) .> 0.01
mu_B = dual.(mod_[:restrict_buys])
mu_inj = dual.(mod_[:Pinj])
AMP_DLG_awa_p2p_flex_buy = (mu_B .- mu_inj) .* L_is_nonzero
mu_S = dual.(mod_[:restrict_sale])
G_is_nonzero = value.(mod_[:Gᴴ]) .> 0.01
AMP_DLG_awa_p2p_flex_sale =  (-mu_inj .- mu_S) .* G_is_nonzero

# CLG awa flex
mod_ = m_CLG_awa_p2p_flex
L_is_nonzero = value.(mod_[:Lᴴ]) .> 0.01
mu_B = dual.(mod_[:restrict_buys])
mu_inj = dual.(mod_[:Pinj])
AMP_CLG_awa_p2p_flex_buy = (mu_B .- mu_inj) .* L_is_nonzero
mu_S = dual.(mod_[:restrict_sale])
G_is_nonzero = value.(mod_[:Gᴴ]) .> 0.01
AMP_CLG_awa_p2p_flex_sale =  (-mu_inj .- mu_S) .* G_is_nonzero

# CLG ign flex
mod_ = m_CLG_ign_p2p_flex
L_is_nonzero = value.(mod_[:Lᴴ]) .> 0.01
mu_B = dual.(mod_[:restrict_buys])
mu_inj = dual.(mod_[:Pinj])
AMP_CLG_ign_p2p_flex_buy = (mu_B .- mu_inj) .* L_is_nonzero
mu_S = dual.(mod_[:restrict_sale])
G_is_nonzero = value.(mod_[:Gᴴ]) .> 0.01
AMP_CLG_ign_p2p_flex_sale =  (-mu_inj .- mu_S) .* G_is_nonzero

# convert to NODAL marginal price (LMP)
LMP_DLG_awa_p2p_flex = zeros(dhn.nₙ, n_t)
LMP_CLG_awa_p2p_flex = zeros(dhn.nₙ, n_t)
LMP_CLG_ign_p2p_flex = zeros(dhn.nₙ, n_t)
for n in 1:dhn.nₙ
    for t in 1:n_t
        # DLG awa
        Bmaxi = maximum(AMP_DLG_awa_p2p_flex_buy[Iₙ[n],t])
        Smaxi = maximum(AMP_DLG_awa_p2p_flex_sale[Iₙ[n],t])
        LMP_DLG_awa_p2p_flex[n,t] = max(Bmaxi, Smaxi)
        # CLG awa
        Bmaxi = maximum(AMP_CLG_awa_p2p_flex_buy[Iₙ[n],t])
        Smaxi = maximum(AMP_CLG_awa_p2p_flex_sale[Iₙ[n],t])
        LMP_CLG_awa_p2p_flex[n,t] = max(Bmaxi, Smaxi)
        # CLG ign
        Bmaxi = maximum(AMP_CLG_ign_p2p_flex_buy[Iₙ[n],t])
        Smaxi = maximum(AMP_CLG_ign_p2p_flex_sale[Iₙ[n],t])
        LMP_CLG_ign_p2p_flex[n,t] = max(Bmaxi, Smaxi)
    end
end

# #--- CLG extra costs for losses
# CLG_ign_loss_costs = [value.(m_CLG_ign_p2p_flex[:w_ij])[:,:,t] * ciᵍᴴ[t] for t in 1:n_t]
# CLG_ign_loss_costs_tot = sum(sum(CLG_ign_loss_costs))
# CLG_awa_loss_costs = [value.(m_CLG_awa_p2p_flex[:w_ij])[:,:,t] * ciᵍᴴ[t] for t in 1:n_t]
# CLG_awa_loss_costs_tot = sum(sum(CLG_awa_loss_costs))
# -------------------


#--- total nodal scheduled generation
nodal_total_gen =
    hcat([[sum(value.(mod[:Gᴴ])[Iₙ[n], :], dims=[1,2])[1,1] for n in 1:dhn.nₙ]
         for mod in models]...)
nodal_total_consumed_gen =
    hcat([[sum(value.(mod[:Sᴴ])[Iₙ[n],:, :]) for n in 1:dhn.nₙ]
         for mod in models]...)

# include grid agent
grid_gen = [sum(value.(m[:Gᴴ_g])) for m in models]
grid_consumed_gen = [sum(value.(m[:Sᴴ])[n_a+1,:,:]) for m in models]
nodal_total_gen_g = vcat(Array(grid_gen)', nodal_total_gen)
nodal_total_consumed_gen_g = vcat(Array(grid_consumed_gen)', nodal_total_consumed_gen)

# losses CLG
DLG_awa_loss_tot = [sum(value.(m_DLG_awa_p2p_flex[:w_ij])[:,:,t]) for t in 1:n_t]
CLG_awa_loss_tot = [sum(value.(m_CLG_awa_p2p_flex[:w_ij])[:,:,t]) for t in 1:n_t]
CLG_ign_loss_tot = [sum(value.(m_CLG_ign_p2p_flex[:w_ij])[:,:,t]) for t in 1:n_t]

#
# selfcons_DLG_awa = hcat([sum(value.(m_DLG_awa_p2p_flex[:Sᴴ][i,i, :]) for i in Iₙ[n])
#                         for n in 1:dhn.nₙ]...)
# selfcons_CLG_awa = hcat([sum(value.(m_CLG_awa_p2p_flex[:Sᴴ][i,i, :]) for i in Iₙ[n])
#                         for n in 1:dhn.nₙ]...)
# selfcons_CLG_ign = hcat([sum(value.(m_CLG_ign_p2p_flex[:Sᴴ][i,i, :]) for i in Iₙ[n])
#                         for n in 1:dhn.nₙ]...)
## revenues and payments
# for DLG awa
# node_rev_pu_DLG_awa = revenues_pu(model=m_DLG_awa_p2p_flex,
#                         LMPs=LMP_DLG_awa_p2p_flex)
# grid_rev_pu_DLG_awa = sum(LMP_DLG_awa_p2p_flex[g_loc,t]*
#                         value.(m_DLG_awa_p2p_flex[:Gᴴ_g][t]) for t in 1:n_t) ./
#                         sum(value.(m_DLG_awa_p2p_flex[:Gᴴ_g]))
node_pay_pu_DLG_awa = payments_pu_individual_LAP(model=m_DLG_awa_p2p_flex,
                        LMPs=LMP_DLG_awa_p2p_flex)
# compute socialized payments
node_pay_DLG_soc_LAP = payments_DLG_socialized_LAP(model=m_DLG_awa_p2p_flex,
                            LMPs=LMP_DLG_awa_p2p_flex)
node_pay_pu_DLG_soc_LAP = node_pay_DLG_soc_LAP ./
                [sum(value.(m_DLG_awa_p2p_flex[:Lᴴ][Iₙ[n],:])) for n in 1:dhn.nₙ]
# for CLG awa ----------------------
# node_rev_pu_CLG_awa = revenues_pu(model=m_CLG_awa_p2p_flex,
#                         LMPs=LMP_CLG_awa_p2p_flex)
# grid_rev_pu_CLG_awa = sum(LMP_CLG_awa_p2p_flex[g_loc,t] *
#                         value.(m_CLG_awa_p2p_flex[:Gᴴ_g][t]) for t in 1:n_t) ./
#                         sum(value.(m_CLG_awa_p2p_flex[:Gᴴ_g]))
node_pay_pu_CLG_awa = payments_pu_individual_LAP(model=m_CLG_awa_p2p_flex,
                        LMPs=LMP_CLG_awa_p2p_flex)
# compute socialized payments
node_pay_CLG_awa_soc_LAP = payments_CLG_socialized_LAP(model=m_CLG_awa_p2p_flex,
                            LMPs=LMP_CLG_awa_p2p_flex)
node_pay_pu_CLG_awa_soc_LAP = node_pay_CLG_awa_soc_LAP ./
                [sum(value.(m_CLG_awa_p2p_flex[:Lᴴ][Iₙ[n],:])) for n in 1:dhn.nₙ]


# for CLG ign -----------------------
# node_rev_pu_CLG_ign = revenues_pu(model=m_CLG_ign_p2p_flex,
#                         LMPs=LMP_CLG_ign_p2p_flex)
# grid_rev_pu_CLG_ign = sum(LMP_CLG_ign_p2p_flex[g_loc,t] *
#                         value.(m_CLG_ign_p2p_flex[:Gᴴ_g][t]) for t in 1:n_t)./
#                         sum(value.(m_CLG_ign_p2p_flex[:Gᴴ_g]))
                        # note that this includes loss production!
# add cost of loss production
node_pay_pu_CLG_ign = payments_pu_individual_LAP(model=m_CLG_ign_p2p_flex,
                        LMPs=LMP_CLG_ign_p2p_flex, loss_aware=false)

# compute socialized payments
node_pay_CLG_ign_soc_LAP = payments_CLG_socialized_LAP(model=m_CLG_ign_p2p_flex,
                            LMPs=LMP_CLG_ign_p2p_flex)
node_pay_pu_CLG_ign_soc_LAP = node_pay_CLG_ign_soc_LAP ./
                [sum(value.(m_CLG_ign_p2p_flex[:Lᴴ][Iₙ[n],:])) for n in 1:dhn.nₙ]


## percentage increase in costs
total_costs = [value.(sum(sum(mod[:c_gen_agents]))) .+
            value.(sum(sum(mod[:c_gen_grid]))) for mod in models] ./ 10^6
ign_loss_cost = sum(sum(value.(m_CLG_ign_p2p_flex[:w_ij])[:,:,t]) *
                    ciᵍᴴ[t] for t in 1:n_t) ./ 10^6

print("total costs = $(round.(total_costs[3] + ign_loss_cost, digits=2)) & $(
    round.(total_costs[2], digits=2)) & $(
    round.(total_costs[1], digits=2)) \\\\ ")


c_prcnt_decrease = round.(100*[(total_costs[3] + ign_loss_cost - total_costs[2]),
            (total_costs[3] + ign_loss_cost - total_costs[1])]./
            (total_costs[3] + ign_loss_cost), digits=2)
print("cost % decrease is $(c_prcnt_decrease[1]) \\% & $(c_prcnt_decrease[2]) \\% \\\\")


## precentage increase in total loss
total_loss = round.([sum(value.(mod[:w_ij])) for mod in models] ./ 1000, digits=2)
txt_total_loss = "$(reverse(total_loss)[1]) & $(reverse(total_loss)[2]) & $(reverse(total_loss)[3]) \\\\"
print("total loss = $(txt_total_loss)")
prcnt_decrease = round.(100*[(total_loss[3] - total_loss[2]), (total_loss[3] - total_loss[1])]./total_loss[3], digits=2)
print("loss % decrease is $(prcnt_decrease[1]) \\% & $(prcnt_decrease[2]) \\% \\\\")
