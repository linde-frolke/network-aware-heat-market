#=
Script making plots present in article.
Should have run the other scripts first:
1. load_parameters
2. run_markets
3. postprocess_results
=#

using PyPlot, ColorSchemes, Plots
using Colors
pygui(true)
include("../functions/my_colormap.jl")
# colors
prop_cycle = plt.rcParams["axes.prop_cycle"]
colors = prop_cycle.by_key()["color"]

fig_save = false
folder = "add_your_figure_folder_here"

#---
# plot el and heat prices
plt.close()
fig, ax = plt.subplots()
ax.plot(1:n_t, ciᵍᴱ, color=:black, label="electricity import")
ax.plot(1:n_t, ciᵍᴴ, color=:black, linestyle="dashdot", label="heat import")

labels = Vector(1:6) .* 4
ax.set_xticks(labels)
ax.set_xticklabels(["$i" for i in labels])
ax.vlines(labels, ymin=0, ymax=420, color=:gray, alpha=0.1)

ax.set_ylabel("Energy price [EUR/MWh]")
ax.set_xlabel("Time [h]")
ax.spines["right"].set_visible(false)
ax.spines["top"].set_visible(false)
ax.legend(loc="upper left", frameon=false)
ax.set_xlim((0.5,24.5))
ax.set_ylim((50, 280))
fig.tight_layout()

plt.show()
if fig_save
    PyPlot.savefig("$(folder)/heat_el_price.pdf")
end


#--- Generation plot including separate grid generations
plt.close()
labels = ["n$i" for i in 1:dhn.nₙ]
labels = ["grid"; labels]
x = range(1, length=length(labels))  # the label locations
width = 0.25  # the width of the bars

fig, ax = plt.subplots()
rects2 = ax.bar(x .- width, (nodal_total_consumed_gen_g[:,1]) ./ 10^6, width,
                label=model_names[1], color=colors[1])
rects1 = ax.bar(x .- width, (nodal_total_gen_g[:,1]) ./ 10^6, width, color=colors[1],
            alpha=0.6)
rects3 = ax.bar(x, (nodal_total_gen_g[:,2]) ./ 10^6, width, color=colors[2], alpha=0.5)
rects3b = ax.bar(x, ([nodal_total_gen_g[1,2]- sum(CLG_awa_loss_tot);
                        nodal_total_gen_g[2:12,2]]) ./ 10^6, width, color=colors[2],
                        label=model_names[2])
rects5 = ax.bar(x .+ width, (nodal_total_gen_g[:,3]) ./ 10^6, width,
                    color=colors[3], alpha=0.5)
rects5b = ax.bar(x .+ width, ([nodal_total_gen_g[1,3]- sum(CLG_ign_loss_tot);
                        nodal_total_gen_g[2:12,3]]) ./ 10^6, width, color=colors[3],
                        label=model_names[3])

# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel("Generated Heat Energy [MWh]")
ax.set_xlabel("Node")
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.spines["right"].set_visible(false)
ax.spines["top"].set_visible(false)
fig.tight_layout()
ax.legend(frameon=false)
plt.show()
if fig_save
    PyPlot.savefig("$(folder)/comp_nodal_generation_case$(case).pdf")
end

#---
# plot prices
# good color schemes:
# :CMRmap or :default or :matter
labs = reshape(["n$n" for n in 1:dhn.nₙ], (1,dhn.nₙ))
ylim_ = (30, 76)
labels = Vector(1:6) .* 4
colmap = my_colmap(dhn.nₙ+1, cs=:matter, rev=true)
Plots.plot(1:n_t, LMP_DLG_awa_p2p_flex', color=colmap, label=labs, ylims=ylim_,
    xlabel="time [h]", ylabel="price [EUR/MWh]", legend=:topleft, xticks=labels,
    grid="x")
if fig_save
    Plots.savefig("$(folder)/LMP_DLG_awa_case$(case).pdf")
end
Plots.plot(1:n_t, LMP_CLG_awa_p2p_flex', color=colmap, label=labs, ylims=ylim_,
    xlabel="time [h]", ylabel="price [EUR/MWh]", legend=:topleft, xticks=labels,
    grid="x")
