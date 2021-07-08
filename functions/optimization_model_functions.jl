#=
Functions to build up the market models. 
=#


function add_consumer_fixedLoad_constraints(m::JuMP.Model)
    # vars agents
    @expression(m, Lᴴ[i=1:n_a, t=1:n_t], DHW[i,t] + SH_ref[i,t])
    @variable(m, G̅ᴴ[i] >= Gᴴ[i=1:n_a, 1:n_t] >= 0)     # heat injection by prosumer/grid
    @variable(m, Lᴱhp[i=1:n_a, 1:n_t])
    @variable(m, Pᴴ[1:n_a, 1:n_t])

    # injection equals generation minus load
    @constraint(m, Pinj[i=1:n_a,t=1:n_t], Pᴴ[i,t] == Gᴴ[i,t] - Lᴴ[i,t])
    # generation comes from HP
    @constraint(m, HPgen[i=1:n_a,t=1:n_t], Gᴴ[i,t] == cop[i]*Lᴱhp[i,t])

    @expression(m, u_t_fun[i=1:n_a,t=1:n_t], 0.0)
    return m
end

function add_consumer_flex_constraints(m::JuMP.Model)
    # vars agents
    @variable(m, Lᴴ[i=1:n_a, 1:n_t] >= 0)
    @variable(m, SHᵢ[1:n_a, 1:n_t] >= 0)
    # @variable(m, Tmin[i] <= Tᵢ[i=1:n_a, 1:n_t] <= Tmax[i])
    @variable(m, G̅ᴴ[i] >= Gᴴ[i=1:n_a, 1:n_t] >= 0)     # heat injection by prosumer/grid
    @variable(m, Lᴱhp[i=1:n_a, 1:n_t])
    @variable(m, Pᴴ[1:n_a, 1:n_t])

    # injection equals generation minus load
    @constraint(m, Pinj[i=1:n_a,t=1:n_t], Pᴴ[i,t] == Gᴴ[i,t] - Lᴴ[i,t])
    # load consists of DHW and SH
    @constraint(m, totalLoad[i=1:n_a,t=1:n_t], Lᴴ[i,t] == SHᵢ[i,t]+ DHW[i,t])
    # generation comes from HP
    @constraint(m, HPgen[i=1:n_a,t=1:n_t], Gᴴ[i,t] == cop[i]*Lᴱhp[i,t])

    # SPACE HEATING flex limits for prosumers
    ΔL = maximum(SH_ref, dims=2)* 0.1 # 10% of max cons. is flex.
    @constraint(m, fLimLB[i=1:n_a, t=1:n_t],
        SH_ref[i,t] - ΔL[i] <= SHᵢ[i,t])
    @constraint(m, fLimUB[i=1:n_a, t=1:n_t],
        SH_ref[i,t] + ΔL[i] >= SHᵢ[i,t])

    # utility fun for deviation from PROFILE
    @expression(m, SH_deviation[i=1:n_a, t=1:n_t], SHᵢ[i,t] - SH_ref[i,t])
    @expression(m, u_t_fun[i=1:n_a,t=1:n_t], - u_t[i,t]*SH_deviation[i,t]^2)
    return m
end

function add_energy_budget(m)
    @constraint(m, budget[i=1:n_a], sum(m[:SHᵢ][i,:]) == sum(SH_ref[i,:]))
    return m
end

