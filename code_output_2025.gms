$onText
------------------------------------------------------------------------------
MODEL PURPOSE
------------------------------------------------------------------------------
This model solves for the optimal area allocation of three mitigation measures
across farm types under a set of carbon price scenarios, under an output-based
policy instrument.

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

Measures:
  JM1 = cover crops
  JM2 = grassland
  JM3 = reduced tillage

Main idea:
  For each carbon price scenario, the model chooses area A(i,j) to maximize
  net benefits, accounting for carbon benefits, mitigation costs, private
  transaction costs, and public MRV plus transport costs.

This specification represents an output-based payment framework, and calculates 
the implied subsidy ex post from the carbon price minus per-hectare MRV and
transport costs.

Author: Luiza Karpavicius
Last modified: 09-03-2024

NOTES FOR REUSE
------------------------------------------------------------------------------
1. All Excel input files below should be replaced with your own data sources /
   assumptions.
   (Here the calibration is done, as explained in the paper, for Denmark.)
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
* capgregor(i,j) = maximum area available to measure j in farm i
* Replace "capgregor.xlsx" with your own farm-level capacity data source.
* Expected layout: sheet "capgregor", range A1:D76
*----------------------------------------------------------------------------
$CALL GDXXRW capgregor.xlsx output=capgregor.gdx par=capgregor rng=capgregor!A1:D76


*==============================================================================
* 2. DEFINE SETS
*==============================================================================

Sets
    i         'farm types' /FT1*FT75/
    scenario  'carbon price scenarios (value of b)' /CP1*CP100/
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
    b_scenarios(scenario)    'carbon price'
    n(i)                     'number of farms of type i in Denmark'
    capCC(i)                 'maximum area for cover crops'
    capTILL(i)               'maximum area for reduced tillage'
    cap_crop(i)              'cropland area'
    transp2(i)               'transport cost per average farm per region';

*----------------------------------------------------------------------------
* Carbon price scenarios
* Replace "data_b.xlsx" with your own carbon-price scenario input.
* In the current setup, data_b includes simulations from 50 to 5,000,
* in increments of 50.
*----------------------------------------------------------------------------
$call gdxxrw.exe data_b.xlsx par=b_scenarios rng=data_b!A2:B101 rdim=1 dset=scenario rng=data_b!A2:B101 rdim=1
$gdxin data_b.gdx
$load b_scenarios
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
* Capacity for cover crops
* Replace "capCC.xlsx" with your own capCC data, in hectares.
*----------------------------------------------------------------------------
$call gdxxrw.exe capCC.xlsx par=capCC rng=capCC!A2:B76 rdim=1 dset=i rng=capCC!A2:B76 rdim=1
$gdxin capCC.gdx
$load capCC
$gdxin

*----------------------------------------------------------------------------
* Capacity for reduced tillage
* Replace "capTILL.xlsx" with your own capTILL data, in hectares.
*----------------------------------------------------------------------------
$call gdxxrw.exe capTILL.xlsx par=capTILL rng=capTILL!A2:B76 rdim=1 dset=i rng=capTILL!A2:B76 rdim=1
$gdxin capTILL.gdx
$load capTILL
$gdxin

*----------------------------------------------------------------------------
* Transport cost data
* Replace "transp2.xlsx" with your own transport cost data.
*
* NOTE:
* The file is named "transp2.xlsx" but the sheet used is "transp".
* Check that this sheet name is correct in your workbook.
*----------------------------------------------------------------------------
$call gdxxrw.exe transp2.xlsx par=transp2 rng=transp!A2:B76 rdim=1 dset=i rng=transp!A2:B76 rdim=1
$gdxin transp2.gdx
$load transp2
$gdxin

*----------------------------------------------------------------------------
* Cropland area
* Replace "cap_crop.xlsx" with your own cropland area data.

