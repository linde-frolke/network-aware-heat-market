# network-aware-heat-market
This repository supports the article _A network-aware market mechanism for decentralized district
 heating systems_. It contains a Julia implementation of the market mechanisms therein. Furthermore,
  the case study considered in the article can be executed using this repository. All inputs needed
   for the case study are included in the repository, see below.

## Getting started
Before you run the scripts, make sure you have the needed packages installed. The script
 **make_environment.jl** lists which packages you need, and helps you to create an environment
 first, if you want that.

## File structure
The _scripts_ folder contains
1. A script for loading the needed inputs: _load\_parameters.jl_.
This script also calls _load\_prosumer\_parameters.jl_.
2. A script for running the optimal dispatch based on these inputs: _run\_markets.jl_
3. A script for postprocessing the optimal dispatch results: _postprocess\_results.jl_.
Here, we compute relevant quantities such as nodal prices, total costs, and other quantities
that we will want to visualize.
4. A script to reproduce the plots in the article: _plot\_results.jl_ .

Input time series data is in the _data_ folder in several .csv files.

The dispatch strategies are implemented in several functions in the file
_functions/optimization_model_functions.jl_. These are called in the script _run\_markets.jl_.

## Using the files


