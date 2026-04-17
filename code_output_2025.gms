$onText
By: Luiza Karpavicius
Last modified 09-03-2024
$offText
$CALL GDXXRW soc.xlsx output=soc.gdx par=soc rng=soc!A1:D76
$CALL GDXXRW capgregor.xlsx output=capgregor.gdx par=capgregor rng=capgregor!A1:D76
*$CALL GDXXRW transp.xlsx output=transp.gdx par=transp rng=transp!A1:D76

* Declare sets and parameters
Sets
    i 'farm types' /FT1*FT75/
    scenario 'carbon price scenario (value of b)' /CP1*CP100/
    j 'JM1=cover crops, JM2=grassland, JM3=reduced till' /JM1*JM3/;

Parameters
 soc(i,j) 'increase in SOC per hectare allocated to measure j in farm i'
* transp(i,j) 'Cost of transport to measure SOC or practices related to measure j in farm i'
 capgregor(i,j)' maximum area available to measure j in farm i';
$GDXIN soc.gdx
$LOAD soc
$GDXIN
$GDXIN capgregor.gdx
$LOAD capgregor
$GDXIN


Parameters
b_scenarios(scenario) 'carbon price'
n(i) 'Number of farms type i existing in Denmark'
capCC(i)
capTILL(i)
cap_crop(i)
transp2(i) 'transp cost per avg farm per region'
;
$call gdxxrw.exe data_b.xlsx par=b_scenarios rng=data_b!A2:B101 rdim=1 dset=scenario rng=data_b!A2:B101 rdim=1
$gdxin data_b.gdx
$load b_scenarios
$gdxIn
$call gdxxrw.exe data_n.xlsx par=n rng=data_n!A2:B76 rdim=1 dset=i rng=data_n!A2:B76 rdim=1
$gdxin data_n.gdx
$load n
$gdxin

$call gdxxrw.exe capCC.xlsx par=capCC rng=capCC!A2:B76 rdim=1 dset=i rng=capCC!A2:B76 rdim=1
$gdxin capCC.gdx
$load capCC
$gdxin

$call gdxxrw.exe capTILL.xlsx par=capTILL rng=capTILL!A2:B76 rdim=1 dset=i rng=capTILL!A2:B76 rdim=1
$gdxin capTILL.gdx
$load capTILL
$gdxin

$call gdxxrw.exe transp2.xlsx par=transp2 rng=transp!A2:B76 rdim=1 dset=i rng=transp!A2:B76 rdim=1
$gdxin transp2.gdx
$load transp2
$gdxin

$call gdxxrw.exe cap_crop.xlsx par=cap_crop rng=cap_crop!A2:B76 rdim=1 dset=i rng=cap_crop!A2:B76 rdim=1
$gdxin cap_crop.gdx
$load cap_crop
$gdxin




*display n b_scenarios;

Parameters
NB_RESULT(scenario) 'net benefits'
NR_RESULT(scenario) 'net revenue'
X_RESULT(scenario, i,j) 'sequestration'
A_RESULT(scenario, i,j) 'area'
MitCost_RESULT(scenario, i,j) 'Mitigation cost'
TranCost_RESULT(scenario, i,j) 'Private transaction cost'
MVR_RESULT(scenario, i,j) 'Public transaction costs'
SUBSIDY_COST_RESULT(scenario, i,j) 'payment given to farmers plus MRV costs in EURO'
ALL_Cost_RESULT(scenario, i,j)
Rent_RESULTS(scenario,i,j) 'mitigation plus private and public transaction costs'
Optimal_sub_result(scenario,i)
;

