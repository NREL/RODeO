$Title Hydrogen Station Model Optimization

$OnText

This model determines optimal behavior for a hydrogen station model
The model assumes price-taking behavior.  The intent of the model is to allow
either perfect knowledge or forecast prices at user-specified forecast horizons.

$OffText

*set defaults for parameters usually passed in by a calling program
*so that this script can be run directly if desired

$if not set elec_rate_instance     $set elec_rate_instance     574dbcac5457a3d3795e629f_hourly
$if not set add_param_instance     $set add_param_instance     additional_parameters_hourly
$if not set ren_prof_instance      $set ren_prof_instance      renewable_profiles_none_hourly
$if not set load_prof_instance     $set load_prof_instance     basic_building_0_hourly
$if not set outdir                 $set outdir                 RODeO\Output\Default
$if not set indir                  $set indir                  RODeO\Input_files\Default3\hourly_tariffs
$call 'if not exist %outdir%\nul mkdir %outdir%'

$if not set gas_price_instance     $set gas_price_instance     NA
$if not set zone_instance          $set zone_instance          NA
$if not set year_instance          $set year_instance          NA

$if not set input_cap_instance     $set input_cap_instance     1000
$if not set output_cap_instance    $set output_cap_instance    0
$if not set input_LSL_instance     $set input_LSL_instance     0.1
$if not set output_LSL_instance    $set output_LSL_instance    0
$if not set Input_start_cost_inst  $set Input_start_cost_inst  0.00001
$if not set Output_start_cost_inst $set Output_start_cost_inst 0
$if not set input_efficiency_inst  $set input_efficiency_inst  0.613668913
$if not set output_efficiency_inst $set output_efficiency_inst 1
$if not set input_cap_cost_inst    $set input_cap_cost_inst    1200000
$if not set output_cap_cost_inst   $set output_cap_cost_inst   0
$if not set input_FOM_cost_inst    $set input_FOM_cost_inst    8400
$if not set output_FOM_cost_inst   $set output_FOM_cost_inst   0
$if not set input_VOM_cost_inst    $set input_VOM_cost_inst    0
$if not set output_VOM_cost_inst   $set output_VOM_cost_inst   0
$if not set input_lifetime_inst    $set input_lifetime_inst    20
$if not set output_lifetime_inst   $set output_lifetime_inst   0
$if not set interest_rate_inst     $set interest_rate_inst     0.07

$if not set in_heat_rate_instance  $set in_heat_rate_instance  0
$if not set out_heat_rate_instance $set out_heat_rate_instance 0
$if not set storage_cap_instance   $set storage_cap_instance   8
$if not set reg_cost_instance      $set reg_cost_instance      0
$if not set min_runtime_instance   $set min_runtime_instance   0
$if not set ramp_penalty_instance  $set ramp_penalty_instance  0

* Next two values change the resoultion of the optimization
*    hourly: 8760, 1     15min: 35040, 0.25       5min: 105120, 0.08333333333
$if not set op_period_instance     $set op_period_instance     8760
$if not set int_length_instance    $set int_length_instance    1

$if not set lookahead_instance     $set lookahead_instance     0
$if not set energy_only_instance   $set energy_only_instance   0
$if not set file_name_instance     $set file_name_instance     "hourly_PGE_E20_no_ramp_penalty"
$if not set H2_consume_adj_inst    $set H2_consume_adj_inst    0.9
$if not set H2_price_instance      $set H2_price_instance      6
$if not set H2_use_instance        $set H2_use_instance        1
$if not set base_op_instance       $set base_op_instance       0
$if not set NG_price_adj_instance  $set NG_price_adj_instance  1
$if not set Renewable_MW_instance  $set Renewable_MW_instance  0
$if not set CF_opt_instance        $set CF_opt_instance        0

* Next values are used to initialize for real-time operation and shorten the run-time
*    To turn off set current_int = -1, next_int = 1 and max_int_instance = Inf
$if not set current_int_instance   $set current_int_instance   -1
$if not set next_int_instance      $set next_int_instance      1
$if not set current_stor_intance   $set current_stor_intance   0.5
$if not set current_max_instance   $set current_max_instance   0.8
$if not set max_int_instance       $set max_int_instance       Inf
$if not set read_MPC_file_instance $set read_MPC_file_instance 0