if fig_save
    Plots.savefig("$(folder)/LMP_CLG_awa_case$(case).pdf")
end
Plots.plot(1:n_t, LMP_CLG_ign_p2p_flex', color=colmap, label=labs,ylims=ylim_,
    xlabel="time [h]", ylabel="price [EUR/MWh]", legend=:topleft, xticks=labels,
    grid="x")
if fig_save
    Plots.savefig("$(folder)/LMP_CLG_ign_case$(case).pdf")
end

#--- Payment plot per unit
plt.close()
labels = ["n$i" for i in 1:dhn.nₙ]
x = range(1, length=length(labels))  # the label locations
width = 0.25  # the width of the bars

fig, ax = plt.subplots()
plt_DLG_awa = ax.bar(x .- width, node_pay_pu_DLG_awa, width,
                label=model_names[1], color=colors[1])
plt_CLG_awa = ax.bar(x, node_pay_pu_CLG_awa, width,
                label=model_names[2], color=colors[2])
plt_CLG_ign = ax.bar(x .+ width, node_pay_pu_CLG_ign, width,
                label=model_names[3], color=colors[3])
# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel("Payment per unit consumed [EUR/MWh]")
ax.set_xlabel("Node")
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.legend()
#fig.tight_layout()
plt.show()
if fig_save
    PyPlot.savefig("$(folder)/payments_perunit_case$(case).pdf")
end



## payments DLG indiv VS CLG socialized
avg_pay_pu_DLG = payments_pu_avg(;model=m_DLG_awa_p2p_flex,
                        LMPs=LMP_DLG_awa_p2p_flex, loss_aware=true)
avg_pay_pu_CLG_awa = payments_pu_avg(;model=m_CLG_awa_p2p_flex,
                        LMPs=LMP_CLG_awa_p2p_flex, loss_aware=true)
avg_pay_pu_CLG_ign = payments_pu_avg(;model=m_CLG_ign_p2p_flex,
                        LMPs=LMP_CLG_ign_p2p_flex, loss_aware=false)

plt.close()
labels = ["n$i" for i in 1:dhn.nₙ]
labels = [labels; ["mean"; ""]]
x = range(1, length=length(labels))  # the label locations
width = 0.4  # the width of the bars

fig, ax = plt.subplots()
plt_DLG_awa = ax.plot(x[1:11], node_pay_pu_DLG_awa,
                label="loss-aware DLG individual LAP", color=colors[1],
                alpha=1)
plt_DLG_awa = ax.plot(x[1:11], node_pay_pu_CLG_ign_soc_LAP,
                label="loss-ignorant CLG socialized LAP", color=colors[3],
                alpha=0.7)
ax.fill_between(x[1:11], node_pay_pu_DLG_awa, node_pay_pu_CLG_ign_soc_LAP,
    where=(node_pay_pu_DLG_awa .> node_pay_pu_CLG_ign_soc_LAP), color=colors[1], alpha=0.1,
                 interpolate=true, hatch="+")
ax.fill_between(x[1:11], node_pay_pu_DLG_awa, node_pay_pu_CLG_ign_soc_LAP,
    where=(node_pay_pu_DLG_awa .< node_pay_pu_CLG_ign_soc_LAP),  color=colors[3], alpha=0.1,
                 interpolate=true, hatch="x")
ax.bar(x[12] .-0.5width, avg_pay_pu_DLG, width, color=colors[1], alpha=0.9)
ax.bar(x[12] .+0.5width, avg_pay_pu_CLG_ign, width, color=colors[3], alpha=0.9)

ax.vlines(x=11.25, ymin=0, ymax = 60, linestyles="dashed", color=:gray)
# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel("Payment per unit consumed [EUR/MWh]")
ax.set_ylim(payment_plot_lims)
ax.set_xlim((0.5, 12.75))
ax.set_xlabel("Node")
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.legend(loc="upper left", frameon=false)