* Other parameters for the model
Parameters
epsilon 'small value to guard against rPower encountering zeros' /1e-6                            /
b         'marginal benefits - carbon price'
seq
CAP_max(j) / JM1 85.05, JM2 0.01, JM3 213.3   /
SOC_max(j) / JM1 0.34, JM2 3.41, JM3 0.2   /
CAP_min(j) / JM1 0.025, JM2 0.003 , JM3 1.02  /
SOC_min(j) / JM1 0.02, JM2 1.61 , JM3 0.18 /
cm_hec(j) 'marginal mitigation cost'                / JM1 6.6, JM2 42.5, JM3 0.48   /
tm(j)       'marginal transaction cost'           / JM1 154, JM2 0.9, JM3 18.4  /
*alpha    'Parameter for non_linearity in seq equation'      / 0.9                              /
mvr_hec_input  'Parameter in MVR cost equation for input policy instrument (not considering transport)' / 13.33  / 
mvr_hec_output 'Parameter in MVR cost equation for output policy instrument (not considering transport)'       /31.89 /;

   

Variable NB 'net benefits in EURO';

Positive Variables
X(i,j) 'sequestration in tco2eq'
A(i,j) 'area allocated for measure in hec'
MitCost(i,j) 'Mitigation cost in EURO'
TranCost(i,j) 'private TRC cost in EURO'
MVR(i,j) 'MVR costs in EURO'
Till(i)
Cover(i);

A.LO(i,j) =  0;
A.l(i,j) =  capgregor(i,j) * 0.01;
A.up(i,j) = max(1e-6, capgregor(i,j));
Till.up(i) = capTILL(i);
Cover.up(i) = capCC(i);

Equations
      obj 'net benefits function'
      area_tradeoff_covercrops(i) 'Trade-off constraint between grassland and cover crops'
      area_tradeoff_reduced_till(i) 'Trade-off constraint between grassland and reduced tillage';

area_tradeoff_covercrops(i).. A(i, 'JM1') + A(i, 'JM2') =e= Cover(i);
area_tradeoff_reduced_till(i).. A(i, 'JM2') + A(i, 'JM3') =e= Till(i);

obj.. NB   =e= SUM((i,j), n(i)*b*soc(i,j) * A(i,j)
                       - n(i) * cm_hec(j)*rPower(A(i,j),2)
                       - n(i) *tm(j)* rPower(soc(i,j) * A(i,j),2) 
                       - n(i)*(mvr_hec_output*A(i,j) +transp2(i)*A(i,j)));
Model Xoptout / all /;
Xoptout.scaleopt = 1;
Loop(scenario,
b = b_scenarios(scenario);

Solve Xoptout maximizing NB using nlp;


NB_RESULT(scenario) = NB.l;
NR_RESULT(scenario) = NB.l +SUM((i,j), n(i)*(mvr_hec_output*A.l(i,j) +transp2(i)*A.l(i,j)))  ;
X_RESULT(scenario, i,j) =  n(i) * soc(i,j) * A.l(i,j);
A_RESULT(scenario, i,j) =  n(i) * A.l(i,j);
MitCost_RESULT(scenario, i,j) = n(i)*(cm_hec(j)*rPower(A.l(i,j),2));
TranCost_RESULT(scenario, i,j) =n(i)*tm(j)*rPower(soc(i,j)*A.l(i,j),2);
MVR_RESULT(scenario, i,j)  =  n(i)*(mvr_hec_output*A.l(i,j) +transp2(i)*A.l(i,j));
ALL_Cost_RESULT(scenario, i,j)  = MVR_RESULT(scenario, i,j) + TranCost_RESULT(scenario, i,j) + MitCost_RESULT(scenario, i,j) ;
Rent_RESULTS(scenario,i,j) = b*n(i)*soc(i,j)*A.l(i,j) - TranCost_RESULT(scenario, i,j) - MitCost_RESULT(scenario, i,j);
Optimal_sub_result(scenario,i) =  (b - mvr_hec_output -transp2(i));
SUBSIDY_COST_RESULT(scenario, i,j) = b*n(i)*soc(i,j)*A.l(i,j) + MVR_RESULT(scenario, i,j);
);

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