*        energy_only_instance = 0, 1 (0 = Energy only operation, 1 = All ancillary services included)
*        H2_consume_adj_inst = adjusts the amount of H2 consumed from the uploaded "H2_consumed" file as capacity factor (%)
*        H2_price_instance = adjusts the value of hydrogen from the uploaded "H2_price" file in $/kg
*        H2_use_instance = 0, 1, or 2 for non-elec use of hydrogen  (0=no extra H2, 1=constant profile, 2=daily requirement)
*        base_op_instance = 0, 1 (0 = normal operation, 1 = baseload input operation)
*        base_pwr_instance = fraction of power setting   (0.198346561 for 100 and 0.793386238 for 400)   (revised: 0.7935049289 80%CF, eff=0.7)
*        NG_avg_price_instance = multiplier for adjusting natural gas price (i.e., NG_price = NG_price * NG_price_adj     (AVG = 6.8598 for ERCOT 2006, 4.21118 for CAISO 0711 2022, 3.61115 for CAISO 2012)
*        CF_opt_instance = 0, 1 for selecting optimization method (0 runs with fixed CF, 1 finds optimal CF)

Files
         input_echo_file /%outdir%\Storage_dispatch_inputs_%file_name_instance%_%storage_cap_instance%hrs.csv/
         results_file    /%outdir%\Storage_dispatch_results_%file_name_instance%_%storage_cap_instance%hrs.csv/
         summary_file    /%outdir%\Storage_dispatch_summary_%file_name_instance%_%storage_cap_instance%hrs.csv/
         RT_out_file    /%outdir%\Real_time_output_values.csv/
;

Sets
         interval          hourly time intervals in study period /1 * %op_period_instance%/
         months            months in study period                /1 * 12/
         days              number of daily periods in study      /1 * 365/
         timed_dem_period  number of timed demand periods        /1 * 6/
         input_value       single value
         LPbanks           Number of low pressure banks          /1 * 4/
         MPbanks           Number of medium pressure banks       /1 * 2/
         HPbanks           Number of high pressure banks         /1 /
;

Parameters
         elec_purchase_price(interval)           "electricity price in each interval ($/MWh)"
         elec_sale_price(interval)               "electricity price in each interval ($/MWh)"
         regup_price(interval)                   "price paid for regulation up ancillary service ($/MW)"
         regdn_price(interval)                   "price paid for regulation down ancillary service ($/MW)"
         spinres_price(interval)                 "price paid for spinning reserve ancillary service ($/MW)"
         nonspinres_price(interval)              "price paid for nonspinning reserve ancillary service ($/MW)"
         NG_price(interval)                      "natural gas price in each interval ($/MMBtu)"
         elec_purchase_price_forecast(interval)  "electricity price forecast in each interval ($/MWh)"
         elec_sale_price_forecast(interval)      "electricity price forecast in each interval ($/MWh)"
         H2_consumed(interval)                   "Amount of H2 consumed each interval (kg)"
         H2_price(interval)                      "Price for Hydrogen for each interval ($/kg)"
         input_power_baseload(interval)          "Establishes the input power signal under baseload operation (MW)"
         renewable_signal(interval)              "Renewable generation signal (MW) (range from 0 to 1)"
         meter_mnth_chg(interval)                "monthly charge for meter ($/meter/month)"
         Renewable_power(interval)               "Scaled renewable signal based on 'Renewable_MW'"
         Fixed_dem(months)                       "Fixed demand charge $/MW-month"
         Timed_dem(timed_dem_period)             "Timed demand charge $/MW-month"
         Load_profile(interval)                  "Load profile (MW)"
;

* Adjust the files that are loaded
$include /%indir%\%elec_rate_instance%.txt
$include /%indir%\%add_param_instance%.txt
$include /%indir%\%ren_prof_instance%.txt
$include /%indir%\%load_prof_instance%.txt

Scalars
         interval_length length of each interval (hours) /%int_length_instance%/
         operating_period_length number of intervals in each operating period (rolling solution window) /%op_period_instance%/
* 1 week = 168 hourly intervals
* set operating period length to full year length (8760 or 8784) to do full-year optimization without rolling window
         look_ahead_length number of additional intervals to look past the current operating period /%lookahead_instance%/

         output_capacity_MW output capacity of storage facility (MW)  /%output_cap_instance%/
         input_capacity_MW  input capacity of storage facility (MW)  /%input_cap_instance%/
         storage_capacity_hours storage capacity of storage facility (hours at rated INPUT capacity) /%storage_cap_instance%/

         output_LSL_fraction output lower sustainable limit as a fraction of the output capacity /%output_LSL_instance%/
         output_regup_limit_fraction regulation up capacity limit as a fraction of the output capacity (value set below)
         output_regdn_limit_fraction regulation down capacity limit as a fraction of the output capacity (value set below)
         output_spinres_limit_fraction spinning reserve capacity limit as a fraction of the output capacity (value set below)
         output_nonspinres_limit_fraction nonspinning reserve capacity limit as a fraction of the output capacity (value set below)

         input_LSL_fraction input lower sustainable limit as a fraction of the input capacity /%input_LSL_instance%/
         input_regup_limit_fraction regulation up capacity limit as a fraction of the input capacity (value set below)
         input_regdn_limit_fraction regulation down capacity limit as a fraction of the input capacity (value set below)
         input_spinres_limit_fraction spinning reserve capacity limit as a fraction of the input capacity (value set below)
         input_nonspinres_limit_fraction nonspinning reserve capacity limit as a fraction of the input capacity (value set below)

         input_efficiency "efficiency of storage mechanism (LHV)" /%input_efficiency_inst%/
         output_efficiency "efficiency of conversion back to electricity (LHV)" /%output_efficiency_inst%/
         input_heat_rate "heat rate of facility (MMBtu/MWh produced)" /%in_heat_rate_instance%/
         output_heat_rate "heat rate of facility (MMBtu/MWh produced)" /%out_heat_rate_instance%/
         input_startup_cost "cost to startup the input side of the facility ($/MW-start)" /%Input_start_cost_inst%/
         output_startup_cost "cost to startup the output side of the facility ($/MW-start)" /%Output_start_cost_inst%/

         input_cap_cost "upfront capital cost ($/MW)" /%input_cap_cost_inst%/
         output_cap_cost "upfront capital cost ($/MW)" /%output_cap_cost_inst%/
         input_FOM_cost "upfront capital cost ($/MW-year)" /%input_FOM_cost_inst%/
         output_FOM_cost "upfront capital cost ($/MW-year)" /%output_FOM_cost_inst%/
         input_VOM_cost "upfront capital cost ($/MWh)" /%input_VOM_cost_inst%/
         output_VOM_cost "upfront capital cost ($/MWh)" /%output_VOM_cost_inst%/

         input_lifetime "equipment lifetime (years)" /%input_lifetime_inst%/
         output_lifetime "equipment lifetime (years)" /%output_lifetime_inst%/

         interest_rate "interest rate on debt" /%interest_rate_inst%/

         VOM_cost "variable O&M cost associated with selling electricity ($/MWh)" /0/
         reg_cost "variable costs associated with providing regulation ($/MW-h)" /%reg_cost_instance%/

         H2_use "Determines if Hydrogen outputted as a product or not (toggle)" /%H2_use_instance%/
         H2_price_adj "Determines if Hydrogen outputted as a product or not" /%H2_price_instance%/
         H2_consumed_adj "Determines if Hydrogen outputted as a product or not" /%H2_consume_adj_inst%/
         H2_LHV "Lower Heating Value of Hydrogen (MWh/kg)" /0.033322222/
         H2_HHV "Higher Heating Value of Hydrogen (MWh/kg)" /0.039411111/
         baseload_operation "Determines if input is operated with baseload duty cycle" /%base_op_instance%/
         NG_price_adj "Average price of natural gas ($/MMBTU)" /%NG_price_adj_instance%/
         Renewable_MW "Installed renewable capacity (MW)" /%Renewable_MW_instance%/
         CF_opt "Select optimization criteria for system" /%CF_opt_instance%/

         min_output_on_intervals 'minimum number of intervals the output side of the facility can be on at a time' /%min_runtime_instance%/
         min_input_on_intervals  'minimum number of intervals the input side of the facility can be on at a time' /%min_runtime_instance%/

         current_interval        'current interval for real-time optimization runs'                              /%current_int_instance%/
         next_interval           'next interval for real-time optimization runs'                                 /%next_int_instance%/
         current_storage_lvl     'current storage level for real-time optimization runs (0-100%, 0-1)'           /%current_stor_intance%/
         current_monthly_max     'current monthly maximum demand for real-time optimization runs (0-100%, 0-1)'  /%current_max_instance%/
         max_interval            'maximum interval for real-time optimization runs'                              /%max_int_instance%/
         read_MPC_file           'read controller values from excel file'                                        /%read_MPC_file_instance%/
         ramp_penalty            'set ramp penalty for input and output devices'                                 /%ramp_penalty_instance%/
;

Set
         next_int(interval)      Next interval           /%next_int_instance%/
;

* Loads predictive controller values from excel file
$call GDXXRW.exe I=%indir%\controller_input_values.xlsx O=%indir%\controller_input_values.gdx par=current_interval2 rng=A2 Dim=0
scalar current_interval2
$GDXIN %indir%\controller_input_values.gdx
$LOAD current_interval2
$GDXIN

$call GDXXRW.exe I=%indir%\controller_input_values.xlsx O=%indir%\controller_input_values.gdx par=next_interval2 rng=B2 Dim=0
scalar next_interval2
$GDXIN %indir%\controller_input_values.gdx
$LOAD next_interval2
$GDXIN

$call GDXXRW.exe I=%indir%\controller_input_values.xlsx O=%indir%\controller_input_values.gdx par=current_storage_lvl2 rng=C2 Dim=0
scalar current_storage_lvl2
$GDXIN %indir%\controller_input_values.gdx
$LOAD current_storage_lvl2
$GDXIN

$call GDXXRW.exe I=%indir%\controller_input_values.xlsx O=%indir%\controller_input_values.gdx par=current_monthly_max2 rng=D2 Dim=0
scalar current_monthly_max2
$GDXIN %indir%\controller_input_values.gdx
$LOAD current_monthly_max2
$GDXIN

$call GDXXRW.exe I=%indir%\controller_input_values.xlsx O=%indir%\controller_input_values.gdx par=max_interval2 rng=E2 Dim=0
scalar max_interval2
$GDXIN %indir%\controller_input_values.gdx
$LOAD max_interval2
$GDXIN

if (read_MPC_file=1,
         current_interval = current_interval2;
         next_interval = next_interval2;
         current_storage_lvl = current_storage_lvl2;
         current_monthly_max = current_monthly_max2;
         max_interval = max_interval2;
else
);

*reseed the random number generator
execseed = 1 + gmillisec(jnow);
*generate an imperfect price forecast
*elec_price_forecast(interval) = elec_price(interval) * uniform(0.95, 1.05);
elec_purchase_price_forecast(interval) = elec_purchase_price(interval);
elec_sale_price_forecast(interval) = elec_sale_price(interval);

* Scale renewable signal to desired installed capacity level
Renewable_power(interval) = renewable_signal(interval) * Renewable_MW;

* Adjust the lifetime if it is equal to zero and zero the cost components (i.e., raising to the power of 0 throws an error)
if (output_lifetime=0, output_lifetime=1; output_cap_cost=0; output_FOM_cost=0; output_VOM_cost=0; );
if ( input_lifetime=0,  input_lifetime=1;  input_cap_cost=0;  input_FOM_cost=0;  input_VOM_cost=0; );

*check to make sure operating period length is not longer than the number of intervals in the input file
if ( operating_period_length > card(interval), operating_period_length = card(interval) );

*set values for allowable AS capacities
if (%energy_only_instance%=1,
         output_regup_limit_fraction      = 0;
         output_regdn_limit_fraction      = 0;
         output_spinres_limit_fraction    = 0;
         output_nonspinres_limit_fraction = 0;

         input_regup_limit_fraction       = 0;
         input_regdn_limit_fraction       = 0;
         input_spinres_limit_fraction     = 0;
         input_nonspinres_limit_fraction  = 0;
elseif %base_op_instance%=1,
         output_regup_limit_fraction      = 1;
         output_regdn_limit_fraction      = 1;
         output_spinres_limit_fraction    = 1;
         output_nonspinres_limit_fraction = 1;

         input_regup_limit_fraction       = 0;
         input_regdn_limit_fraction       = 0;
         input_spinres_limit_fraction     = 0;
         input_nonspinres_limit_fraction  = 0;
else
         output_regup_limit_fraction      = 1;
         output_regdn_limit_fraction      = 1;
         output_spinres_limit_fraction    = 1;
         output_nonspinres_limit_fraction = 1;

         input_regup_limit_fraction       = 1;
         input_regdn_limit_fraction       = 1;
         input_spinres_limit_fraction     = 1;
         input_nonspinres_limit_fraction  = 1;
);

*scalars for rolling window implementation
*note that the rolling window is the current operating period plus a look-ahead
*period to give residual value to stored energy at the end of the current
*operating period
Scalars
         number_of_solves                number of times the model will be solved after moving the solve window
         solve_index                     index used to loop through all of the solves
         operating_period_min_index      value of first index in current operating period
         operating_period_max_index      value of last index in current operating period
         rolling_window_min_index        value of first index in current rolling window
         rolling_window_max_index        value of last index in current rolling window
;

Positive Variables
         output_power_MW(interval)       output capacity actually supplying power to the grid (MW)
         output_regup_MW(interval)       output capacity committed for regulation up ancillary service (MW)
         output_regdn_MW(interval)       output capacity committed for regulation down ancillary service (MW)
         output_spinres_MW(interval)     output capacity committed for spinning reserve ancillary service (MW)
         output_nonspinres_MW(interval)  output capacity committed for nonspinning reserve ancillary service (MW)

         input_power_MW(interval)        input capacity actually buying power from the grid (MW)
         input_regup_MW(interval)        input capacity committed for regulation up ancillary service (MW)
         input_regdn_MW(interval)        input capacity committed for regulation down ancillary service (MW)
         input_spinres_MW(interval)      input capacity committed for spinning reserve ancillary service (MW)
         input_nonspinres_MW(interval)   input capacity committed for nonspinning reserve ancillary service (MW)
         input_power_MW_ren(interval)    actual amount of renewable generation used (MWh)
         input_power_MW_non_ren(interval) actual amount of non renewable generation used (MWh)

         storage_level_MWh(interval) amount of energy stored at the end of each interval (MWh)

         H2_sold(interval)       Determines how much hydrogen is sold
         H2_sold_daily(days)     Represents how much hydrogen is sold each day

         Fixed_cap(months)       Sets peak capacity for the fixed demand charges (MW)
         cap_1(months)           Sets max capacity for the month (MW)
         cap_2(months)           Sets max capacity for the month (MW)
         cap_3(months)           Sets max capacity for the month (MW)
         cap_4(months)           Sets max capacity for the month (MW)
         cap_5(months)           Sets max capacity for the month (MW)
         cap_6(months)           Sets max capacity for the month (MW)

         Hydrogen_fraction       Sets the capacity factor

         input_ramp_pos(interval)  Positive ramp rate constraint (used to linearize absolute value)
         input_ramp_neg(interval)  Negative ramp rate constraint (used to linearize absolute value)
         output_ramp_pos(interval) Positive ramp rate constraint (used to linearize absolute value)
         output_ramp_neg(interval) Negative ramp rate constraint (used to linearize absolute value)
;

Binary Variables
         output_active(interval) binary variable indicating if the output system is active
         input_active(interval) binary variable indicating if the input system is active

         output_start(interval) binary variable indicating if the output system started up in this interval
         input_start(interval) binary variable indicating if the input system started up in this interval
;

Variables
         operating_profit "net profit or loss from operations, before paying for capital costs ($)"
;

Equations
         operating_profit_eqn equation that sums the operating profits for the storage facility

         output_LSL_eqn(interval) equation that limits the lower sustainable limit for the output of the facility
         output_capacity_limit_eqn(interval) equation that limits the upper limit for the output of the facility
         output_regup_limit_eqn(interval) equation that limits the amount of regulation up the output side of the facilty can offer
         output_regdn_limit_eqn(interval) equation that limits the amount of regulation down the output side of the facilty can offer
         output_spinres_limit_eqn(interval) equation that limits the amount of spinning reserve the output side of the facilty can offer
         output_nonspinres_limit_eqn(interval) equation that limits the amount of nonspinning reserve the output side of the facility can offer

         input_pwr_eqn(interval) equation that defines the input power for baseload operation
         input_LSL_eqn(interval) equation that limits the lower sustainable limit for the input of the facility
         input_capacity_limit_eqn(interval) equation that limits the upper limit for the input of the facility
         input_capacity_limit_eqn2(interval) equation that limits the upper limit for the input of the facility
         input_ren_contribution(interval) equation that sets the amount of renewable gen consumed
         input_regup_limit_eqn(interval) equation that limits the amount of regulation up the input side of the facilty can offer
         input_regdn_limit_eqn(interval) equation that limits the amount of regulation down the input side of the facilty can offer
         input_spinres_limit_eqn(interval) equation that limits the amount of spinning reserve the input side of the facilty can offer
         input_nonspinres_limit_eqn(interval) equation that limits the amount of nonspinning reserve the input side of the facility can offer

         storage_level_accounting_eqn(interval) equation that keeps track of how much energy is in storage on an output power basis for storage or pump technologies (MWh)
         storage_level_accounting_eqn2(interval) equation that keeps track of how much energy is in storage on an output power basis for generation only technologies (MWh)
         storage_level_limit_eqn(interval) equation that limits the storage level to the maximum capacity of the storage facility including ancillary services (MWh)
         storage_level_limit_eqn2(interval) equation that limits the storage level to the maximum capacity of the storage facility including ancillary services (MWh)
         storage_level_limit_eqn3(interval) equation that limits the storage level to the maximum capacity of the storage facility including ancillary services (MWh)

         output_startup_eqn(interval) equation that determines if the output side of the facility started up
         input_startup_eqn(interval) equation that determines if the input side of the facility started up

         H2_output_limit_eqn(days) equation that calculates the daily H2 consumed from the hourly production vector
         H2_output_limit_eqn2(days) equation that limits the maximum hydrogen production per day
         H2_output_limit_eqn3(interval) equation that ensures the H2_sold = H2_consumed

         output_min_on_eqn1(interval) equation that requires that if the output unit turns off during the first few intervals of the year it must stay on for all of the previous intervals
         output_min_on_eqn2(interval) equation that enforces minimum on-time for most of the intervals of the year
         output_min_on_eqn3(interval) equation that enforces minimum on-time for the ending intervals of the year
         input_min_on_eqn1(interval)  equation that requires that if the input unit turns off during the first few intervals of the year it must stay on for all of the previous intervals
         input_min_on_eqn2(interval)  equation that enforces minimum on-time for most of the intervals of the year
         input_min_on_eqn3(interval)  equation that enforces minimum on-time for the ending intervals of the year

         Fixed_dem_Jan(Month_Jan)     equation that enforces fixed demand charge in given month
         Fixed_dem_Feb(Month_Feb)     equation that enforces fixed demand charge in given month
         Fixed_dem_Mar(Month_Mar)     equation that enforces fixed demand charge in given month
         Fixed_dem_Apr(Month_Apr)     equation that enforces fixed demand charge in given month
         Fixed_dem_May(Month_May)     equation that enforces fixed demand charge in given month
         Fixed_dem_Jun(Month_Jun)     equation that enforces fixed demand charge in given month
         Fixed_dem_Jul(Month_Jul)     equation that enforces fixed demand charge in given month
         Fixed_dem_Aug(Month_Aug)     equation that enforces fixed demand charge in given month
         Fixed_dem_Sep(Month_Sep)     equation that enforces fixed demand charge in given month
         Fixed_dem_Oct(Month_Oct)     equation that enforces fixed demand charge in given month
         Fixed_dem_Nov(Month_Nov)     equation that enforces fixed demand charge in given month
         Fixed_dem_Dec(Month_Dec)     equation that enforces fixed demand charge in given month

         Jan_1_eqn(Jan_1)       equation that enforces timed demand charge in given month
         Feb_1_eqn(Feb_1)       equation that enforces timed demand charge in given month
         Mar_1_eqn(Mar_1)       equation that enforces timed demand charge in given month
         Apr_1_eqn(Apr_1)       equation that enforces timed demand charge in given month
         May_1_eqn(May_1)       equation that enforces timed demand charge in given month
         Jun_1_eqn(Jun_1)       equation that enforces timed demand charge in given month
         Jul_1_eqn(Jul_1)       equation that enforces timed demand charge in given month
         Aug_1_eqn(Aug_1)       equation that enforces timed demand charge in given month
         Sep_1_eqn(Sep_1)       equation that enforces timed demand charge in given month
         Oct_1_eqn(Oct_1)       equation that enforces timed demand charge in given month
         Nov_1_eqn(Nov_1)       equation that enforces timed demand charge in given month
         Dec_1_eqn(Dec_1)       equation that enforces timed demand charge in given month

         Jan_2_eqn(Jan_2)       equation that enforces timed demand charge in given month
         Feb_2_eqn(Feb_2)       equation that enforces timed demand charge in given month
         Mar_2_eqn(Mar_2)       equation that enforces timed demand charge in given month
         Apr_2_eqn(Apr_2)       equation that enforces timed demand charge in given month
         May_2_eqn(May_2)       equation that enforces timed demand charge in given month
         Jun_2_eqn(Jun_2)       equation that enforces timed demand charge in given month
         Jul_2_eqn(Jul_2)       equation that enforces timed demand charge in given month
         Aug_2_eqn(Aug_2)       equation that enforces timed demand charge in given month
         Sep_2_eqn(Sep_2)       equation that enforces timed demand charge in given month
         Oct_2_eqn(Oct_2)       equation that enforces timed demand charge in given month
         Nov_2_eqn(Nov_2)       equation that enforces timed demand charge in given month
         Dec_2_eqn(Dec_2)       equation that enforces timed demand charge in given month

         Jan_3_eqn(Jan_3)       equation that enforces timed demand charge in given month
         Feb_3_eqn(Feb_3)       equation that enforces timed demand charge in given month
         Mar_3_eqn(Mar_3)       equation that enforces timed demand charge in given month
         Apr_3_eqn(Apr_3)       equation that enforces timed demand charge in given month
         May_3_eqn(May_3)       equation that enforces timed demand charge in given month
         Jun_3_eqn(Jun_3)       equation that enforces timed demand charge in given month
         Jul_3_eqn(Jul_3)       equation that enforces timed demand charge in given month
         Aug_3_eqn(Aug_3)       equation that enforces timed demand charge in given month
         Sep_3_eqn(Sep_3)       equation that enforces timed demand charge in given month
         Oct_3_eqn(Oct_3)       equation that enforces timed demand charge in given month
         Nov_3_eqn(Nov_3)       equation that enforces timed demand charge in given month
         Dec_3_eqn(Dec_3)       equation that enforces timed demand charge in given month

         Jan_4_eqn(Jan_4)       equation that enforces timed demand charge in given month
         Feb_4_eqn(Feb_4)       equation that enforces timed demand charge in given month
         Mar_4_eqn(Mar_4)       equation that enforces timed demand charge in given month
         Apr_4_eqn(Apr_4)       equation that enforces timed demand charge in given month
         May_4_eqn(May_4)       equation that enforces timed demand charge in given month
         Jun_4_eqn(Jun_4)       equation that enforces timed demand charge in given month
         Jul_4_eqn(Jul_4)       equation that enforces timed demand charge in given month
         Aug_4_eqn(Aug_4)       equation that enforces timed demand charge in given month
         Sep_4_eqn(Sep_4)       equation that enforces timed demand charge in given month
         Oct_4_eqn(Oct_4)       equation that enforces timed demand charge in given month
         Nov_4_eqn(Nov_4)       equation that enforces timed demand charge in given month
         Dec_4_eqn(Dec_4)       equation that enforces timed demand charge in given month

         Jan_5_eqn(Jan_5)       equation that enforces timed demand charge in given month
         Feb_5_eqn(Feb_5)       equation that enforces timed demand charge in given month
         Mar_5_eqn(Mar_5)       equation that enforces timed demand charge in given month
         Apr_5_eqn(Apr_5)       equation that enforces timed demand charge in given month
         May_5_eqn(May_5)       equation that enforces timed demand charge in given month
         Jun_5_eqn(Jun_5)       equation that enforces timed demand charge in given month
         Jul_5_eqn(Jul_5)       equation that enforces timed demand charge in given month
         Aug_5_eqn(Aug_5)       equation that enforces timed demand charge in given month
         Sep_5_eqn(Sep_5)       equation that enforces timed demand charge in given month
         Oct_5_eqn(Oct_5)       equation that enforces timed demand charge in given month
         Nov_5_eqn(Nov_5)       equation that enforces timed demand charge in given month
         Dec_5_eqn(Dec_5)       equation that enforces timed demand charge in given month

         Jan_6_eqn(Jan_6)       equation that enforces timed demand charge in given month
         Feb_6_eqn(Feb_6)       equation that enforces timed demand charge in given month
         Mar_6_eqn(Mar_6)       equation that enforces timed demand charge in given month
         Apr_6_eqn(Apr_6)       equation that enforces timed demand charge in given month
         May_6_eqn(May_6)       equation that enforces timed demand charge in given month
         Jun_6_eqn(Jun_6)       equation that enforces timed demand charge in given month
         Jul_6_eqn(Jul_6)       equation that enforces timed demand charge in given month
         Aug_6_eqn(Aug_6)       equation that enforces timed demand charge in given month
         Sep_6_eqn(Sep_6)       equation that enforces timed demand charge in given month
         Oct_6_eqn(Oct_6)       equation that enforces timed demand charge in given month
         Nov_6_eqn(Nov_6)       equation that enforces timed demand charge in given month
         Dec_6_eqn(Dec_6)       equation that enforces timed demand charge in given month

         H2_CF_eqn(interval)    equation to adjust the CF for H2 equipment
         H2_CF_eqn2             limit Hydrogen_fraction
         H2_CF_eqn3             limit Hydrogen_fraction

         RT_eqn1(interval)      equation to set current power values to enable running in real-time
         RT_eqn2(interval)      equation to set current storage values to enable running in real-time
         RT_eqn3(interval)      equation to set power values to shorten running in real-time
         RT_eqn4(interval)      equation to set storage values to shorten running in real-time

         output_ramp_eqn(interval)       equation to limit ramping with penalty price
         input_ramp_eqn(interval)        equation to limit ramping with penalty price

**         one_active_device_eqn(interval) equation to ensure that both generator and pump cannot be simultaneously active
;

* Adjusts the price of natural gas to the selected value "NG_price_adj"
NG_price(interval) = NG_price(interval) * NG_price_adj;

* Check to see if H2 will be exported for this analysis (i.e., H2 = 1 or 2)
if (H2_use = 0,
         H2_consumed(interval) = H2_consumed(interval) * 0;
         H2_price(interval)    = H2_price(interval)*0;
elseif H2_use=1,
         H2_price(interval) = H2_price(interval) * H2_price_adj;
         if (CF_opt=0,
                 H2_consumed(interval) = H2_consumed(interval) * H2_consumed_adj * input_capacity_MW * input_efficiency / H2_LHV * 24 * interval_length;
         elseif CF_opt=1,
                 H2_consumed_adj = input_capacity_MW * input_efficiency / H2_LHV *24;
         );
elseif H2_use=2,
);





*
* Input files ::: identifier for station, time, vehicle inital tank fill, vehicle desired tank fill, vehicle max wait time (opt.)
*
* To Do: Load
*
*
*

Set
         LPbanks         Number of low pressure banks    /1 * 2/
         MPbanks         Number of low pressure banks    /1 * 3/
         HPbanks         Number of low pressure banks    /1 * 3/
         MP_comps        Number of medium pressure compressors /1 * 2/
         HP_comps        Number of high pressure compressors   /1 * 2/
;

Parameter
         comp_MP_flowrate        "Medium pressure compressor flowrate (kg/sec)"   / 0.00075 /
         comp_HP_flowrate        "High pressure compressor flowrate (kg/sec)"     / 0.005 /
         comp_MP_efficiency      "Medium pressure compressor efficiency (kg/kWh)" / 2 /
         comp_HP_efficiency      "High pressure compressor efficiency (kg/kWh)"   / 4 /
;

Positive Variables
         comp_power_MP(interval,MP_comps)        "Medium compressor power timeseries (kW)"
         comp_power_HP(interval,HP_comps)        "Medium compressor power timeseries (kW)"
         storage_level_LP(interval,LPbanks)      "LP Storage level for each bank (kg)"
         storage_level_MP(interval,MPbanks)      "MP Storage level for each bank (kg)"
         storage_level_HP(interval,HPbanks)      "HP Storage level for each bank (kg)"
         pre_cooling_power(interval)             "Power to operate precooling (kW)"
;

Equations

;






transfer_LP_to_MP(interval)
transfer_MP_to_HP(interval)




H2_sold(interval)























H2_CF_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and CF_opt=1)..
         H2_sold(interval) =e= H2_consumed(interval) * H2_consumed_adj * Hydrogen_fraction;

