$onText
------------------------------------------------------------------------------
MODEL PURPOSE
------------------------------------------------------------------------------
This model solves for the optimal area allocation of three mitigation measures
across farm types under a set of carbon price scenarios.

It generates, for each scenario:
  - Net benefits
  - Net revenues
  - Sequestration by farm type and measure
  - Area allocation by farm type and measure
  - Mitigation costs
  - Private transaction costs
  - Public MRV / transaction costs
  - Total cost
  - Subsidy cost
  - Optimal uniform subsidy by measure

Measures:
  JM1 = cover crops
  JM2 = grassland
  JM3 = reduced tillage

Main idea:
  For each carbon price scenario, the model chooses area A(i,j) and a uniform
  subsidy s(j) to maximize net benefits, subject to response/cost conditions
  and area trade-off constraints.

Author: Luiza Karpavicius
Last modified: 09-03-2024

NOTES FOR REUSE
------------------------------------------------------------------------------
1. All Excel input files below should be replaced with your own data sources/ assumptions. 
(Here the calibration is done, as explained in the paper, for Denmark)
2. Sheet names and ranges must match your Excel files exactly.
3. The model assumes farm types FT1*FT75 and scenarios CP1*CP100.
   Adjust these set definitions if your data structure is different.
4. Output ranges "XXX!a1" are placeholders and should be replaced with the
   actual workbook/sheet destinations you want to write to.
------------------------------------------------------------------------------
$offText


*==============================================================================
* 1. IMPORT INPUT DATA FROM EXCEL
*==============================================================================

*----------------------------------------------------------------------------
* Import SOC data
* soc(i,j) = increase in soil organic carbon per hectare for measure j on farm i
* Replace "soc.xlsx" with your own SOC input data source.
* Expected layout: sheet "soc", range A1:D76
*----------------------------------------------------------------------------
$CALL GDXXRW soc.xlsx output=soc.gdx par=soc rng=soc!A1:D76

*----------------------------------------------------------------------------
* Import maximum feasible area data
* capgregor(i,j) = maximum area available to measure j on farm i
* Replace "capgregor.xlsx" with your own farm-level capacity data source.
* Expected layout: sheet "capgregor", range A1:D76
*----------------------------------------------------------------------------
$CALL GDXXRW capgregor.xlsx output=capgregor.gdx par=capgregor rng=capgregor!A1:D76




*==============================================================================
* 2. DEFINE SETS
*==============================================================================

Sets
    i         'farm types' /FT1*FT75/
    scenario  'carbon price scenarios' /CP1*CP100/
    j         'mitigation measures: JM1=cover crops, JM2=grassland, JM3=reduced tillage'
              /JM1*JM3/;



*==============================================================================
* 3. LOAD CORE PARAMETERS FROM GDX FILES
*==============================================================================

Parameters
    soc(i,j)        'increase in SOC per hectare allocated to measure j in farm i'
    capgregor(i,j)  'maximum area available to measure j in farm i';

$GDXIN soc.gdx
$LOAD soc
$GDXIN

$GDXIN capgregor.gdx
$LOAD capgregor
$GDXIN



*==============================================================================
* 4. LOAD SCENARIO AND FARM-LEVEL INPUTS
*==============================================================================

Parameters
    b_scenarios(scenario)    'carbon price by scenario'
    seq_scenarios(scenario)  'sequestration target by scenario (currently loaded but not used)'
    n(i)                     'number of farms of type i in Denmark'
    capCC(i)                 'maximum area for cover crops'
    capTILL(i)               'maximum area for reduced tillage'
    transp2(i)               'transport cost per average farm in region i';

*----------------------------------------------------------------------------
* Carbon price scenarios
* Replace "data_b.xlsx" with your own carbon-price scenario input. d
* data_b includes simulations from 50 to 5,000, in 50 increments
*----------------------------------------------------------------------------
$call gdxxrw.exe data_b.xlsx par=b_scenarios rng=data_b!A2:B101 rdim=1 dset=scenario rng=data_b!A2:B101 rdim=1
$gdxin data_b.gdx
$load b_scenarios
$gdxin

