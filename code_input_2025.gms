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
 capgregor(i,j)' maximum area available to measure j in farm i';
$GDXIN soc.gdx
$LOAD soc
$GDXIN
$GDXIN  capgregor.gdx
$LOAD  capgregor
$GDXIN


Parameters
b_scenarios(scenario) 'carbon price'
seq_scenarios(scenario)
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

$call gdxxrw.exe data_seq.xlsx par=seq_scenarios rng=data_seq!A2:B101 rdim=1 dset=scenario rng=data_seq!A2:B101 rdim=1
$gdxin data_seq.gdx
$load seq_scenarios
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

$call gdxxrw.exe cap_crop.xlsx par=cap_crop rng=cap_crop!A2:B76 rdim=1 dset=i rng=cap_crop!A2:B76 rdim=1
$gdxin cap_crop.gdx
$load cap_crop
$gdxin

$call gdxxrw.exe transp2.xlsx par=transp2 rng=transp!A2:B76 rdim=1 dset=i rng=transp!A2:B76 rdim=1
$gdxin transp2.gdx
$load transp2
$gdxin




display n seq_scenarios;

Parameters
NB_RESULT(scenario) 'net benefits'
NR_RESULT(scenario) 'net revenues'
X_RESULT(scenario, i,j) 'sequestration'
A_RESULT(scenario, i,j) 'area'
MitCost_RESULT(scenario, i,j) 'Mitigation cost'
TranCost_RESULT(scenario, i,j) 'Private transaction cost'
MVR_RESULT(scenario, i,j) 'Public transaction costs'
ALL_Cost_RESULT(scenario, i,j) 'mitigation plus private and public transaction costs'
SUBSIDY_COST_RESULT(scenario, i,j) 'payment given to farmers plus MRV costs in EURO'
Optimal_sub_result(scenario,j) 'value of uniform subsidy, per measure in EURO/ha'
Rent_RESULTS(scenario,i,j)
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
*mu_a(i,j) 'lagrange multiplier area mu'
*mu_i1(i) 'lagrange multiplier grasscc'
*mu_i2(i) 'lagrange multiplier grasstil'
Till(i)
Cover(i)
s(j) 'uniform subsidy';



A.LO(i,j) =  0;
A.l(i,j) =   capgregor(i,j) * 0.01;
A.up(i,j) = max(1e-6, capgregor(i,j));
s.LO(j) = 0;
s.l(j) = (2 * cm_hec(j) *CAP_max(j)* 0.01)
+ (2  * tm(j) * Power(SOC_max(j),2)* CAP_max(j)* 0.01);
s.up(j) = 1000;
Till.up(i) = capTILL(i);
Cover.up(i) = capCC(i);

Equations
      obj 'net benefits function'
      responseeq(i,j)
      area_tradeoff_covercrops(i) 'Trade-off constraint between grassland and cover crops'
      area_tradeoff_reduced_till(i) 'Trade-off constraint between grassland and reduced tillage';

area_tradeoff_covercrops(i).. A(i, 'JM1') + A(i, 'JM2') =e= Cover(i);
area_tradeoff_reduced_till(i).. A(i, 'JM2') + A(i, 'JM3') =e= Till(i);

obj.. NB   =e= SUM((i,j), n(i)*b*soc(i,j)*A(i,j)
                       -n(i)*s(j)*A(i,j)
                       - n(i)*(mvr_hec_input*A(i,j) +transp2(i)*A(i,j)));

responseeq(i,j)..(2 * cm_hec(j) * A(i,j))
      + (2  * tm(j) * Power(soc(i,j),2)* A(i,j) )
=l=s(j)
        ;
*seq_eq.. sum((i,j),n(i) * soc(i,j) * rPower(A(i,j), alpha)) =g= seq  ;
                       

Model XoptUniform / all /;
XoptUniform.scaleopt = 1;
*option nlp = BARON
Loop(scenario,
b = b_scenarios(scenario);
*seq = seq_scenarios(scenario);

Solve XoptUniform maximizing NB using nlp;
NB_RESULT(scenario) = NB.l;
NR_RESULT(scenario) = SUM((i,j), n(i)*s.l(j)*A.l(i,j) -n(i)*(cm_hec(j)*rPower(A.l(i,j),2)) - n(i)*tm(j)*rPower(soc(i,j)*A.l(i,j),2) )  ;
X_RESULT(scenario, i,j) =  n(i) * soc(i,j) * A.l(i,j);
A_RESULT(scenario, i,j) =  n(i) * A.l(i,j);
MitCost_RESULT(scenario, i,j) = n(i)*(cm_hec(j)*rPower(A.l(i,j),2));
TranCost_RESULT(scenario, i,j) =n(i)*tm(j)*rPower(soc(i,j)*A.l(i,j),2);
MVR_RESULT(scenario, i,j)  =  n(i)*(mvr_hec_input*A.l(i,j) +transp2(i)*A.l(i,j));
Rent_RESULTS(scenario,i,j) = s.l(j)*n(i)*A.l(i,j) - TranCost_RESULT(scenario, i,j) - MitCost_RESULT(scenario, i,j);
ALL_Cost_RESULT(scenario, i,j)  = MVR_RESULT(scenario, i,j) + TranCost_RESULT(scenario, i,j) + MitCost_RESULT(scenario, i,j);
SUBSIDY_COST_RESULT(scenario, i,j) = s.l(j)*A.l(i,j)*n(i) + MVR_RESULT(scenario, i,j);
Optimal_sub_result(scenario,j) = s.l(j)
);


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