H2_CF_eqn2$(CF_opt=1).. Hydrogen_fraction =l= 1;
H2_CF_eqn3$(CF_opt=0).. Hydrogen_fraction =e= 1;


*** Cost function: Elec sale price, elec purchase price, regup, regdown, spin, nonspin, NGout/in, unused VOM cost, startup cost, H2 price, VOM cost, demand charge (fixed and timed), meter cost, cap and FOM cost
operating_profit_eqn..
         operating_profit =e= sum( (interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index ),
                   (elec_sale_price_forecast(interval) * (output_power_MW(interval)) * interval_length)
                 - (elec_purchase_price_forecast(interval) * input_power_MW_non_ren(interval) * interval_length)
                 + ( regup_price(interval) - reg_cost ) * ( output_regup_MW(interval) + input_regup_MW(interval) ) * interval_length
                 + ( regdn_price(interval) - reg_cost ) * ( output_regdn_MW(interval) + input_regdn_MW(interval) ) * interval_length
                 + spinres_price(interval) * ( output_spinres_MW(interval) + input_spinres_MW(interval) ) * interval_length
                 + nonspinres_price(interval) * ( output_nonspinres_MW(interval) + input_nonspinres_MW(interval) ) * interval_length
                 - output_heat_rate * NG_price(interval) * output_power_MW(interval) * interval_length
                 - input_heat_rate * NG_price(interval) * input_power_MW(interval) * interval_length
                 - VOM_cost * output_power_MW(interval) * interval_length
                 - output_startup_cost * output_capacity_MW * output_start(interval)
                 - input_startup_cost  * input_capacity_MW  * input_start(interval)
                 + H2_price(interval) * H2_sold(interval)
                 - input_VOM_cost * input_power_MW(interval) * interval_length
                 - output_VOM_cost * output_power_MW(interval) * interval_length
                 - (input_ramp_pos(interval)+input_ramp_neg(interval))*ramp_penalty
                 - (output_ramp_pos(interval)+output_ramp_neg(interval))*ramp_penalty )
                 - sum(months, Fixed_cap(months) * Fixed_dem(months))
                 - sum(months, cap_1(months) * Timed_dem("1"))
                 - sum(months, cap_2(months) * Timed_dem("2"))
                 - sum(months, cap_3(months) * Timed_dem("3"))
                 - sum(months, cap_4(months) * Timed_dem("4"))
                 - sum(months, cap_5(months) * Timed_dem("5"))
                 - sum(months, cap_6(months) * Timed_dem("6"))
                 - meter_mnth_chg("1") * 12
                 - (input_cap_cost+input_FOM_cost*input_lifetime) * input_capacity_MW * (interest_rate+(interest_rate/(power((1+interest_rate),input_lifetime)-1)))
                 - (output_cap_cost+output_FOM_cost*output_lifetime) * output_capacity_MW * (interest_rate+(interest_rate/(power((1+interest_rate),output_lifetime)-1)))
                 ;