*----------------------------------------------------------------------------
* Sequestration potential
* Replace "data_seq.xlsx" with your own sequestration values for each of the measures

*----------------------------------------------------------------------------
$call gdxxrw.exe data_seq.xlsx par=seq_scenarios rng=data_seq!A2:B101 rdim=1 dset=scenario rng=data_seq!A2:B101 rdim=1
$gdxin data_seq.gdx
$load seq_scenarios
$gdxin

*----------------------------------------------------------------------------
* Number of farms by farm type
* Replace "data_n.xlsx" with your own farm-count data.
*----------------------------------------------------------------------------
$call gdxxrw.exe data_n.xlsx par=n rng=data_n!A2:B76 rdim=1 dset=i rng=data_n!A2:B76 rdim=1
$gdxin data_n.gdx
$load n
$gdxin

*----------------------------------------------------------------------------
* Capacity for cover-crops
* Replace "capCC.xlsx" with your own capCC data (in hectares).
*----------------------------------------------------------------------------
$call gdxxrw.exe capCC.xlsx par=capCC rng=capCC!A2:B76 rdim=1 dset=i rng=capCC!A2:B76 rdim=1
$gdxin capCC.gdx
$load capCC
$gdxin

*----------------------------------------------------------------------------
* Capacity for reduced tillage
* Replace "capTILL.xlsx" with your own capTILL data, in hectares
*----------------------------------------------------------------------------
$call gdxxrw.exe capTILL.xlsx par=capTILL rng=capTILL!A2:B76 rdim=1 dset=i rng=capTILL!A2:B76 rdim=1
$gdxin capTILL.gdx
$load capTILL
$gdxin

*----------------------------------------------------------------------------
* cropland area
* Replace "cap_crop.xlsx" with your own cropland area
* NOTE: cap_crop is loaded but not currently used in the model equations.
*----------------------------------------------------------------------------
$call gdxxrw.exe cap_crop.xlsx par=cap_crop rng=cap_crop!A2:B76 rdim=1 dset=i rng=cap_crop!A2:B76 rdim=1
$gdxin cap_crop.gdx
$load cap_crop
$gdxin

*----------------------------------------------------------------------------
* Transport cost data
* Replace "transp2.xlsx" with your own transport cost data.
*
*----------------------------------------------------------------------------
$call gdxxrw.exe transp2.xlsx par=transp2 rng=transp!A2:B76 rdim=1 dset=i rng=transp!A2:B76 rdim=1
$gdxin transp2.gdx
$load transp2
$gdxin


display n, seq_scenarios;



*==============================================================================
* 5. DEFINE STORAGE PARAMETERS
*==============================================================================

Parameters
    NB_RESULT(scenario)              'net benefits'
    NR_RESULT(scenario)              'net revenues'
    X_RESULT(scenario,i,j)           'sequestration'
    A_RESULT(scenario,i,j)           'area'
    MitCost_RESULT(scenario,i,j)     'mitigation cost'
    TranCost_RESULT(scenario,i,j)    'private transaction cost'
    MVR_RESULT(scenario,i,j)         'public monitoring, verification, and reporting costs'
    ALL_Cost_RESULT(scenario,i,j)    'total cost = mitigation + private transaction + public MRV'
    SUBSIDY_COST_RESULT(scenario,i,j)'payment to farmers + MRV costs'
    Optimal_sub_result(scenario,j)   'optimal uniform subsidy per measure (EUR/ha)'
    Rent_RESULTS(scenario,i,j)       'economic rent by farm type and measure';



*==============================================================================
* 6. DEFINE MODEL PARAMETERS
*==============================================================================