################################################################################
# DLG
################################################################################
function DLG_aware_pool(m)
    # add_grid_connection(m)
    @variable(m, Pᴴ_g[1:n_t])  # grid connection power injection.
    @variable(m, Lᴴ_g[1:n_t] >= 0)
    @variable(m, Gᴴ_g[1:n_t] >= 0)
    # pipe flow - onedirectional in pipes
    @variable(m, m̅̇[p] >= ṁˢ[p=1:dhn.nₚ,1:n_t] >= 0)
    # nodal flow - positive is from supply to return side
    @variable(m, ṁᴺ[1:dhn.nₙ, 1:n_t])

    # grid agent constraint
    @constraint(m, Pinj_g[t=1:n_t], Pᴴ_g[t] == Gᴴ_g[t] - Lᴴ_g[t])

    # Network # VARIABLES

    # compute total power injection at each node
    @expression(m, P_node[n=1:dhn.nₙ,t=1:n_t],
                sum(m[:Pᴴ][i,t] for i in Iₙ[n]) +
                sum(Pᴴ_g[t] for b=1 if n==g_loc))

    # Network CONSTRAINTS
    # continuity of flow
    @constraint(m, flow_continuity[n=1:dhn.nₙ,t=1:n_t],
        sum(ṁˢ[p,t] for p in dhn.Sₙ⁻[n]) -
        sum(ṁˢ[p,t] for p in dhn.Sₙ⁺[n]) == ṁᴺ[n,t])
    # nodal heat exchanger
    @constraint(m, powerinj[n=1:dhn.nₙ,t=1:n_t],
        P_node[n,t] == - cf * ṁᴺ[n,t]*(Tˢ[n] - Tᴿ[n]))

    # OBJFUN
    @expression(m, gen_loss_agent[i=findall(cop .!= 0),t=1:n_t],
                (1/cop[i]) * m[:Gᴴ][i,t])
    @expression(m, c_gen_agents[i=findall(cop .!= 0),t=1:n_t],
                gen_loss_agent[i,t]*ciᵍᴱ[t])
    #@expression(m, c_gen_agents[i=1:n_a,t=1:n_t], m[:Lᴱhp][i,t] * ciᵍᴱ[t])
    @expression(m, c_gen_grid[t=1:n_t], m[:Gᴴ_g][t]*ciᵍᴴ[t])
    @expression(m, objfun, sum(sum(c_gen_agents)) - scale_util*sum(sum(m[:u_t_fun]))
        + sum(c_gen_grid))
    @objective(m, Min, objfun)
    return m
end



function DLG_aware_add_p2p(m)
    m = DLG_aware_pool(m)
    # trade between agents. positive if selling
    # let grid agent by agent nr n_a + 1
    @variable(m, Tᴴ[1:(n_a+1), 1:(n_a+1), 1:n_t])
    # selling trades
    @variable(m, Sᴴ[1:(n_a+1), 1:(n_a+1), 1:n_t] >= 0)
    # buying trades
    @variable(m, Bᴴ[1:(n_a+1), 1:(n_a+1), 1:n_t] >= 0)
    # loss positive
    @variable(m, w_ij[1:(n_a+1),1:(n_a+1),1:n_t] >= 0)

    # constraints
    @constraint(m, net_trade[i=1:(n_a+1),j=1:(n_a+1),t=1:n_t],
        Tᴴ[i,j,t] == Sᴴ[i,j,t] - Bᴴ[i,j,t])
    # trade reciprocity
    @constraint(m, BSopposition[i=1:(n_a+1),j=1:(n_a+1),t=1:n_t],
        Bᴴ[i,j,t] == Sᴴ[j,i,t])
    #
    @constraint(m, restrict_buys[i=1:n_a, t=1:n_t],
        sum(Bᴴ[i,:,t]) == m[:Lᴴ][i,t])
    @constraint(m, restrict_buys_g[t=1:n_t],
        sum(Bᴴ[n_a+1,:,t]) == m[:Lᴴ_g][t])
    @constraint(m, restrict_sale[i=1:n_a, t=1:n_t],
        sum(Sᴴ[i,:,t] + w_ij[i,:,t]) == m[:Gᴴ][i,t])
    @constraint(m, restrict_sale_g[t=1:n_t],
        sum(Sᴴ[n_a+1,:,t] + w_ij[n_a+1,:,t]) == m[:Gᴴ_g][t])

    # loss allocated to the producer of the trade (so if S zero, no loss)
    @constraint(m, set_loss_ij[i=1:(n_a+1), j=1:(n_a+1),t=1:n_t],
       w_ij[i,j,t] == (w̃_ij[i,j] - 1) * Sᴴ[i,j,t]) # if sell, produce loss

    #
    return m
end

################################################################################
# CLG
################################################################################