output_LSL_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_power_MW(interval) - output_regdn_MW(interval) =g= output_LSL_fraction * output_capacity_MW * output_active(interval);

output_capacity_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_power_MW(interval) + output_regup_MW(interval) + output_spinres_MW(interval) =l= output_capacity_MW * output_active(interval);

output_regup_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_regup_MW(interval) =l= output_capacity_MW * output_regup_limit_fraction;

output_regdn_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_regdn_MW(interval) =l= output_capacity_MW * output_regdn_limit_fraction;

output_spinres_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_spinres_MW(interval) =l= output_capacity_MW * output_spinres_limit_fraction;

output_nonspinres_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_nonspinres_MW(interval) =l= output_capacity_MW * output_nonspinres_limit_fraction * ( 1 - output_active(interval) );
*         output_nonspinres_MW(interval) =l= 0;

output_ramp_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_power_MW(interval)-output_power_MW(interval-1) =e= output_ramp_pos(interval)-output_ramp_neg(interval);

input_ramp_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_power_MW(interval)-input_power_MW(interval-1) =e= input_ramp_pos(interval)-input_ramp_neg(interval);

input_pwr_eqn(interval)$(baseload_operation = 1)..
         input_power_MW(interval) =e=  input_capacity_MW * H2_consumed_adj;

input_LSL_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_power_MW(interval) - input_regup_MW(interval) - input_spinres_MW(interval) - input_nonspinres_MW(interval) =g= input_LSL_fraction * input_capacity_MW * input_active(interval);

input_capacity_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_power_MW(interval) + input_regdn_MW(interval) =l= input_capacity_MW * input_active(interval);