Parameters
    epsilon          'small value to guard against numerical issues' /1e-6/
    b                'marginal benefit / carbon price'
    seq              'sequestration target (currently unused)'

    CAP_max(j)       'maximum area parameter in subsidy initialization'
                     / JM1 85.05, JM2 0.01, JM3 213.3 /

    SOC_max(j)       'maximum SOC parameter in subsidy initialization'
                     / JM1 0.34, JM2 3.41, JM3 0.2 /

    CAP_min(j)       'minimum area parameter (currently unused)'
                     / JM1 0.025, JM2 0.003, JM3 1.02 /

    SOC_min(j)       'minimum SOC parameter (currently unused)'
                     / JM1 0.02, JM2 1.61, JM3 0.18 /

    cm_hec(j)        'marginal mitigation cost parameter'
                     / JM1 6.6, JM2 42.5, JM3 0.48 /

    tm(j)            'marginal private transaction cost parameter'
                     / JM1 154, JM2 0.9, JM3 18.4 /

    mvr_hec_input    'MRV cost parameter for input-based policy instrument (excluding transport)'
                     / 13.33 /

    mvr_hec_output   'MRV cost parameter for output-based policy instrument (excluding transport)'
                     / 31.89 /;

*==============================================================================
* 7. DECLARE DECISION VARIABLES
*==============================================================================

Variable
    NB               'net benefits in EUR';

Positive Variables
    X(i,j)           'sequestration in tCO2eq'
    A(i,j)           'area allocated to measure j in hectares'
    MitCost(i,j)     'mitigation cost in EUR'
    TranCost(i,j)    'private transaction cost in EUR'
    MVR(i,j)         'MRV costs in EUR'
    Till(i)          'aggregate area linked to tillage trade-off'
    Cover(i)         'aggregate area linked to cover-crop trade-off'
    s(j)             'uniform subsidy in EUR/ha';


*==============================================================================
* 8. VARIABLE BOUNDS AND STARTING VALUES
*==============================================================================

* Area bounds
A.LO(i,j) = 0;
A.L(i,j)  = capgregor(i,j) * 0.01;
A.UP(i,j) = max(1e-6, capgregor(i,j));

* Subsidy bounds and initial value
s.LO(j) = 0;
s.L(j)  = (2 * cm_hec(j) * CAP_max(j) * 0.01)
        + (2 * tm(j) * Power(SOC_max(j),2) * CAP_max(j) * 0.01);
s.UP(j) = 1000;

* Aggregate upper bounds
Till.UP(i)  = capTILL(i);
Cover.UP(i) = capCC(i);



*==============================================================================
* 9. EQUATIONS
*==============================================================================

Equations
    obj(i,j)                      'objective function defining net benefits'
    responseeq(i,j)               'subsidy must cover marginal response cost'
    area_tradeoff_covercrops(i)   'trade-off constraint between grassland and cover crops'
    area_tradeoff_reduced_till(i) 'trade-off constraint between grassland and reduced tillage';

area_tradeoff_covercrops(i)..
    A(i,'JM1') + A(i,'JM2') =e= Cover(i);

area_tradeoff_reduced_till(i)..
    A(i,'JM2') + A(i,'JM3') =e= Till(i);

obj..
    NB =e=
        SUM((i,j),
              n(i) * b * soc(i,j) * A(i,j)
            - n(i) * s(j) * A(i,j)
            - n(i) * (mvr_hec_input * A(i,j) + transp2(i) * A(i,j))
        );

responseeq(i,j)..
      (2 * cm_hec(j) * A(i,j))
    + (2 * tm(j) * Power(soc(i,j),2) * A(i,j))
    =l= s(j);


*==============================================================================
* 10. MODEL DEFINITION
*==============================================================================

Model XoptUniform / all /;
XoptUniform.scaleopt = 1;


*==============================================================================
* 11. SOLVE LOOP OVER CARBON PRICE SCENARIOS
*==============================================================================