*----------------------------------------------------------------------------
$call gdxxrw.exe cap_crop.xlsx par=cap_crop rng=cap_crop!A2:B76 rdim=1 dset=i rng=cap_crop!A2:B76 rdim=1
$gdxin cap_crop.gdx
$load cap_crop
$gdxin


*display n, b_scenarios;



*==============================================================================
* 5. DEFINE STORAGE PARAMETERS
*==============================================================================

Parameters
    NB_RESULT(scenario)               'net benefits'
    NR_RESULT(scenario)               'net revenue'
    X_RESULT(scenario,i,j)            'sequestration'
    A_RESULT(scenario,i,j)            'area'
    MitCost_RESULT(scenario,i,j)      'mitigation cost'
    TranCost_RESULT(scenario,i,j)     'private transaction cost'
    MVR_RESULT(scenario,i,j)          'public transaction costs'
    SUBSIDY_COST_RESULT(scenario,i,j) 'payment given to farmers plus MRV costs in EUR'
    ALL_Cost_RESULT(scenario,i,j)     'total cost = mitigation + private transaction + public MRV'
    Rent_RESULTS(scenario,i,j)        'economic rent by farm type and measure'
    Optimal_sub_result(scenario,i)    'implied optimal subsidy';



*==============================================================================
* 6. DEFINE MODEL PARAMETERS
*==============================================================================

Parameters
    epsilon          'small value to guard against rPower encountering zeros' /1e-6/
    b                'marginal benefits / carbon price'
    seq              'sequestration target (currently unused)'

    CAP_max(j)       'maximum area parameter'
                     / JM1 85.05, JM2 0.01, JM3 213.3 /

    SOC_max(j)       'maximum SOC parameter'
                     / JM1 0.34, JM2 3.41, JM3 0.2 /

    CAP_min(j)       'minimum area parameter (currently unused)'
                     / JM1 0.025, JM2 0.003, JM3 1.02 /

    SOC_min(j)       'minimum SOC parameter (currently unused)'
                     / JM1 0.02, JM2 1.61, JM3 0.18 /

    cm_hec(j)        'marginal mitigation cost parameter'
                     / JM1 6.6, JM2 42.5, JM3 0.48 /

    tm(j)            'marginal transaction cost parameter'
                     / JM1 154, JM2 0.9, JM3 18.4 /

*   alpha           'parameter for non-linearity in sequestration equation'
*                    / 0.9 /

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
    Cover(i)         'aggregate area linked to cover-crop trade-off';



*==============================================================================
* 8. VARIABLE BOUNDS AND STARTING VALUES
*==============================================================================

* Area bounds
A.LO(i,j) = 0;
A.L(i,j)  = capgregor(i,j) * 0.01;
A.UP(i,j) = max(1e-6, capgregor(i,j));

* Aggregate upper bounds
Till.UP(i)  = capTILL(i);
Cover.UP(i) = capCC(i);



*==============================================================================
* 9. EQUATIONS
*==============================================================================

Equations
    obj                              'net benefits function'
    area_tradeoff_covercrops(i)      'trade-off constraint between grassland and cover crops'
    area_tradeoff_reduced_till(i)    'trade-off constraint between grassland and reduced tillage';

area_tradeoff_covercrops(i)..
    A(i,'JM1') + A(i,'JM2') =e= Cover(i);

area_tradeoff_reduced_till(i)..
    A(i,'JM2') + A(i,'JM3') =e= Till(i);

obj..
    NB =e=
        SUM((i,j),
              n(i) * b * soc(i,j) * A(i,j)
            - n(i) * cm_hec(j) * rPower(A(i,j),2)
            - n(i) * tm(j) * rPower(soc(i,j) * A(i,j),2)
            - n(i) * (mvr_hec_output * A(i,j) + transp2(i) * A(i,j))
        );



*==============================================================================
* 10. MODEL DEFINITION
*==============================================================================

Model Xoptout / all /;
Xoptout.scaleopt = 1;



*==============================================================================
* 11. SOLVE LOOP OVER CARBON PRICE SCENARIOS
*==============================================================================