plt.show()
if fig_save
    PyPlot.savefig("$(folder)/CLG_ign_soc_VS_DLG_indivcomp_payments_perunit_case$(case).pdf")
end

#--- DLG indiv VS socialized
plt.close()
labels = ["n$i" for i in 1:dhn.nₙ]
x = range(1, length=length(labels))  # the label locations
width = 0.4  # the width of the barss

fig, ax = plt.subplots()
ax.plot(x[1:11], node_pay_pu_DLG_awa, #width,
                label="individual LAP", color=colors[1],
                alpha=1)
ax.plot(x[1:11], node_pay_pu_DLG_soc_LAP, #width,
                label="socialized LAP", color=colors[1],
                alpha=1, linestyle="dashed")
ax.hlines([avg_pay_pu_DLG], xmin=1, xmax=dhn.nₙ, color=:gray, alpha=1,
                 label="average", linestyle=["dotted"])

# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel("Payment per unit consumed [EUR/MWh]")
ax.set_ylim(payment_plot_lims)
ax.set_xlabel("Node")
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.spines["right"].set_visible(false)
ax.spines["top"].set_visible(false)

ax.legend(loc="upper left", frameon=false)
fig.tight_layout()
plt.show()
if fig_save
    PyPlot.savefig("$(folder)/DLG_soc_VS_indivcomp_payments_perunit_case$(case).pdf")
end

#--- CLG awa indiv VS socialized
plt.close()
labels = ["n$i" for i in 1:dhn.nₙ]
x = range(1, length=length(labels))  # the label locations
width = 0.4  # the width of the barss

fig, ax = plt.subplots()
ax.plot(x[1:11], node_pay_pu_CLG_awa, #width,
                label="individual LAP", color=colors[2],
                alpha=1)
ax.plot(x[1:11], node_pay_pu_CLG_awa_soc_LAP, #width,
                label="socialized LAP", color=colors[2],
                alpha=1, linestyle="dashed")
ax.hlines([avg_pay_pu_CLG_awa], xmin=1, xmax=dhn.nₙ, color=:gray, alpha=1,
                 label="average", linestyle=["dotted"])

# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel("Payment per unit consumed [EUR/MWh]")
ax.set_ylim(payment_plot_lims)
ax.set_xlabel("Node")
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.spines["right"].set_visible(false)
ax.spines["top"].set_visible(false)

ax.legend(loc="upper left", frameon=false)
fig.tight_layout()
plt.show()
if fig_save
    PyPlot.savefig("$(folder)/CLGawa_soc_VS_indivcomp_payments_perunit_case$(case).pdf")
end

#--- CLG ign indiv VS socialized
plt.close()
labels = ["n$i" for i in 1:dhn.nₙ]
x = range(1, length=length(labels))  # the label locations
width = 0.4  # the width of the barss

fig, ax = plt.subplots()
ax.plot(x[1:11], node_pay_pu_CLG_ign, #width,
                label="individual LAP", color=colors[3],
                alpha=1)
ax.plot(x[1:11], node_pay_pu_CLG_ign_soc_LAP, #width,
                label="socialized LAP", color=colors[3],
                alpha=1, linestyle="dashed")
ax.hlines([avg_pay_pu_CLG_ign], xmin=1, xmax=dhn.nₙ, color=:gray, alpha=1,
                 label="average", linestyle=["dotted"])

# Add some text for labels, title and custom x-axis tick labels, etc.
ax.set_ylabel("Payment per unit consumed [EUR/MWh]")
ax.set_ylim(payment_plot_lims)
ax.set_xlabel("Node")
labels = ["n$i" for i in 1:dhn.nₙ]
x = range(1, length=length(labels))  # the label locations
ax.set_xticks(x)
ax.set_xticklabels(labels)
ax.spines["right"].set_visible(false)
ax.spines["top"].set_visible(false)

ax.legend(loc="upper left", frameon=false)
fig.tight_layout()
plt.show()
if fig_save
    PyPlot.savefig("$(folder)/CLGign_soc_VS_indivcomp_payments_perunit_case$(case).pdf")
end