Loop(scenario,

    * Set carbon price for this scenario
    b = b_scenarios(scenario);

    * Optional sequestration target by scenario (currently not activated)
    * seq = seq_scenarios(scenario);

    * Solve model
    Solve XoptUniform maximizing NB using nlp;

    *----------------------------------------------------------------------
    * Store results for this scenario
    *----------------------------------------------------------------------

    NB_RESULT(scenario) = NB.L;

    NR_RESULT(scenario) =
        SUM((i,j),
              n(i) * s.L(j) * A.L(i,j)
            - n(i) * (cm_hec(j) * rPower(A.L(i,j),2))
            - n(i) * tm(j) * rPower(soc(i,j) * A.L(i,j),2)
        );

    X_RESULT(scenario,i,j) =
        n(i) * soc(i,j) * A.L(i,j);

    A_RESULT(scenario,i,j) =
        n(i) * A.L(i,j);

    MitCost_RESULT(scenario,i,j) =
        n(i) * (cm_hec(j) * rPower(A.L(i,j),2));

    TranCost_RESULT(scenario,i,j) =
        n(i) * tm(j) * rPower(soc(i,j) * A.L(i,j),2);

    MVR_RESULT(scenario,i,j) =
        n(i) * (mvr_hec_input * A.L(i,j) + transp2(i) * A.L(i,j));

    Rent_RESULTS(scenario,i,j) =
        s.L(j) * n(i) * A.L(i,j)
        - TranCost_RESULT(scenario,i,j)
        - MitCost_RESULT(scenario,i,j);

    ALL_Cost_RESULT(scenario,i,j) =
        MVR_RESULT(scenario,i,j)
        + TranCost_RESULT(scenario,i,j)
        + MitCost_RESULT(scenario,i,j);

    SUBSIDY_COST_RESULT(scenario,i,j) =
        s.L(j) * A.L(i,j) * n(i)
        + MVR_RESULT(scenario,i,j);

    Optimal_sub_result(scenario,j) =
        s.L(j);
);



*==============================================================================
* 12. EXPORT RESULTS TO GDX AND THEN TO EXCEL
*==============================================================================

* IMPORTANT:
* Every "XXX!a1" below is a placeholder.
* Replace "XXX" with the actual worksheet name in your output workbook.

execute_unload "NB_input.gdx" NB_RESULT;
execute 'gdxxrw.exe NB_input.gdx par=NB_RESULT rng=XXX!a1';

execute_unload "NR_input.gdx" NR_RESULT;
execute 'gdxxrw.exe NR_input.gdx par=NR_RESULT rng=XXX!a1';

execute_unload "rent_input.gdx" Rent_RESULTS;
execute 'gdxxrw.exe rent_input.gdx par=Rent_RESULTS rng=XXX!a1';

execute_unload "Sequestration_input.gdx" X_RESULT;
execute 'gdxxrw.exe Sequestration_input.gdx par=X_RESULT rng=XXX!a1';

execute_unload "Area_input.gdx" A_RESULT;
execute 'gdxxrw.exe Area_input.gdx par=A_RESULT rng=XXX!a1';

execute_unload "ALL_Cost_RESULT_input.gdx" ALL_Cost_RESULT;
execute 'gdxxrw.exe ALL_Cost_RESULT_input.gdx par=ALL_Cost_RESULT rng=XXX!a1';

execute_unload "SUBSIDY_COST_RESULT_input.gdx" SUBSIDY_COST_RESULT;
execute 'gdxxrw.exe SUBSIDY_COST_RESULT_input.gdx par=SUBSIDY_COST_RESULT rng=XXX!a1';

execute_unload "Optimal_sub_result_input.gdx" Optimal_sub_result;
execute 'gdxxrw.exe Optimal_sub_result_input.gdx par=Optimal_sub_result rng=XXX!a1';

execute_unload "MitCost_input.gdx" MitCost_RESULT;
execute 'gdxxrw.exe MitCost_input.gdx par=MitCost_RESULT rng=XXX!a1';

execute_unload "TranCost_input.gdx" TranCost_RESULT;
execute 'gdxxrw.exe TranCost_input.gdx par=TranCost_RESULT rng=XXX!a1';

execute_unload "MVR_input.gdx" MVR_RESULT;
execute 'gdxxrw.exe MVR_input.gdx par=MVR_RESULT rng=XXX!a1';