*** Fixed Demand Charge ***
Fixed_dem_Jan(Month_Jan)$( rolling_window_min_index <= ord(Month_Jan) and ord(Month_Jan) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Jan) =l= Fixed_cap("1");
Fixed_dem_Feb(Month_Feb)$( rolling_window_min_index <= ord(Month_Feb) and ord(Month_Feb) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Feb) =l= Fixed_cap("2");
Fixed_dem_Mar(Month_Mar)$( rolling_window_min_index <= ord(Month_Mar) and ord(Month_Mar) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Mar) =l= Fixed_cap("3");
Fixed_dem_Apr(Month_Apr)$( rolling_window_min_index <= ord(Month_Apr) and ord(Month_Apr) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Apr) =l= Fixed_cap("4");
Fixed_dem_May(Month_May)$( rolling_window_min_index <= ord(Month_May) and ord(Month_May) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_May) =l= Fixed_cap("5");
Fixed_dem_Jun(Month_Jun)$( rolling_window_min_index <= ord(Month_Jun) and ord(Month_Jun) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Jun) =l= Fixed_cap("6");
Fixed_dem_Jul(Month_Jul)$( rolling_window_min_index <= ord(Month_Jul) and ord(Month_Jul) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Jul) =l= Fixed_cap("7");
Fixed_dem_Aug(Month_Aug)$( rolling_window_min_index <= ord(Month_Aug) and ord(Month_Aug) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Aug) =l= Fixed_cap("8");
Fixed_dem_Sep(Month_Sep)$( rolling_window_min_index <= ord(Month_Sep) and ord(Month_Sep) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Sep) =l= Fixed_cap("9");
Fixed_dem_Oct(Month_Oct)$( rolling_window_min_index <= ord(Month_Oct) and ord(Month_Oct) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Oct) =l= Fixed_cap("10");
Fixed_dem_Nov(Month_Nov)$( rolling_window_min_index <= ord(Month_Nov) and ord(Month_Nov) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Nov) =l= Fixed_cap("11");
Fixed_dem_Dec(Month_Dec)$( rolling_window_min_index <= ord(Month_Dec) and ord(Month_Dec) <= rolling_window_max_index ).. input_power_MW_non_ren(Month_Dec) =l= Fixed_cap("12");
*************************
**** Demand Charge 1 ****
Jan_1_eqn(Jan_1)$( rolling_window_min_index <= ord(Jan_1) and ord(Jan_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Jan_1) =l= Cap_1("1");
Feb_1_eqn(Feb_1)$( rolling_window_min_index <= ord(Feb_1) and ord(Feb_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Feb_1) =l= Cap_1("2");
Mar_1_eqn(Mar_1)$( rolling_window_min_index <= ord(Mar_1) and ord(Mar_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Mar_1) =l= Cap_1("3");
Apr_1_eqn(Apr_1)$( rolling_window_min_index <= ord(Apr_1) and ord(Apr_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Apr_1) =l= Cap_1("4");
May_1_eqn(May_1)$( rolling_window_min_index <= ord(May_1) and ord(May_1) <= rolling_window_max_index ).. input_power_MW_non_ren(May_1) =l= Cap_1("5");
Jun_1_eqn(Jun_1)$( rolling_window_min_index <= ord(Jun_1) and ord(Jun_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Jun_1) =l= Cap_1("6");
Jul_1_eqn(Jul_1)$( rolling_window_min_index <= ord(Jul_1) and ord(Jul_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Jul_1) =l= Cap_1("7");
Aug_1_eqn(Aug_1)$( rolling_window_min_index <= ord(Aug_1) and ord(Aug_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Aug_1) =l= Cap_1("8");
Sep_1_eqn(Sep_1)$( rolling_window_min_index <= ord(Sep_1) and ord(Sep_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Sep_1) =l= Cap_1("9");
Oct_1_eqn(Oct_1)$( rolling_window_min_index <= ord(Oct_1) and ord(Oct_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Oct_1) =l= Cap_1("10");
Nov_1_eqn(Nov_1)$( rolling_window_min_index <= ord(Nov_1) and ord(Nov_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Nov_1) =l= Cap_1("11");
Dec_1_eqn(Dec_1)$( rolling_window_min_index <= ord(Dec_1) and ord(Dec_1) <= rolling_window_max_index ).. input_power_MW_non_ren(Dec_1) =l= Cap_1("12");
*************************
**** Demand Charge 2 ****
Jan_2_eqn(Jan_2)$( rolling_window_min_index <= ord(Jan_2) and ord(Jan_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Jan_2) =l= Cap_2("1");
Feb_2_eqn(Feb_2)$( rolling_window_min_index <= ord(Feb_2) and ord(Feb_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Feb_2) =l= Cap_2("2");
Mar_2_eqn(Mar_2)$( rolling_window_min_index <= ord(Mar_2) and ord(Mar_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Mar_2) =l= Cap_2("3");
Apr_2_eqn(Apr_2)$( rolling_window_min_index <= ord(Apr_2) and ord(Apr_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Apr_2) =l= Cap_2("4");
May_2_eqn(May_2)$( rolling_window_min_index <= ord(May_2) and ord(May_2) <= rolling_window_max_index ).. input_power_MW_non_ren(May_2) =l= Cap_2("5");
Jun_2_eqn(Jun_2)$( rolling_window_min_index <= ord(Jun_2) and ord(Jun_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Jun_2) =l= Cap_2("6");
Jul_2_eqn(Jul_2)$( rolling_window_min_index <= ord(Jul_2) and ord(Jul_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Jul_2) =l= Cap_2("7");
Aug_2_eqn(Aug_2)$( rolling_window_min_index <= ord(Aug_2) and ord(Aug_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Aug_2) =l= Cap_2("8");
Sep_2_eqn(Sep_2)$( rolling_window_min_index <= ord(Sep_2) and ord(Sep_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Sep_2) =l= Cap_2("9");
Oct_2_eqn(Oct_2)$( rolling_window_min_index <= ord(Oct_2) and ord(Oct_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Oct_2) =l= Cap_2("10");
Nov_2_eqn(Nov_2)$( rolling_window_min_index <= ord(Nov_2) and ord(Nov_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Nov_2) =l= Cap_2("11");
Dec_2_eqn(Dec_2)$( rolling_window_min_index <= ord(Dec_2) and ord(Dec_2) <= rolling_window_max_index ).. input_power_MW_non_ren(Dec_2) =l= Cap_2("12");
*************************
**** Demand Charge 3 ****
Jan_3_eqn(Jan_3)$( rolling_window_min_index <= ord(Jan_3) and ord(Jan_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Jan_3) =l= Cap_3("1");
Feb_3_eqn(Feb_3)$( rolling_window_min_index <= ord(Feb_3) and ord(Feb_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Feb_3) =l= Cap_3("2");
Mar_3_eqn(Mar_3)$( rolling_window_min_index <= ord(Mar_3) and ord(Mar_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Mar_3) =l= Cap_3("3");
Apr_3_eqn(Apr_3)$( rolling_window_min_index <= ord(Apr_3) and ord(Apr_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Apr_3) =l= Cap_3("4");
May_3_eqn(May_3)$( rolling_window_min_index <= ord(May_3) and ord(May_3) <= rolling_window_max_index ).. input_power_MW_non_ren(May_3) =l= Cap_3("5");
Jun_3_eqn(Jun_3)$( rolling_window_min_index <= ord(Jun_3) and ord(Jun_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Jun_3) =l= Cap_3("6");
Jul_3_eqn(Jul_3)$( rolling_window_min_index <= ord(Jul_3) and ord(Jul_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Jul_3) =l= Cap_3("7");
Aug_3_eqn(Aug_3)$( rolling_window_min_index <= ord(Aug_3) and ord(Aug_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Aug_3) =l= Cap_3("8");
Sep_3_eqn(Sep_3)$( rolling_window_min_index <= ord(Sep_3) and ord(Sep_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Sep_3) =l= Cap_3("9");
Oct_3_eqn(Oct_3)$( rolling_window_min_index <= ord(Oct_3) and ord(Oct_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Oct_3) =l= Cap_3("10");
Nov_3_eqn(Nov_3)$( rolling_window_min_index <= ord(Nov_3) and ord(Nov_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Nov_3) =l= Cap_3("11");
Dec_3_eqn(Dec_3)$( rolling_window_min_index <= ord(Dec_3) and ord(Dec_3) <= rolling_window_max_index ).. input_power_MW_non_ren(Dec_3) =l= Cap_3("12");
*************************
**** Demand Charge 4 ****
Jan_4_eqn(Jan_4)$( rolling_window_min_index <= ord(Jan_4) and ord(Jan_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Jan_4) =l= Cap_4("1");
Feb_4_eqn(Feb_4)$( rolling_window_min_index <= ord(Feb_4) and ord(Feb_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Feb_4) =l= Cap_4("2");
Mar_4_eqn(Mar_4)$( rolling_window_min_index <= ord(Mar_4) and ord(Mar_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Mar_4) =l= Cap_4("3");
Apr_4_eqn(Apr_4)$( rolling_window_min_index <= ord(Apr_4) and ord(Apr_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Apr_4) =l= Cap_4("4");
May_4_eqn(May_4)$( rolling_window_min_index <= ord(May_4) and ord(May_4) <= rolling_window_max_index ).. input_power_MW_non_ren(May_4) =l= Cap_4("5");
Jun_4_eqn(Jun_4)$( rolling_window_min_index <= ord(Jun_4) and ord(Jun_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Jun_4) =l= Cap_4("6");
Jul_4_eqn(Jul_4)$( rolling_window_min_index <= ord(Jul_4) and ord(Jul_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Jul_4) =l= Cap_4("7");
Aug_4_eqn(Aug_4)$( rolling_window_min_index <= ord(Aug_4) and ord(Aug_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Aug_4) =l= Cap_4("8");
Sep_4_eqn(Sep_4)$( rolling_window_min_index <= ord(Sep_4) and ord(Sep_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Sep_4) =l= Cap_4("9");
Oct_4_eqn(Oct_4)$( rolling_window_min_index <= ord(Oct_4) and ord(Oct_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Oct_4) =l= Cap_4("10");
Nov_4_eqn(Nov_4)$( rolling_window_min_index <= ord(Nov_4) and ord(Nov_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Nov_4) =l= Cap_4("11");
Dec_4_eqn(Dec_4)$( rolling_window_min_index <= ord(Dec_4) and ord(Dec_4) <= rolling_window_max_index ).. input_power_MW_non_ren(Dec_4) =l= Cap_4("12");
*************************
**** Demand Charge 5 ****
Jan_5_eqn(Jan_5)$( rolling_window_min_index <= ord(Jan_5) and ord(Jan_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Jan_5) =l= Cap_5("1");
Feb_5_eqn(Feb_5)$( rolling_window_min_index <= ord(Feb_5) and ord(Feb_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Feb_5) =l= Cap_5("2");
Mar_5_eqn(Mar_5)$( rolling_window_min_index <= ord(Mar_5) and ord(Mar_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Mar_5) =l= Cap_5("3");
Apr_5_eqn(Apr_5)$( rolling_window_min_index <= ord(Apr_5) and ord(Apr_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Apr_5) =l= Cap_5("4");
May_5_eqn(May_5)$( rolling_window_min_index <= ord(May_5) and ord(May_5) <= rolling_window_max_index ).. input_power_MW_non_ren(May_5) =l= Cap_5("5");
Jun_5_eqn(Jun_5)$( rolling_window_min_index <= ord(Jun_5) and ord(Jun_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Jun_5) =l= Cap_5("6");
Jul_5_eqn(Jul_5)$( rolling_window_min_index <= ord(Jul_5) and ord(Jul_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Jul_5) =l= Cap_5("7");
Aug_5_eqn(Aug_5)$( rolling_window_min_index <= ord(Aug_5) and ord(Aug_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Aug_5) =l= Cap_5("8");
Sep_5_eqn(Sep_5)$( rolling_window_min_index <= ord(Sep_5) and ord(Sep_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Sep_5) =l= Cap_5("9");
Oct_5_eqn(Oct_5)$( rolling_window_min_index <= ord(Oct_5) and ord(Oct_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Oct_5) =l= Cap_5("10");
Nov_5_eqn(Nov_5)$( rolling_window_min_index <= ord(Nov_5) and ord(Nov_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Nov_5) =l= Cap_5("11");
Dec_5_eqn(Dec_5)$( rolling_window_min_index <= ord(Dec_5) and ord(Dec_5) <= rolling_window_max_index ).. input_power_MW_non_ren(Dec_5) =l= Cap_5("12");
*************************
**** Demand Charge 6 ****
Jan_6_eqn(Jan_6)$( rolling_window_min_index <= ord(Jan_6) and ord(Jan_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Jan_6) =l= Cap_6("1");
Feb_6_eqn(Feb_6)$( rolling_window_min_index <= ord(Feb_6) and ord(Feb_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Feb_6) =l= Cap_6("2");
Mar_6_eqn(Mar_6)$( rolling_window_min_index <= ord(Mar_6) and ord(Mar_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Mar_6) =l= Cap_6("3");
Apr_6_eqn(Apr_6)$( rolling_window_min_index <= ord(Apr_6) and ord(Apr_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Apr_6) =l= Cap_6("4");
May_6_eqn(May_6)$( rolling_window_min_index <= ord(May_6) and ord(May_6) <= rolling_window_max_index ).. input_power_MW_non_ren(May_6) =l= Cap_6("5");
Jun_6_eqn(Jun_6)$( rolling_window_min_index <= ord(Jun_6) and ord(Jun_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Jun_6) =l= Cap_6("6");
Jul_6_eqn(Jul_6)$( rolling_window_min_index <= ord(Jul_6) and ord(Jul_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Jul_6) =l= Cap_6("7");
Aug_6_eqn(Aug_6)$( rolling_window_min_index <= ord(Aug_6) and ord(Aug_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Aug_6) =l= Cap_6("8");
Sep_6_eqn(Sep_6)$( rolling_window_min_index <= ord(Sep_6) and ord(Sep_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Sep_6) =l= Cap_6("9");
Oct_6_eqn(Oct_6)$( rolling_window_min_index <= ord(Oct_6) and ord(Oct_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Oct_6) =l= Cap_6("10");
Nov_6_eqn(Nov_6)$( rolling_window_min_index <= ord(Nov_6) and ord(Nov_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Nov_6) =l= Cap_6("11");
Dec_6_eqn(Dec_6)$( rolling_window_min_index <= ord(Dec_6) and ord(Dec_6) <= rolling_window_max_index ).. input_power_MW_non_ren(Dec_6) =l= Cap_6("12");
*************************

input_capacity_limit_eqn2(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_power_MW_ren(interval)-Load_profile(interval)+input_power_MW_non_ren(interval) =e= input_power_MW(interval);

input_ren_contribution(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_power_MW_ren(interval) =l= Renewable_power(interval);

input_regup_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_regup_MW(interval) =l= input_capacity_MW * input_regup_limit_fraction;

input_regdn_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_regdn_MW(interval) =l= input_capacity_MW * input_regdn_limit_fraction;

input_spinres_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_spinres_MW(interval) =l= input_capacity_MW * input_spinres_limit_fraction;

input_nonspinres_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_nonspinres_MW(interval) =l= input_capacity_MW * input_nonspinres_limit_fraction;

storage_level_accounting_eqn(interval)$(rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and input_capacity_MW > 0 and baseload_operation=0 and ord(interval)>current_interval and ord(interval)<max_interval )..
         storage_level_MWh(interval) =e= storage_level_MWh(interval-1)
         + input_power_MW(interval) * interval_length * input_efficiency
         - output_power_MW(interval) * interval_length / output_efficiency
         - H2_sold(interval) * H2_LHV;
* LHV selected because fuel cell vehicles typically use a PEM FC and will release liquid water

storage_level_accounting_eqn2(interval)$(rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and input_capacity_MW = 0 and baseload_operation=0 and ord(interval)>current_interval and ord(interval)<max_interval )..
         storage_level_MWh(interval) =e= storage_level_MWh(interval-1);
* If input capacity is equal to zero then output device cannot interact with storage system so storage_level_MWh is held constant

H2_output_limit_eqn(days)$(H2_use = 2)..
         H2_sold_daily(days) =e= sum( interval$(floor(div(ord(interval)-1,24))+1 = ord(days) ), H2_sold(interval) );

H2_output_limit_eqn2(days)$(H2_use = 2)..
         H2_sold_daily(days) =e= sum( interval$(floor(div(ord(interval)-1,24))+1 = ord(days) ), H2_consumed(interval) );

H2_output_limit_eqn3(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and H2_use <= 1 and CF_opt=0)..
         H2_sold(interval) =e= H2_consumed(interval);

storage_level_limit_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and input_capacity_MW>0 and ord(interval)>current_interval and ord(interval)<max_interval )..
         storage_level_MWh(interval) =l= input_capacity_MW * storage_capacity_hours
         - input_regdn_MW(interval) * interval_length * 0.5;

storage_level_limit_eqn2(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and input_capacity_MW<=0 and ord(interval)>current_interval and ord(interval)<max_interval )..
         storage_level_MWh(interval) =l= output_capacity_MW * storage_capacity_hours
         - input_regdn_MW(interval) * interval_length * 0.5;

*****(ord(interval)>current_interval OR ord(interval)<max_interval )

storage_level_limit_eqn3(interval)$(rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and ord(interval)>current_interval and ord(interval)<max_interval )..
         storage_level_MWh(interval) =g= (output_regup_MW(interval) + output_spinres_MW(interval) + output_nonspinres_MW(interval)) / input_efficiency * interval_length * 0.5;
* Ensures that reserves can be provided if necessary for at least 1/2 hour.

output_startup_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         output_start(interval) =g= output_active(interval) - output_active(interval-1);

input_startup_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         input_start(interval) =g= input_active(interval) - input_active(interval-1);

RT_eqn1(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and ord(interval)<=current_interval and current_monthly_max>=0)..
         input_power_MW(interval) =e= current_monthly_max * input_capacity_MW;

RT_eqn2(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and ord(interval)<=current_interval and current_storage_lvl>=0)..
         storage_level_MWh(interval) =e= current_storage_lvl * input_capacity_MW * storage_capacity_hours;

RT_eqn3(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and ord(interval)>=max_interval and current_monthly_max>=0)..
         input_power_MW(interval) =e= current_monthly_max * input_capacity_MW;

RT_eqn4(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index and ord(interval)>=max_interval and current_storage_lvl>=0)..
         storage_level_MWh(interval) =e= current_storage_lvl * input_capacity_MW * storage_capacity_hours;

*one_active_device_eqn(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
*         input_active(interval) + output_active(interval) =l= 1;


alias (interval, interval_alias);
*note that min runtime constraints are not generated if min runtimes would not be binding--this reduces the execution time significantly
output_min_on_eqn1(interval)$( min_output_on_intervals > 1 and 1 < ord(interval) and ord(interval) <= min_output_on_intervals and rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         sum(interval_alias$( ord(interval_alias) <= ord(interval) ), output_active(interval_alias) ) =g= ord(interval) * ( output_active(interval) - output_active(interval + 1) );

output_min_on_eqn2(interval)$( min_output_on_intervals > 1 and 1 < ord(interval) and ord(interval) <= card(interval) - min_output_on_intervals + 1 and rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         sum(interval_alias$( ord(interval) <= ord(interval_alias) and ord(interval_alias) <= ord(interval) + min_output_on_intervals - 1 ),
             output_active(interval_alias) ) =g= min_output_on_intervals * ( output_active(interval) - output_active(interval - 1) );

output_min_on_eqn3(interval)$( min_output_on_intervals > 1 and ord(interval) > card(interval) - min_output_on_intervals + 1 and ord(interval) < card(interval) and rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         sum(interval_alias$( ord(interval) <= ord(interval_alias) ), output_active(interval_alias) ) =g= (card(interval) - ord(interval) + 1) * ( output_active(interval) - output_active(interval - 1) );

input_min_on_eqn1(interval)$( min_input_on_intervals > 1 and 1 < ord(interval) and ord(interval) <= min_input_on_intervals and rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         sum(interval_alias$( ord(interval_alias) <= ord(interval) ), input_active(interval_alias) ) =g= ord(interval) * ( input_active(interval) - input_active(interval + 1) );

input_min_on_eqn2(interval)$( min_input_on_intervals > 1 and 1 < ord(interval) and ord(interval) <= card(interval) - min_input_on_intervals + 1 and rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         sum(interval_alias$( ord(interval) <= ord(interval_alias) and ord(interval_alias) <= ord(interval) + min_input_on_intervals - 1 ),
             input_active(interval_alias) ) =g= min_input_on_intervals * ( input_active(interval) - input_active(interval - 1) );

input_min_on_eqn3(interval)$( min_input_on_intervals > 1 and ord(interval) > card(interval) - min_input_on_intervals + 1 and ord(interval) < card(interval) and rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )..
         sum(interval_alias$( ord(interval) <= ord(interval_alias) ), input_active(interval_alias) ) =g= (card(interval) - ord(interval) + 1) * ( input_active(interval) - input_active(interval - 1) );


Model arbitrage_and_AS /all/
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

*prepare for rolling window solution

*determine the number of times the model will be solved
number_of_solves = ceil( card(interval) / operating_period_length );

*set optcr so that (best feasible - best possible) / (best feasible + 1e-10) < optcr
* default is 0.1 = 10%, which seems too big
* 0.01 = 1%
option optcr=0.01;

*give initial values to all of the variables
output_power_MW.l(interval)      = 0;
output_regup_MW.l(interval)      = 0;
output_regdn_MW.l(interval)      = 0;
output_spinres_MW.l(interval)    = 0;
output_nonspinres_MW.l(interval) = 0;
input_power_MW.l(interval)       = 1;
input_regup_MW.l(interval)       = 0;
input_regdn_MW.l(interval)       = 0;
input_spinres_MW.l(interval)     = 0;
input_nonspinres_MW.l(interval)  = 0;
storage_level_MWh.l(interval)    = 1;
output_active.l(interval)        = 0;
input_active.l(interval)         = 0;
output_start.l(interval)         = 0;
input_start.l(interval)          = 1;
H2_sold.l(interval)              = 0;
H2_sold_daily.l(days)            = 0;
if(H2_use = 2,
         H2_sold_daily.l(days)            = 24;
* need value above 0 for initialization
);

scalars
         no_error indicator of whether the model encountered an error
         optimal_solution_reached indicator of whether the model found an optimal solution before the time limit expired
         solve_index index for solve loop
;

no_error = 1;
optimal_solution_reached = 1;
solve_index = 1;

while ( solve_index <= number_of_solves and no_error = 1 ,

*        fix all variables' values
*        (will relax the values within the rolling window later)
         output_power_MW.fx(interval)      = output_power_MW.l(interval)  ;
         output_regup_MW.fx(interval)      = output_regup_MW.l(interval)  ;
         output_regdn_MW.fx(interval)      = output_regdn_MW.l(interval)  ;
         output_spinres_MW.fx(interval)    = output_spinres_MW.l(interval);
         output_nonspinres_MW.fx(interval) = output_nonspinres_MW.l(interval);
         input_power_MW.fx(interval)       = input_power_MW.l(interval)   ;
         input_regup_MW.fx(interval)       = input_regup_MW.l(interval)   ;
         input_regdn_MW.fx(interval)       = input_regdn_MW.l(interval)   ;
         input_spinres_MW.fx(interval)     = input_spinres_MW.l(interval) ;
         input_nonspinres_MW.fx(interval)  = input_nonspinres_MW.l(interval);
         storage_level_MWh.fx(interval)    = storage_level_MWh.l(interval);
         output_active.fx(interval)        = output_active.l(interval)    ;
         input_active.fx(interval)         = input_active.l(interval)     ;
         output_start.fx(interval)         = output_start.l(interval)     ;
         input_start.fx(interval)          = input_start.l(interval)      ;
         H2_sold.fx(interval)              = H2_sold.l(interval)          ;
         H2_sold_daily.fx(days)            = H2_sold_daily.l(days)        ;

*        calculate the min and max indices for the rolling window
         operating_period_min_index = ( solve_index-1 ) * operating_period_length + 1;
         operating_period_max_index = ( solve_index ) * operating_period_length;
         rolling_window_min_index   = operating_period_min_index;
         rolling_window_max_index   = operating_period_max_index + look_ahead_length;

*        relax variables in current rolling window
         output_power_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )      = 0;
         output_regup_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )      = 0;
         output_regdn_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )      = 0;
         output_spinres_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )    = 0;
         output_nonspinres_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index ) = 0;
         input_power_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )       = 0;
         input_regup_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )       = 0;
         input_regdn_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )       = 0;
         input_spinres_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )     = 0;
         input_nonspinres_MW.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )  = 0;
         storage_level_MWh.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )    = 0;
         output_active.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )        = 0;
         input_active.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )         = 0;
         output_start.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )         = 0;
         input_start.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )          = 0;
         H2_sold.lo(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )              = 0;
         H2_sold_daily.lo(days)$(H2_use=2)                                                                                             = 0;

         output_power_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )      =  inf;
         output_regup_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )      =  inf;
         output_regdn_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )      =  inf;
         output_spinres_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )    =  inf;
         output_nonspinres_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index ) =  inf;
         input_power_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )       =  inf;
         input_regup_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )       =  inf;
         input_regdn_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )       =  inf;
         input_spinres_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )     =  inf;
         input_nonspinres_MW.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )  =  inf;
         storage_level_MWh.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )    =  inf;
         output_active.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )        =  1;
         input_active.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )         =  1;
         output_start.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )         =  1;
         input_start.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )          =  1;

         H2_sold.up(interval)$( rolling_window_min_index <= ord(interval) and ord(interval) <= rolling_window_max_index )              = inf;
         H2_sold_daily.up(days)$(H2_use=2)                                                                                             = inf;


         Solve arbitrage_and_AS using MIP maximizing operating_profit;


*        modelstat = 1 means optimal LP solution
*        modelstat = 6 means model ran out of time, feasible integer solution found but not yet optimal
*        modelstat = 8 means optimal integer solution found
         if( ( arbitrage_and_AS.modelstat=1 or arbitrage_and_AS.modelstat=8 ),
                 solve_index = solve_index + 1;

                 if ( arbitrage_and_AS.solvestat = 2 or arbitrage_and_AS.solvestat = 3,
                         optimal_solution_reached = 0;
                 );

         elseif ( arbitrage_and_AS.modelstat = 6 ),
                 solve_index = solve_index + 1;
                 optimal_solution_reached = 0;

         else
                 no_error = 0;
         );

);
*end of for loop

*calculate values to export in reports
Scalars
         elec_in_MWh              MWh of electricity bought over the simulated time period
         elec_output_MWh          MWh of electricity sold over the simulated time period
         output_input_ratio       ratio of elec output to elec output
         input_capacity_factor    capacity factor for buying side of the facility
         output_capacity_factor   capacity factor for the selling side of the facility
         avg_regup_MW             average capacity sold to regup (MW per interval)
         avg_regdn_MW             average capacity sold to regdn (MW per interval)
         avg_spinres_MW           average capacity sold to spinning reserve (MW per interval)
         avg_nonspinres_MW        average capacity sold to nonspinning reserve (MW per interval)

         num_input_starts         number of compressor or input power system starts
         num_output_starts        number of turbine or output power system starts

         fuel_cost                cost of fuel (dollars)
         elec_cost                cost of electricity (dollars)
         VOM_cost_val             cost of VOM (dollars)
         arbitrage_revenue        operating profits due to electricity purchases and sales (dollars)
         regup_revenue            operating profits due to regulation up AS market (dollars)
         regdn_revenue            operating profits due to regulation down AS market (dollars)
         spinres_revenue          operating profits due to spinning reserve AS market (dollars)
         nonspinres_revenue       operating profits due to nonspinning reserve AS market (dollars)
         H2_revenue               operating profits due to selling hydrogen (dollars)
         startup_costs            cost due to startups
         actual_operating_profit  actual operating profits (dollars)
         Renewable_pen_input      renewable penetration of input device (%)
         Renewable_pen_input_net  renewable penetration of input device for net metering (%)

         Fixed_dem_charge_cost    Yearly Fixed demand charge cost
         Timed_dem_1_cost         Yearly Timed demand charge cost
         Timed_dem_2_cost         Yearly Timed demand charge cost
         Timed_dem_3_cost         Yearly Timed demand charge cost
         Timed_dem_4_cost         Yearly Timed demand charge cost
         Timed_dem_5_cost         Yearly Timed demand charge cost
         Timed_dem_6_cost         Yearly Timed demand charge cost
         Meter_cost               Yearly cost for operating meter

         input_cap_cost2          Annualized capital cost
         output_cap_cost2         Annualized capital cost
         input_FOM_cost2          Annualized FOM cost
         output_FOM_cost2         Annualized FOM cost
         input_VOM_cost2          Annualized VOM cost
         output_VOM_cost2         Annualized VOM cost

         Hydrogen_fraction_val    Optimized Capacity Factor (%)
;

Parameters
         Fixed_cap_val(months)    determine calculated value for fixed demand (MW)
         cap_1_val(months)        determine power cap for demand period 1 (MW)
         cap_2_val(months)        determine power cap for demand period 2 (MW)
         cap_3_val(months)        determine power cap for demand period 3 (MW)
         cap_4_val(months)        determine power cap for demand period 4 (MW)
         cap_5_val(months)        determine power cap for demand period 5 (MW)
         cap_6_val(months)        determine power cap for demand period 6 (MW)
;

* calculate values to be output in the report
Fixed_cap_val(months) = Fixed_cap.l(months);
cap_1_val(months) = cap_1.l(months);
cap_2_val(months) = cap_2.l(months);
cap_3_val(months) = cap_3.l(months);
cap_4_val(months) = cap_4.l(months);
cap_5_val(months) = cap_5.l(months);
cap_6_val(months) = cap_6.l(months);
Fixed_dem_charge_cost = -sum(months, Fixed_cap.l(months) * Fixed_dem(months));
Timed_dem_1_cost = -sum(months, cap_1.l(months) * Timed_dem("1"));
Timed_dem_2_cost = -sum(months, cap_2.l(months) * Timed_dem("2"));
Timed_dem_3_cost = -sum(months, cap_3.l(months) * Timed_dem("3"));
Timed_dem_4_cost = -sum(months, cap_4.l(months) * Timed_dem("4"));
Timed_dem_5_cost = -sum(months, cap_5.l(months) * Timed_dem("5"));
Timed_dem_6_cost = -sum(months, cap_6.l(months) * Timed_dem("6"));
Meter_cost = -(meter_mnth_chg("1") * 12);

elec_in_MWh  = sum(interval,  (input_power_MW.l(interval) + Load_profile(interval)) * interval_length );
elec_output_MWh = sum(interval, output_power_MW.l(interval) * interval_length );
output_input_ratio = elec_output_MWh / elec_in_MWh;
input_capacity_factor  =  elec_in_MWh / (  input_capacity_MW * card(interval) * interval_length );
output_capacity_factor = elec_output_MWh / ( output_capacity_MW * card(interval) * interval_length );
avg_regup_MW = sum(interval, output_regup_MW.l(interval) + input_regup_MW.l(interval) ) / card(interval);
avg_regdn_MW = sum(interval, output_regdn_MW.l(interval) + input_regdn_MW.l(interval) ) / card(interval);
avg_spinres_MW = sum(interval, output_spinres_MW.l(interval) + input_spinres_MW.l(interval) ) / card(interval);
avg_nonspinres_MW = sum(interval, output_nonspinres_MW.l(interval) + input_nonspinres_MW.l(interval) ) / card(interval);

num_input_starts = sum(interval, input_start.l(interval) );
num_output_starts = sum(interval, output_start.l(interval) );

fuel_cost = sum(interval,- output_heat_rate * NG_price(interval) * output_power_MW.l(interval) * interval_length
                         - input_heat_rate * NG_price(interval) * input_power_MW.l(interval) * interval_length);
elec_cost = sum(interval,((elec_sale_price(interval) * output_power_MW.l(interval)) - (elec_purchase_price(interval) * input_power_MW_non_ren.l(interval))) * interval_length);
VOM_cost_val = sum(interval,- VOM_cost * output_power_MW.l(interval) * interval_length);
arbitrage_revenue = sum(interval,
                        ((elec_sale_price(interval) * (output_power_MW.l(interval)))
                        - (elec_purchase_price(interval) * input_power_MW_non_ren.l(interval))) * interval_length
                        - output_heat_rate * NG_price(interval) * output_power_MW.l(interval) * interval_length
                        - input_heat_rate * NG_price(interval) * input_power_MW.l(interval) * interval_length
                        - VOM_cost * output_power_MW.l(interval) * interval_length
                        );
* +Renewable_power(interval)-input_power_MW_ren.l(interval)

input_cap_cost2  = -input_cap_cost * input_capacity_MW * (interest_rate+(interest_rate/(power((1+interest_rate),input_lifetime)-1)));
output_cap_cost2 = -output_cap_cost * output_capacity_MW * (interest_rate+(interest_rate/(power((1+interest_rate),output_lifetime)-1)));
input_FOM_cost2  = -input_FOM_cost * input_capacity_MW * input_lifetime * (interest_rate+(interest_rate/(power((1+interest_rate),input_lifetime)-1)));
output_FOM_cost2 = -output_FOM_cost * output_capacity_MW * output_lifetime * (interest_rate+(interest_rate/(power((1+interest_rate),output_lifetime)-1)));
input_VOM_cost2  = -elec_in_MWh * input_VOM_cost;
output_VOM_cost2 = -elec_output_MWh * output_VOM_cost;

regup_revenue = sum(interval, ( regup_price(interval) - reg_cost ) * ( output_regup_MW.l(interval) + input_regup_MW.l(interval) ) * interval_length );
regdn_revenue = sum(interval, ( regdn_price(interval) - reg_cost ) * ( output_regdn_MW.l(interval) + input_regdn_MW.l(interval) ) * interval_length );
spinres_revenue = sum(interval, spinres_price(interval) * ( output_spinres_MW.l(interval) + input_spinres_MW.l(interval) ) * interval_length );
nonspinres_revenue = sum(interval, nonspinres_price(interval) * ( output_nonspinres_MW.l(interval) + input_nonspinres_MW.l(interval) ) * interval_length );
startup_costs = sum(interval, output_startup_cost * output_capacity_MW * output_start.l(interval) + input_startup_cost * input_capacity_MW * input_start.l(interval) );
H2_revenue = sum(interval, H2_price(interval) * H2_sold.l(interval));
actual_operating_profit = arbitrage_revenue + regup_revenue + regdn_revenue + spinres_revenue + nonspinres_revenue + H2_revenue - startup_costs
                        + Fixed_dem_charge_cost + Timed_dem_1_cost + Timed_dem_2_cost + Timed_dem_3_cost + Timed_dem_4_cost + Timed_dem_5_cost + Timed_dem_6_cost + Meter_cost
                        + input_cap_cost2 + output_cap_cost2 + input_FOM_cost2 + output_FOM_cost2 + input_VOM_cost2 + output_VOM_cost2;

Hydrogen_fraction_val = Hydrogen_fraction.l*100;

Renewable_pen_input = sum(interval,input_power_MW_ren.l(interval) )/sum(interval,input_power_MW.l(interval));
Renewable_pen_input_net = sum(interval,Renewable_power(interval) )/sum(interval,input_power_MW.l(interval));
if (Renewable_pen_input_net>1,
         Renewable_pen_input_net=1;
         );



if (1=1,
option decimals=8;
display elec_in_MWh;
display elec_output_MWh;
display fuel_cost;
display elec_cost;
display VOM_cost_val;
display H2_revenue;
display regup_revenue;
display regdn_revenue;
display spinres_revenue;
display nonspinres_revenue;
display arbitrage_revenue;
display actual_operating_profit;
* display Fixed_cap_val;
* display cap_1_val;
* display cap_2_val;
* display cap_3_val;
* display cap_4_val;
* display cap_5_val;
* display cap_6_val;
* display Hydrogen_fraction_val;
*display current_interval;
*display next_interval;
*display current_storage_lvl;
*display current_monthly_max;
*display max_interval;
);

* - - - - write output to files - - - -
if( (arbitrage_and_AS.modelstat=1 or arbitrage_and_AS.modelstat=2 or arbitrage_and_AS.modelstat=8),

         put input_echo_file;
                 PUT 'Run on a %system.filesys% machine on %system.date% %system.time%.' /;
                 put 'Optimal solution found within time limit:,',
                 if ( optimal_solution_reached = 1,
                         put 'Yes' /;
                 else
                         put 'No' /;
                 );
                 put /;
                 put 'zone, %zone_instance%' /;
                 put 'year, %year_instance%' /;
                 put 'interval length (hours), ', interval_length /;
                 put 'operating period length (hours), ' operating_period_length /;
                 put 'additional look-ahead (hours), ' look_ahead_length /;
                 put 'output capacity (MW), ', output_capacity_MW /;
                 put 'input capacity (MW), ', input_capacity_MW   /;
                 put 'storage capacity (hours), ', storage_capacity_hours /;
                 put 'input efficiency (%), ', input_efficiency /;
                 put 'output efficiency (%), ', output_efficiency /;
                 put 'input heat rate (MMBtu/MWh), ', input_heat_rate /;
                 put 'ouptut heat rate (MMBtu/MWh), ', output_heat_rate /;
                 put 'variable O&M cost, ', VOM_cost /;
                 put 'regulation cost, ', reg_cost /;
                 put 'hydrogen use, ', H2_use /;
                 put /;
                 put 'input' /;
                 put 'LSL limit fraction, ', input_LSL_fraction /;
                 put 'reg up limit fraction, ', input_regup_limit_fraction /;
                 put 'reg down limit fraction, ', input_regdn_limit_fraction /;
                 put 'spining reserve limit fraction, ', input_spinres_limit_fraction /;
                 put 'startup cost ($/MW-start), ', input_startup_cost:0:10 /;
                 put 'minimum run intervals, ' min_input_on_intervals /;
                 put /;
                 put 'output' /;
                 put 'LSL limit fraction, ', output_LSL_fraction /;
                 put 'reg up limit fraction, ', output_regup_limit_fraction /;
                 put 'reg down limit fraction, ', output_regdn_limit_fraction /;
                 put 'spining reserve limit fraction, ', output_spinres_limit_fraction /;
                 put 'startup cost ($/MW-start), ', output_startup_cost:0:10 /;
                 put 'minimum run intervals, ', min_output_on_intervals /;
                 put /;
                 put 'Int, Elec Purchase ($/MWh), Elec Sale ($/MWh), Reg Up ($/MW), Reg Dn ($/MW), Spin Res ($/MW), Nospin Res ($/MW), Nat Gas ($/MMBTU), H2 ($/kg), Renewable In (MW), Load Profile (MW), Meter ($/mth)' /;
                 loop(interval, put      ord(interval),',',
                                         elec_purchase_price(interval),',',
                                         elec_sale_price(interval),',',
                                         regup_price(interval),',',
                                         regdn_price(interval),',',
                                         spinres_price(interval),',',
                                         nonspinres_price(interval),',',
                                         NG_price(interval),',',
                                         H2_price(interval),',',
                                         Renewable_power(interval),',',
                                         Load_profile(interval),',',
                                         meter_mnth_chg(interval) /;
                 );

         put results_file;
                 PUT 'Run on a %system.filesys% machine on %system.date% %system.time%.' /;
                 put 'Optimal solution found within time limit:,',
                 if ( optimal_solution_reached = 1,
                         put 'Yes' /;
                 else
                         put 'No' /;
                 );
                 put /;
                 put 'Renewable Capacity (MW), ', Renewable_MW /;
                 put 'Renewable Penetration for Input (%), ', Renewable_pen_input /;
                 put 'hydrogen use, ', H2_use /;
                 put /;
                 put 'actual operating profit, ', actual_operating_profit /;
                 put 'total electricity input (MWh), ', elec_in_MWh /;
                 put 'total electricity output (MWh), ', elec_output_MWh /;
                 put 'output to input ratio, ', output_input_ratio /;
                 put 'input capacity factor, ', input_capacity_factor /;
                 put 'output capacity factor, ', output_capacity_factor /;
                 put 'average regup (MW), ', avg_regup_MW /;
                 put 'average regdn (MW), ', avg_regdn_MW /;
                 put 'average spinres (MW), ', avg_spinres_MW /;
                 put 'average nonspinres (MW), ' avg_nonspinres_MW /;
                 put 'number of input power system starts, ' num_input_starts /;
                 put 'number of output power system starts, ' num_output_starts /;
                 put 'arbitrage revenue ($),', arbitrage_revenue /;
                 put 'regup revenue ($), ', regup_revenue /;
                 put 'regdn revenue ($), ', regdn_revenue /;
                 put 'spinres revenue ($), ', spinres_revenue /;
                 put 'nonspinres revenue ($), ', nonspinres_revenue /;
                 put 'hydrogen revenue ($), ', H2_revenue /;
                 put 'startup costs ($), ', startup_costs /;
                 put /;
                 put 'Interval, In Pwr (MW), Out Pwr (MW), Storage Level (MW-h), In Reg Up (MW), Out Reg Up (MW), In Reg Dn (MW), Out Reg Dn (MW), In Spin Res (MW), Out Spin Res (MW), In Nonspin (MW), Out Nonspin (MW), H2 Out (kg), Renewable Input (MW), Nonrenewable Input (MW)'/;
                 loop(interval, put      ord(interval),',',
                                         input_power_MW.l(interval),',',
                                         output_power_MW.l(interval),',',
                                         storage_level_MWh.l(interval),',',
                                         input_regup_MW.l(interval),',',
                                         output_regup_MW.l(interval),',',
                                         input_regdn_MW.l(interval),',',
                                         output_regdn_MW.l(interval),',',
                                         input_spinres_MW.l(interval),',',
                                         output_spinres_MW.l(interval),',',
                                         input_nonspinres_MW.l(interval),',',
                                         output_nonspinres_MW.l(interval),',',
                                         H2_sold.l(interval),',',
                                         input_power_MW_ren.l(interval),',',
                                         input_power_MW_non_ren.l(interval) /;
                 );

         put summary_file;
                 PUT 'Run on a %system.filesys% machine on %system.date% %system.time%.' /;
                 put 'Optimal solution found within time limit:,',
                 if ( optimal_solution_reached = 1,
                         put 'Yes' /;
                 else
                         put 'No' /;
                 );
                 put /;
                 put 'Renewable Capacity (MW), ', Renewable_MW /;
                 put 'Renewable Penetration for Input (%), ', Renewable_pen_input /;
                 put 'interval length (hours), ', interval_length /;
                 put 'operating period length (hours), ' operating_period_length /;
                 put 'additional look-ahead (hours), ' look_ahead_length /;
                 put 'output capacity (MW), ', output_capacity_MW /;
                 put 'input capacity (MW), ', input_capacity_MW   /;
                 put 'storage capacity (hours), ', storage_capacity_hours /
                 put 'input efficiency (%), ', input_efficiency /;
                 put 'output efficiency (%), ', output_efficiency /;
                 put 'input heat rate (MMBtu/MWh), ', input_heat_rate /;
                 put 'output heat rate (MMBtu/MWh), ', output_heat_rate /;
                 put 'variable O&M cost, ', VOM_cost /;
                 put 'regulation cost, ', reg_cost /;
                 put 'hydrogen use, ', H2_use /;
                 put /;
                 put 'input' /;
                 put 'LSL limit fraction, ', input_LSL_fraction /;
                 put 'reg up limit fraction, ', input_regup_limit_fraction /;
                 put 'reg down limit fraction, ', input_regdn_limit_fraction /;
                 put 'spining reserve limit fraction, ', input_spinres_limit_fraction /;
                 put 'startup cost ($/MW-start), ', input_startup_cost:0:10 /;
                 put 'minimum run intervals, ' min_input_on_intervals /;
                 put /;
                 put 'output' /;
                 put 'LSL limit fraction, ', output_LSL_fraction /;
                 put 'reg up limit fraction, ', output_regup_limit_fraction /;
                 put 'reg down limit fraction, ', output_regdn_limit_fraction /;
                 put 'spining reserve limit fraction, ', output_spinres_limit_fraction /;
                 put 'startup cost ($/MW-start), ', output_startup_cost:0:10 /;
                 put 'minimum run intervals, ', min_output_on_intervals /;
                 put /;
                 put 'actual operating profit ($), ', actual_operating_profit /;
                 put 'total electricity input (MWh), ', elec_in_MWh /;
                 put 'total electricity output (MWh), ', elec_output_MWh /;
                 put 'output to input ratio, ', output_input_ratio /;
                 put 'input capacity factor, ', input_capacity_factor /;
                 put 'output capacity factor, ', output_capacity_factor /;
                 put 'average regup (MW), ', avg_regup_MW /;
                 put 'average regdn (MW), ', avg_regdn_MW /;
                 put 'average spinres (MW), ', avg_spinres_MW /;
                 put 'average nonspinres (MW), ' avg_nonspinres_MW /;
                 put 'number of input power system starts, ' num_input_starts /;
                 put 'number of output power system starts, ' num_output_starts /;
                 put 'arbitrage revenue ($),', arbitrage_revenue /;
                 put 'regup revenue ($), ', regup_revenue /;
                 put 'regdn revenue ($), ', regdn_revenue /;
                 put 'spinres revenue ($), ', spinres_revenue /;
                 put 'nonspinres revenue ($), ', nonspinres_revenue /;
                 put 'hydrogen revenue ($), ', H2_revenue /;
                 put 'startup costs ($), ', startup_costs /;
                 put 'Fixed demand charge ($), ',Fixed_dem_charge_cost/;
                 put 'Timed demand charge 1 ($), ',Timed_dem_1_cost/;
                 put 'Timed demand charge 2 ($), ',Timed_dem_2_cost/;
                 put 'Timed demand charge 3 ($), ',Timed_dem_3_cost/;
                 put 'Timed demand charge 4 ($), ',Timed_dem_4_cost/;
                 put 'Timed demand charge 5 ($), ',Timed_dem_5_cost/;
                 put 'Timed demand charge 6 ($), ',Timed_dem_6_cost/;
                 put 'Meter cost ($), ',Meter_cost/;
                 put 'Renewable Penetration net meter (%), ', Renewable_pen_input_net /;
                 put 'Input annualized capital cost ($), ',input_cap_cost2 /;
                 put 'Output annualized capital cost ($), ',output_cap_cost2 /;
                 put 'Input FOM cost ($), ',input_FOM_cost2 /;
                 put 'Output FOM cost ($), ',output_FOM_cost2 /;
                 put 'Input VOM cost ($), ',input_VOM_cost2 /;
                 put 'Output VOM cost ($), ',output_VOM_cost2 /;
                 put /;

         if (next_interval>1,
               put RT_out_file;
                       put 'Interval, Electrolyzer Setpoint (MW)' /;
                       loop(next_int, put  next_interval,',',
                                           input_power_MW.l(next_int) /;
                       );
         );

else
*         put input_echo_file;
*                 put 'Error--solution not found.';
*         put results_file;
*                 put 'Error--solution not found.';
         put summary_file;
                 put 'Error--solution not found.';
*         put RT_out_file;
*                 put 'Error--soultion not found.';
);