function CLG_awa_ign_p2p(m::JuMP.Model; loss_aware)
    # add_grid_connection(m)
    @variable(m, Pᴴ_g[1:n_t])  # grid connection power injection.
    @variable(m, Lᴴ_g[1:n_t] >= 0)
    @variable(m, Gᴴ_g[1:n_t] >= 0)

    # grid agent constraint
    @constraint(m, Pinj_g[t=1:n_t], Pᴴ_g[t] == Gᴴ_g[t] - Lᴴ_g[t])
    # trade between agents. positive if selling
    # let grid agent by agent nr n_a + 1
    @variable(m, Tᴴ[1:(n_a+1), 1:(n_a+1), 1:n_t])
    # selling trades
    @variable(m, Sᴴ[1:(n_a+1), 1:(n_a+1), 1:n_t] >= 0)
    # buying trades
    @variable(m, Bᴴ[1:(n_a+1), 1:(n_a+1), 1:n_t] >= 0)
    # loss positive
    @variable(m, w_ij[1:(n_a+1),1:(n_a+1),1:n_t] >= 0)

    # constraints
    @constraint(m, net_trade[i=1:(n_a+1),j=1:(n_a+1),t=1:n_t],
        Tᴴ[i,j,t] == Sᴴ[i,j,t] - Bᴴ[i,j,t])
    @constraint(m, BSopposition[i=1:(n_a+1),j=1:(n_a+1),t=1:n_t],
        Bᴴ[i,j,t] == Sᴴ[j,i,t])


    # loss allocated to the producer of the trade (so if S zero, no loss)
    @constraint(m, set_loss_ij[i=1:(n_a+1), j=1:(n_a+1),t=1:n_t],
       w_ij[i,j,t] == w̃_gi[i]*(w̃_ij[i,j] - 1) * Sᴴ[i,j,t])
    @variable(m, w_i[1:n_a,1:n_t] >= 0)

    # hard restrict ...
    @constraint(m, restrict_buys[i=1:n_a, t=1:n_t],
        sum(Bᴴ[i,:,t]) == m[:Lᴴ][i,t])
    @constraint(m, restrict_buys_g[t=1:n_t],
        sum(Bᴴ[n_a+1,:,t]) == 0)
    # @constraint(m, restrict_sale_g[t=1:n_t],
    #     sum(Sᴴ[n_a+1,:,t]) + sum(w_i[:,t]) .== m[:Gᴴ_g][t])
    @constraint(m, restrict_sale[i=1:n_a, t=1:n_t],
        sum(Sᴴ[i,:,t]) == m[:Gᴴ][i,t])
    @constraint(m, restrict_sale_g[t=1:n_t],
        sum(Sᴴ[n_a+1,:,t]) + sum(w_ij[:,:,t]) == m[:Gᴴ_g][t])

    # compute total power injection at each node
    @expression(m, P_node[n=1:dhn.nₙ,t=1:n_t],
                sum(m[:Pᴴ][i,t] for i in Iₙ[n]) +
                sum(m[:Pᴴ_g][t] for i=1 if n==g_loc))
    # VARIABLES
    # pipe flow - onedirectional in pipes
    @variable(m, m̅̇[p] >= ṁˢ[p=1:dhn.nₚ,1:n_t] >= 0)
    # nodal flow - positive is from supply to return side
    @variable(m, ṁᴺ[1:dhn.nₙ, 1:n_t])

    # CONSTRAINTS
    # continuity of flow
    @constraint(m, flow_continuity[n=1:dhn.nₙ,t=1:n_t],
        sum(ṁˢ[p,t] for p in dhn.Sₙ⁻[n]) -
        sum(ṁˢ[p,t] for p in dhn.Sₙ⁺[n]) == ṁᴺ[n,t])
    # common constraints
    # nodal heat exchanger
    @constraint(m, powerinj[n=1:dhn.nₙ,t=1:n_t],
        P_node[n,t] == - cf * ṁᴺ[n,t]*(Tˢ[n] - Tᴿ[n]))

    # OBJFUN
    @expression(m, gen_loss_agent[i=findall(cop .!= 0),t=1:n_t],
                (1/cop[i]) * m[:Gᴴ][i,t])
    @expression(m, c_gen_agents[i=findall(cop .!= 0),t=1:n_t],
                gen_loss_agent[i,t]*ciᵍᴱ[t])
    if loss_aware
        # import costs heat
        @expression(m, c_gen_grid[t=1:n_t], m[:Gᴴ_g][t]*ciᵍᴴ[t])
    else
        @expression(m, c_gen_grid[t=1:n_t], (m[:Gᴴ_g][t] - sum(w_ij[:,:,t]))*ciᵍᴴ[t])
    end
    @expression(m, objfun, sum(sum(c_gen_agents)) - scale_util*sum(sum(m[:u_t_fun]))
        + sum(c_gen_grid))
    @objective(m, Min, objfun)
    return m
