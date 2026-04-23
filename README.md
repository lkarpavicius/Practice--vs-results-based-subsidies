# Practice--vs-results-based-subsidies
This repository contains GAMS source code for reproducing the results of the forthcoming paper:
“Practice- or results-based subsidies: balancing direct costs for soil carbon sequestration and transaction costs for farmers and monitoring agencies”
by Luiza Karpavicius and Katarina Elofsson.

The paper will be published in Q Open.

This repository provides the computational implementation of a numerical optimization model analyzing policy design for agricultural carbon sequestration. The model compares:

- Practice-based subsidies (payments per hectare for specific actions)
- Results-based subsidies (payments per unit of carbon sequestered)

while explicitly accounting for:

Direct mitigation costs
- Private transaction costs for farmers
- Public monitoring, reporting, and verification (MRV) costs
- Heterogeneity across farm types and regions

The model maximizes social net benefits under different policy designs.


# Model Description

The implemented model is formulated as a nonlinear optimization problem and solved using GAMS (CONOPT4 solver)
It includes:
- A social planner problem (first-best, results-based subsidy, also referred to as output subsidy)
- A Stackelberg game framework for uniform practice-based subsidies, i.e. input subsidies

The framework allows comparison of policy instruments under realistic institutional constraints.

# Empirical Application

The model here is calibrated using data from Danish agriculture, including:
- 75 representative farm types
- Regional variation across Denmark
- Three carbon sequestration measures: Cover cropping, Reduced tillage and Conversion to grassland

Carbon sequestration, costs, and constraints are parameterized using empirical literature and official statistics.

Key findings from the paper include:

- Results-based subsidies generally yield higher net benefits and greater carbon sequestration
- However, practice-based subsidies can outperform when MRV costs are sufficiently high (e.g., >3.5× those of practice-based schemes, depending on carbon price)

# Data Availability

All data used in this study are available as supplementary materials accompanying the paper. Please refer to the published article in Q Open for access to:
- Parameter values
- Calibration details
- Results graphs and sensitivity analyses

# Citation

If you use this code, please cite: Karpavicius, L., & Elofsson, K.
Practice- or results-based subsidies: balancing direct costs for soil carbon sequestration and transaction costs for farmers and monitoring agencies.
Q Open (forthcoming).

This project is licensed under the MIT License. You are free to use, modify, and distribute the code for any purpose, provided that appropriate credit is given.

# Contact
This repository will not be updated after May 2026. For questions or collaboration, please contact the authors via their institutional affiliations.
