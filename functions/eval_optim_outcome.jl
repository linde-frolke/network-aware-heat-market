using JuMP

function eval_optim_outcome(m::JuMP.Model)
    print("termination status = $(termination_status(m))\n")
    print("dual status = $(dual_status(m))\n")
    print("primal status = $(primal_status(m))\n")
end