end


function CLG_awa_ign_pool(m::JuMP.Model; loss_aware::Bool)
    # add_grid_connection(m)
    @variable(m, Pᴴ_g[1:n_t])  # grid connection power injection.
    @variable(m, Lᴴ_g[1:n_t] >= 0)
    @variable(m, Gᴴ_g[1:n_t] >= 0)

    # grid agent constraint
    @constraint(m, Pinj_g[t=1:n_t], Pᴴ_g[t] == Gᴴ_g[t] - Lᴴ_g[t])
    # loss positive
    @variable(m, w[1:n_t] >= 0)
    @variable(m, G_g_noloss[1:n_t] >= 0)
    # grid produces losses
    @constraint(m, setG_g[t=1:n_t], Gᴴ_g[t] == G_g_noloss[t] + w[t])
    # power balance without losses
    @constraint(m, powerB_noloss[t=1:n_t],
        G_g_noloss[t] + sum(m[:Gᴴ][i,t] for i in 1:n_a) ==
            sum(m[:Lᴴ][i,t] for i in 1:n_a))

    # compute total power injection at each node
    @expression(m, P_node[n=1:dhn.nₙ,t=1:n_t],
                sum(m[:Pᴴ][i,t] for i in Iₙ[n]) +
                sum(m[:Pᴴ_g][t] for i=1 if n==g_loc))
    # VARIABLES
    # pipe flow - onedirectional in pipes
    @variable(m, m̅̇[p] >= ṁˢ[p=1:dhn.nₚ,1:n_t] >= 0)
    # nodal flow - positive is from supply to return side
    @variable(m, ṁᴺ[1:dhn.nₙ, 1:n_t])

    # CONSTRAINTS
    # continuity of flow
    @constraint(m, flow_continuity[n=1:dhn.nₙ,t=1:n_t],
        sum(ṁˢ[p,t] for p in dhn.Sₙ⁻[n]) -
        sum(ṁˢ[p,t] for p in dhn.Sₙ⁺[n]) == ṁᴺ[n,t])
    # common constraints
    # nodal heat exchanger
    @constraint(m, powerinj[n=1:dhn.nₙ,t=1:n_t],
        P_node[n,t] == - cf * ṁᴺ[n,t]*(Tˢ[n] - Tᴿ[n]))

    # generation costs for agents
    @expression(m, gen_loss_agent[i=findall(cop .!= 0),t=1:n_t],
                (1/cop[i]) * m[:Gᴴ][i,t])
    @expression(m, c_gen_agents[i=findall(cop .!= 0),t=1:n_t],
                gen_loss_agent[i,t]*ciᵍᴱ[t])

    if loss_aware
        @expression(m, c_gen_grid[t=1:n_t], m[:Gᴴ_g][t]*ciᵍᴴ[t])
    else
        # import costs heat
        @expression(m, c_gen_grid[t=1:n_t], m[:G_g_noloss][t]*ciᵍᴴ[t])
    end
    # objfun cost - utility of agents, plus cost from import
    @expression(m, objfun, sum(sum(c_gen_agents)) - scale_util*sum(sum(m[:u_t_fun]))
            + sum(c_gen_grid))
    @objective(m, Min, objfun)
    return m
end
