# functions to compute payments and revenues
using JuMP

# individual -----
function payments_pu_individual_LAP(;model::JuMP.Model, LMPs, loss_aware=true)
    # return total price per consumed unit
    agent_pay = zeros(n_a, n_t)
    for i in 1:n_a
        agent_pay[i,:] = [LMPs[a_loc[i],t]*
                                value.(model[:Lᴴ][i,t]) for t in 1:n_t]
    end
    if loss_aware == false
        for i in 1:n_a
            agent_pay[i,:] += [LMPs[g_loc,t]*
                                    sum(value.(model[:w_ij][:,i,t])) for t in 1:n_t]
        end
    end

    node_pay = [sum(agent_pay[Iₙ[n],:]) for n in 1:dhn.nₙ]
    node_pay_pu = node_pay ./ [sum(value.(model[:Lᴴ][Iₙ[n],:])) for n in 1:dhn.nₙ]

    return node_pay_pu
end

function payments_pu_avg(;model::JuMP.Model, LMPs, loss_aware=true)
    # return total price per consumed unit
    agent_pay = zeros(n_a, n_t)
    for i in 1:n_a
        agent_pay[i,:] = [LMPs[a_loc[i],t]*
                                value.(model[:Lᴴ][i,t]) for t in 1:n_t]
    end
    if loss_aware == false
        for i in 1:n_a
            agent_pay[i,:] += [LMPs[g_loc,t]*
                                    sum(value.(model[:w_ij][:,i,t])) for t in 1:n_t]
        end
    end
    avg_pay_pu = sum(agent_pay[:,:]) / sum(value.(model[:Lᴴ]))

    return avg_pay_pu
end

function revenues_pu(;model::JuMP.Model, LMPs)
    # return total price per consumed unit
    agent_rev = zeros(n_a, n_t)
    for i in 1:n_a
        agent_rev[i,:] = [LMPs[a_loc[i],t]*
                                value.(model[:Gᴴ][i,t]) for t in 1:n_t]
    end
    node_rev = [sum(agent_rev[Iₙ[n],:]) for n in 1:dhn.nₙ]
    node_rev_pu = node_rev ./ [sum(value.(model[:Gᴴ][Iₙ[n],:])) for n in 1:dhn.nₙ]
    return node_rev_pu
end

# socialized ----
function payments_DLG_socialized_LAP(;model, LMPs)
    # return total payments for each node if losses are socialized
    price_loss_pu = sum(sum(sum(value.(model[:w_ij][i,:,t])) *
                  LMPs[ag_loc[i],t] for i in 1:(n_a+1)) for t in 1:n_t) /
                  sum(value.(model[:Lᴴ]))
    price_consumed_pu = [sum(sum(value.(model[:Bᴴ][i,j,t]) *
                        LMPs[ag_loc[j],t] for j in 1:(n_a+1)) for t in 1:n_t)
                        for i in 1:n_a]

    agent_pay = [sum(value.(model[:Lᴴ][i,:]))*price_loss_pu +
                    price_consumed_pu[i] for i in 1:n_a]

    node_pay = [sum(agent_pay[Iₙ[n]]) for n in 1:dhn.nₙ]
    # node_pay_pu_DLG_socialized_LAP = node_pay_DLG_socialized_LAP ./
    #                 [sum(value.(model[:Lᴴ][Iₙ[n],:])) for n in 1:dhn.nₙ]
    return node_pay
end

function payments_CLG_socialized_LAP(;model, LMPs)
    # return total payments for each node if losses are socialized
    price_loss_pu = sum(sum(sum(value.(model[:w_ij][i,:,t])) *
                  LMPs[g_loc,t] for i in 1:(n_a+1)) for t in 1:n_t) /
                  sum(value.(model[:Lᴴ]))
    price_consumed_pu = [sum(sum(value.(model[:Bᴴ][i,j,t]) *
                        LMPs[ag_loc[j],t] for j in 1:(n_a+1)) for t in 1:n_t)
                        for i in 1:n_a]

    agent_pay = [sum(value.(model[:Lᴴ][i,:]))*price_loss_pu +
                    price_consumed_pu[i] for i in 1:n_a]

    node_pay = [sum(agent_pay[Iₙ[n]]) for n in 1:dhn.nₙ]
    # node_pay_pu_DLG_socialized_LAP = node_pay_DLG_socialized_LAP ./
    #                 [sum(value.(model[:Lᴴ][Iₙ[n],:])) for n in 1:dhn.nₙ]
    return node_pay
end
