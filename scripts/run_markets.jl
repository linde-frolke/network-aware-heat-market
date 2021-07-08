#=
script to fit the different models used in the article
This can be run alone
=#

Pkg.activate("network-aware-heat-market/")
using JuMP
using Gurobi

include("../functions/optimization_model_functions.jl")
include("../functions/eval_optim_outcome.jl")

#--- load input data, depending on case
case = 2
compare_to_pool = false

include("load_parameters.jl")
if case == 2
    # convert to case II by reverting the COPs.
    cop[hp_agents] = [mean_cop - i*0.05 for i in 1:length(hp_agents)] .* (163.02 ./ 524 ) .* 2.5
end

#---- loss-aware DLG
if compare_to_pool
    m_DLG_awa_pool_flex = Model(Gurobi.Optimizer)
    add_consumer_flex_constraints(m_DLG_awa_pool_flex)
    DLG_aware_pool(m_DLG_awa_pool_flex)
    m_DLG_awa_pool_flex = add_energy_budget(m_DLG_awa_pool_flex)
    optimize!(m_DLG_awa_pool_flex)
    eval_optim_outcome(m_DLG_awa_pool_flex)
end

# p2p
m_DLG_awa_p2p_flex = Model(Gurobi.Optimizer)
add_consumer_flex_constraints(m_DLG_awa_p2p_flex)
m_DLG_awa_p2p_flex = add_energy_budget(m_DLG_awa_p2p_flex)
DLG_aware_add_p2p(m_DLG_awa_p2p_flex)
optimize!(m_DLG_awa_p2p_flex)
eval_optim_outcome(m_DLG_awa_p2p_flex)


#--- loss-aware CLG
if compare_to_pool
    m_CLG_awa_pool_flex = Model(Gurobi.Optimizer)
    m_CLG_awa_pool_flex = add_consumer_flex_constraints(m_CLG_awa_pool_flex)
    m_CLG_awa_pool_flex = add_energy_budget(m_CLG_awa_pool_flex)
    m_CLG_awa_pool_flex = CLG_awa_ign_pool(m_CLG_awa_pool_flex, loss_aware=true)
    set_optimizer(m_CLG_awa_pool_flex, Gurobi.Optimizer)
    optimize!(m_CLG_awa_pool_flex)
    eval_optim_outcome(m_CLG_awa_pool_flex)
end
# p2p
m_CLG_awa_p2p_flex = Model(Gurobi.Optimizer)
m_CLG_awa_p2p_flex = add_consumer_flex_constraints(m_CLG_awa_p2p_flex)
m_CLG_awa_p2p_flex = CLG_awa_ign_p2p(m_CLG_awa_p2p_flex, loss_aware=true)
m_CLG_awa_p2p_flex = add_energy_budget(m_CLG_awa_p2p_flex)
optimize!(m_CLG_awa_p2p_flex)
eval_optim_outcome(m_CLG_awa_p2p_flex)

#--- loss-ignorant CLG
m_CLG_ign_p2p_flex = Model(Gurobi.Optimizer)
m_CLG_ign_p2p_flex = add_consumer_flex_constraints(m_CLG_ign_p2p_flex)
m_CLG_ign_p2p_flex = CLG_awa_ign_p2p(m_CLG_ign_p2p_flex, loss_aware=false)
m_CLG_ign_p2p_flex = add_energy_budget(m_CLG_ign_p2p_flex)
optimize!(m_CLG_ign_p2p_flex)
eval_optim_outcome(m_CLG_ign_p2p_flex)