Loop(scenario,

    * Set carbon price for this scenario
    b = b_scenarios(scenario);

    * Solve model
    Solve Xoptout maximizing NB using nlp;

    *----------------------------------------------------------------------
    * Store results for this scenario
    *----------------------------------------------------------------------

    NB_RESULT(scenario) = NB.L;

    * Net revenue is calculated as net benefits plus public MRV and transport
    * costs, i.e. excluding those public costs from the private revenue measure.
    NR_RESULT(scenario) =
        NB.L
        + SUM((i,j),
              n(i) * (mvr_hec_output * A.L(i,j) + transp2(i) * A.L(i,j))
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
        n(i) * (mvr_hec_output * A.L(i,j) + transp2(i) * A.L(i,j));

    ALL_Cost_RESULT(scenario,i,j) =
        MVR_RESULT(scenario,i,j)
        + TranCost_RESULT(scenario,i,j)
        + MitCost_RESULT(scenario,i,j);

    Rent_RESULTS(scenario,i,j) =
        b * n(i) * soc(i,j) * A.L(i,j)
        - TranCost_RESULT(scenario,i,j)
        - MitCost_RESULT(scenario,i,j);

    * Implied subsidy under the output-based instrument
    * This is farm-specific because transport cost varies by i.
    Optimal_sub_result(scenario,i) =
        (b - mvr_hec_output - transp2(i));

    SUBSIDY_COST_RESULT(scenario,i,j) =
        b * n(i) * soc(i,j) * A.L(i,j)
        + MVR_RESULT(scenario,i,j);
);



*==============================================================================
* 12. EXPORT RESULTS TO GDX AND THEN TO EXCEL
*==============================================================================

* IMPORTANT:
* Every "XXX!a1" below is a placeholder.
* Replace "XXX" with the actual worksheet name in your output workbook.

execute_unload "NB_output.gdx" NB_RESULT;
execute 'gdxxrw.exe NB_output.gdx par=NB_RESULT rng=XXX!a1';

execute_unload "NR_output.gdx" NR_RESULT;
execute 'gdxxrw.exe NR_output.gdx par=NR_RESULT rng=XXX!a1';

execute_unload "rent_output.gdx" Rent_RESULTS;
execute 'gdxxrw.exe rent_output.gdx par=Rent_RESULTS rng=XXX!a1';

execute_unload "Optimal_sub_result_output.gdx" Optimal_sub_result;
execute 'gdxxrw.exe Optimal_sub_result_output.gdx par=Optimal_sub_result rng=XXX!a1';

execute_unload "Sequestration_output.gdx" X_RESULT;
execute 'gdxxrw.exe Sequestration_output.gdx par=X_RESULT rng=XXX!a1';

execute_unload "Area_output.gdx" A_RESULT;
execute 'gdxxrw.exe Area_output.gdx par=A_RESULT rng=XXX!a1';

execute_unload "ALL_Cost_RESULT_output.gdx" ALL_Cost_RESULT;
execute 'gdxxrw.exe ALL_Cost_RESULT_output.gdx par=ALL_Cost_RESULT rng=XXX!a1';

execute_unload "SUBSIDY_COST_RESULT_output.gdx" SUBSIDY_COST_RESULT;
execute 'gdxxrw.exe SUBSIDY_COST_RESULT_output.gdx par=SUBSIDY_COST_RESULT rng=XXX!a1';

execute_unload "MitCost_output.gdx" MitCost_RESULT;
execute 'gdxxrw.exe MitCost_output.gdx par=MitCost_RESULT rng=XXX!a1';

execute_unload "TranCost_output.gdx" TranCost_RESULT;
execute 'gdxxrw.exe TranCost_output.gdx par=TranCost_RESULT rng=XXX!a1';

execute_unload "MVR_output.gdx" MVR_RESULT;
execute 'gdxxrw.exe MVR_output.gdx par=MVR_RESULT rng=XXX!a1';
