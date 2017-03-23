$Title Hydrogen Station Model Optimization

$OnText

This model determines optimal behavior for a hydrogen station model
The model assumes price-taking behavior.  The intent of the model is to allow
either perfect knowledge or forecast prices at user-specified forecast horizons.

$OffText


Set
         interval                "Time intervals in study (min)"         /1 * 1440/
         totbanks                Total number of storage banks           /1 * 9/
         LPbanks(totbanks)       Number of low pressure banks            /1 * 3/
         MPbanks(totbanks)       Number of medium pressure banks         /4 * 6/
         HPbanks(totbanks)       Number of high pressure banks           /6 * 9/
         tot_comps               Total number of compressors             /1 * 4/
         MP_comps(tot_comps)     Number of medium pressure compressors   /1 * 2/
         HP_comps(tot_comps)     Number of high pressure compressors     /3 * 4/
         tot_dispensers          Total number of dispensers              /1 * 3/
         veh_num                 Total number of vehicles                /1 * 349/
;

Parameter
         interval_length                 length of each interval                           / 0.016666667 /
         min_per_hour                    minutes per hour                                  / 60 /
         max_storage_lvl(totbanks)       "maximum storage level by bank (kg)"              / 63,  63,  63,  28,  28,  28,  20,  20,  20  /
*         max_pressure_lvl(totbanks)      "maximum storage pressure by bank (bar)"          / 200, 200, 200, 415, 415, 415, 900, 900, 900 /
         comp_flowrate_max0(tot_comps)   "Compressor flowrate (kg/hour)"                   / 2.7, 2.7, 18, 18 /
         comp_flowrate_max(tot_comps)    "Compressor flowrate (kg/min)"
*         comp_MP_flowrate                "Medium pressure compressor flowrate (kg/sec)"   / 0.00075 /
*         comp_HP_flowrate                "High pressure compressor flowrate (kg/sec)"     / 0.005 /
         vehicle_fillrate(tot_dispensers) "Maximum fillrate to vehicles (kg/min)"          / 1, 1, 1 /
         comp_efficiency(tot_comps)      "Compressor efficiency (kWh/kg)"                  / 0.5, 0.5, 0.25, 0.25 /
*         comp_MP_efficiency              "Medium pressure compressor efficiency (kWh/kg)" / 0.5 /
*         comp_HP_efficiency              "High pressure compressor efficiency (kWh/kg)"   / 0.25 /
         pre_cool_base(tot_dispensers)   "Pre-cooling base energy consumption (kW/hr)"     / 0,0,0 /
         pre_cool_eff(tot_dispensers)    "Pre-cooling energy consumption (kWh/kg)"         / 0.1,0.1,0.1 /

         elec_purchase_price(interval)           "electricity price in each interval ($/MWh)"
         elec_sale_price(interval)               "electricity price in each interval ($/MWh)"
         elec_purchase_price_forecast(interval)  "electricity price forecast in each interval ($/MWh)"
         elec_sale_price_forecast(interval)      "electricity price forecast in each interval ($/MWh)"

         vehicle_initial_SOC(interval,veh_num)   "SOC when vehicles arrive"
         vehicle_final_SOC(interval,veh_num)     "Acceptable SOC when vehicles leave"
         vehicle_max_wait(intervalveh_num)       "Maximum time in which vehicles must be filled (min)"
;

Variables
         operating_profit                        "net profit or loss from operations ($)"
;

Binary Variables
         comp_active(interval,tot_comps)         binary variable indicating if compressors are active
;

Positive Variables
         comp_power_tot(interval,tot_comps)      "Total compressor power timeseries (kW)"
         comp_flow_tot(interval,tot_comps)       "Total compressor flow timeseries (kg/min)"
*         comp_power_MP(interval,MP_comps)        "Medium compressor power timeseries (kW)"
*         comp_power_HP(interval,HP_comps)        "Medium compressor power timeseries (kW)"
         storage_level_tanks(interval,totbanks)  "Storage level for each bank (kg)"
*         storage_level_LP(interval,LPbanks)      "LP Storage level for each bank (kg)"
*         storage_level_MP(interval,MPbanks)      "MP Storage level for each bank (kg)"
*         storage_level_HP(interval,HPbanks)      "HP Storage level for each bank (kg)"
         pre_cooling_power(interval)             "Power to operate precooling (kW)"
         vehicle_SOC(interval,veh_num)           "Vehicle state of charge (kg)"
;

Equations
         operating_profit_eqn                    equation that sums the operating profits for the facility
         storage_level_1(interval,totbanks)
         storage_level_2(interval,totbanks)

;


comp_flowrate_max(tot_comps) = comp_flowrate_max0(tot_comps) / min_per_hour;

elec_purchase_price_forecast(interval) = elec_purchase_price(interval);
elec_sale_price_forecast(interval) = elec_sale_price(interval);



operating_profit_eqn..
         operating_profit =e= sum(interval,
                         (elec_sale_price_forecast(interval) * (output_power_MW(interval)) * interval_length)
                       - (elec_purchase_price_forecast(interval) * input_power_MW(interval) * interval_length)
                       + H2_price(interval) * H2_sold(interval)
                       ;

* Ensure max tank level is never violated
storage_level_1(interval,totbanks)..
         storage_level_tanks(interval,totbanks) =l= max_storage_lvl(totbanks);

* Ensure max flowrate into tanks is not violated
storage_level_2(interval,totbanks)..
         storage_level_tanks(interval,totbanks)-storage_level_tanks(interval-1,totbanks) =l=  FLOWRATE;     make another eqn > flowrate


         storage_level_tanks(interval,"1")-comp_flow_tot(interval,tot_comps)*comp_active(interval,tot_comps) =l= comp_flowrate_max(tot_comps);
         storage_level_tanks(interval,"1")-comp_flow_tot(interval,tot_comps)*comp_active(interval,tot_comps) =l= comp_flowrate_max(tot_comps);


* Vehicle SOC is set once vehicle arrives
 $vehicle_arrival(interval,veh_num)>0
         vehicle_SOC(interval,veh_num) =e= vehicle_initial_SOC(interval,veh_num);


* Vehicle must leave with final SOC or greater
*(fix the $ statement to ensure that it is filled after wait time)
 $vehicle_arrival(interval,veh_num)=2
         vehicle_SOC(interval,veh_num) =g= vehicle_final_SOC(interval,veh_num);


* Vehicle fill equation
*(must determine how to select compressor and tanks)
         vehicle_SOC(interval,veh_num) =e= vehicle_SOC(interval-1,veh_num) + comp_flow_tot(interval,tot_comps);


****     set binary values for each flow timeseries and make the sum of the flow values = # compressors
* Storage tanks can either be filling, emptying, or doing nothing (can use two binarys, two veariables or continuous value neg, 0, pos)
* How to track flows?  Can track
* comp_flowrate is the max (can be less if needed)




Model Station_operation /all/
*set number of iterations before solver is terminated
option iterlim = 1000000;
*set number of seconds before the solver is terminated
option reslim = 6000;
*suppress listing of the equations in the listing file
option limrow = 0;
option limcol = 0;
*suppress listing of the solution in the listing file
option solprint = off;
option sysout = off;
*set optcr so that (best feasible - best possible) / (best feasible + 1e-10) < optcr,    default is 0.1 = 10%
option optcr=0.01;

*give initial values to all of the variables
output_power_MW.l(interval)      = 0;




Solve Station_operation using MIP maximizing operating_profit;



