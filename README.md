RODeO
=====
The Revenue, Operation, and Device Optimization (RODeO) model explores optimal system design and operation considering different levels of grid integration, equipment cost, operating limitations, financing, and credits and incentives. RODeO is a price-taker model formulated as a mixed-integer linear programming (MILP) model in the GAMS modeling platform. The objective is to maximizes the net revenue for a collection of equipment at a given site. The equipment includes generators (e.g., gas turbine, steam turbine, solar, wind, hydro, fuel cells, etc.), storage systems (batteries, pumped hydro, gas-fired compressed air energy storage, long-duration systems, hydrogen), and flexible loads (e.g., electric vehicles, electrolyzers, flexible building loads). The input data required by RODeO can be classified into three bins. 1). utility service data, which refers to retail utility rate information (meter cost, energy and demand charges).  2). Electricity market data, which include energy and reserve prices. 3) other inputs, which refer to additional electrical demand, product output demand, technological assumptions, financial properties, and operational parameters. 

This model requires GAMS (https://www.gams.com/) and an appropriate solver (developed using CPLEX). Additionally there are scripts written in Python and Matlab that can aid in input/output functionality but are not required to run RODeO. Below are seven easy steps to run RODeO.


## Preparing to run RODeO

**Step 1.**
Open the "Projects" folder and create a new project item by copying the "Test" folder.
Decide if you want to perform an analyis using wholesale or retail rates. If retail continue to step 2, if wholesale skip to step 4

**Step 2.**
Determine the retail utility rates that you want to model from URDB and populate "RODeO/Projects/Test/Data_files/CSV_data/Profile_selection/list_of_rates.csv" with the URDB id values


**Step 3.**
Open "RODeO/create_tariff_files/example_tariff_generator.py".
Update "Analysis_path" with your desired path and run.


**Step 4.**
All files in "RODeO/Projects/Test/Data_files/TXT_files" can be created manually if preferred; however, if you are using retail rates or you want to create data input files in bulk you can use "RODeO/create_tariff_files/GAMS_output.m" in Matlab

Bulk file creation can be done by first, updating the files in "RODeO/Projects/Test/Data_files/CSV_data" that begin with "GAMS", as desired. Then running GAMS_output.m. With the exception of the "GAMS_AS.xlsx" all other files can be used to create multiple sets of inputs by increasing the number of columns with data, as shown in "GAMS_renewables.xlsx".
 
Running that script will create all the files needed to run RODeO except for "Devices_parameters_empty.csv", "Devices_ren_parameters_empty.csv" and "Compressors_cost.csv", which are already in the "Test" project directory. 


**Step 5.** 
Open Storage_dispatch.gms in GAMS.
Make desired adjustments. See more detailed description of model inputs further down in the README.


**Step 6.**
If you are running from the GUI skip to the next step. If you want to run in parallel using batch files continue with this step.
Open "RODeO/Projects/Batch_files"
There are three methods to create batch files. 
1) Use "Gams caller text generator.xlsx" to create text strings which then can be split into multiple files using "Split_files.xlsx" and copied into batch files
2) Use GAMS_prep_batch_v6_3 if you are creating many complicated runs (>1000). This script uses relationship files between inputs to create batch runs
3) [NOT COMPLETE] Use "Run_GAMS_from_python.py" to run one or more runs from python.
Once the batch files are produced (for options 1 and 2). Copy them to the main RODeO directory (i.e., the folder that contains "Storage_dispatch.gms") and run them from there.


**Step 7.**
After running all of the desired scenarios the results are contained in the "RODeO/Projects/Test/Output" folder.
There are several ways of compiling those results.
1) Use "RODeO/Combine_output_files/combine_output_files.m" to combine all summary files into a single csv.
	Open the script file, set the destination folder, run the script. The output will be in the project "Output" folder titled "Combined_results1.csv"
2) Use "RODeO/Combine_output_files/GAMS_combine_csv_files.py" to combine any output files into a mySQL database. 
	Open the script file, use the first section to sort out machine readable information from the filename of each file. Then run.




## Setting up RODeO for your analysis

At a high level, RODeO will take in direct input or load from files and perform the desired optimization. There are several toggles that change the mode of operation that are important to understand and will be described below along with a general description of other inputs. Additional details can also be found in the code.

**Property** | **Description**
------------ | -------------
*run_opt_breakeven* | Switches to an iteration mode that updates the product cost until a break-even value across the lifetime is achieved
*NEM_nscr* | Toggles on and off the use of Net Energy Metering (NEM)
*Max_input_prof_inst* | The maximum setpoint for input devices as a fraction of their installed power
*Max_output_prof_inst* | The maximum setpoint for output devices as a fraction of their installed power
*product_consumed_inst* | The normalized profile for the sale of product
*elec_rate_instance* | The retail rate used. If *run_retail_instance* is set to use wholesale rates then it doesn't matter what rate is selected here.
*load_prof_instance* | The additional load that must be met.
*AS_price_inst* | The ancillary service prices including regulation up, regulation down, spinning reserve and non-spinning reserve.
*Device_parameters_inst* | Table of parameters that can be used to define multiple unique generator, storage or demand response devices to be simultaneously optimized.
*Device_ren_params_inst* | Table of parameters that can be used to define multiple unique renewable devices on the system to be simultaneously optimized.
*energy_purchase_price_inst* | Wholesale electricity purchase price
*energy_sale_price_inst* | Wholesale electricity sale price
*MACRS_instance* | Desired MACRS depreciation schedule
*NG_price_instance* | Normalized timeseries of natural gas prices (later multiplied by *NG_price_adj_instance*)
*NSCR_instance* | Net Surplus Compensation Rate. Used for determining the revenue from the sale of excess electricity to the grid under NEM rates
*product_price_prof_inst* | Normalized (max is 1) timeseries of product sale prices (later multiplied by *Product_price_instance*)
*ren_prof_instance* | Normalized (max is 1) timeseries of renewable generation from renewable device (later multiplied by *Renewable_MW_instance*)
*outdir* | Path to output directory (because of the potential size of this folder github will not save data in this folder [see .gitignore in repository])
*indir* | Path to input directory
 | 
*file_name_instance* | User defined filename for the outputs (consider making this structured and machine readable for later processing)
*devices_instance* | Determines the number of devices to be optimized (if greater than 1 RODeO will draw from *Device_parameters_inst*
*use_alt_devices* | Used to create an alternative technology to compare with all devices (e.g., compare the cost of an electric bus fleet to a diesel hybrid bus fleet without post-processing)
*use_all_devices* | Forces operation of all installed devices (goes along with *use_alt_devices*, *use_smart_charging*, and *soft_cons_device_inst*)
*use_smart_charging* | Similar to *use_alt_devices* this allows for comparison between optimized and non-optimized device charging without post-processing (e.g., compare immediate vehicle charging to smart charging). This input relies on *Storage_penalty* to force immediate charging by adding a large penalty value for any delay in charging.
*soft_cons_device_inst* | Specialized input that will incrementally reduce the capacity factor setpoint for fixed capacity factor devices until a feasible solution is achieved. (this was coded for modeling a fleet of electric buses that must deal with charging constraints). This input also relies on *CF_penalty* and *CF_incremental_change_value* as setpoints.
*input_cap_instance* | Input storage or demand response installed capacity. [MW]
*output_cap_instance* | Output generator or storage installed capacity. [MW]
*Renewable_MW_instance* | Sets the installed renewable capacity [MW]
 | 
*price_cap_instance* | Implements a cap on *energy_purchase_price_inst* and *energy_sale_price_inst* [$/MWh]
*max_output_cap_inst* | Implements a maximum AC export power (e.g., inverter size) [MW]
*max_input_cap_inst* | Implements a maximum AC import power [MW]
*allow_import_instance* | Enables or disables electricity import from the grid 
*allow_sales_instance* | Enables or disables electricity export to the grid
 | 
*input_LSL_instance* | Lower sustainable operation limit fraction for input device [0 to 1] (i.e., the input device will operate between 100% capacity and this value but must shutoff at any setpoints below this value). 
*output_LSL_instance* | Lower sustainable operation limit fraction for output device [0 to 1] (i.e., the output device will operate between 100% capacity and this value but must shutoff at any setpoints below this value).
*Input_start_cost_inst* | Cost value for the input device to start [$/start]
*Output_start_cost_inst* | Cost value for the output device to start [$/start]
*input_efficiency_inst* | Efficiency of input device [0 to 1]
*output_efficiency_inst* | Efficiency of output device [0 to 1]
*input_heat_rate* | Input heatrate for devices that consume natural gas (e.g., steam methane reformer) [MMBtu/MWh produced]
*output_heat_rate* | Output heatrate for devices that consume natural gas (e.g., combustion turbine) [MMBtu/MWh produced]
 | 
*renew_cap_cost_inst* | Renewable device capital cost [$/MW]
*input_cap_cost_inst* | Input device capital cost [$/MW]
*input_cap_alt_cst_inst* | Alternate input device capital cost [$/MW] (goes along with *use_alt_devices*)
*output_cap_cost_inst* | Output device capital cost [$/MW]
*ProdStor_cap_cost_inst* | Capital cost for energy storage [$/unit of product] (included if purchased separately, e.g., hydrogen tank)
*ProdComp_cap_cost_inst* | Capital cost for compressor [$/unit of product/hour]
*renew_FOM_cost_inst* | Renewable device fixed operation and maintenance cost [$/MW-yr]
*input_FOM_cost_inst* | Input device fixed operation and maintenance cost [$/MW-yr]
*input_FOM_alt_cost_inst* | Alternate input device fixed operation and maintenance cost [$/MW-yr] (goes along with *use_alt_devices*)
*output_FOM_cost_inst* | Output device fixed operation and maintenance cost [$/MW-yr]
*input_VOM_cost_inst* | Variable operation and maintenance cost for input device [$/MWh]
*output_VOM_cost_inst* | Variable operation and maintenance cost for output device [$/MWh]
 | 
*storage_cap_instance* | Hours of duration for **input device** to fill the storage system [hours] (can be changed to output device by changing *storage_level_accounting_init_eqn*, *storage_level_accounting_final_eqn*, and *storage_level_limit_eqn* in GAMS)
*storage_set_instance* | Toggles a feature that sets the initial volume and end volume levels (particularly useful for long-duration energy storage)
*storage_init_instance* | Setpoint for the initial volume level as a fraction of the entire storage system [0 to 1]
*storage_final_instance* | Setpoint for the final volume level as a fraction of the entire storage system [0 to 1]
*stor_dissipation_inst* | Storage dissipation term as a percentage of input power. Dissipation occurs every interval at this level [0 to 1]
*reg_cost_instance* | Variable costs associated with providing regulation [$/MW-h]
*min_runtime_instance* | The minimum number of intervals that the input and output device must be on. 
*ramp_penalty_instance* | Penalty for ramping input and output devices [$/MW/interval]
 | 
*wacc_instance* | Weighted Average Cost of Capital (this value is calculated based on the next values)
*perc_equity_instance* | Percentage of equity towards the capital cost of all devices [0 to 1]
*ror_instance* | Rate of Return [0 to 1]
*roe_instance* | Rate of equity [0 to 1]
*debt_interest_instance* | Interest rate on debt [0 to 1]
*cftr_instance* | Combined Federal and local taxes [0 to 1]
*bonus_deprec_instance* | Bonus depreciation fraction [0 to 1]
*inflation_inst* | Annual inflation rate [0 to 1]
*study_years_inst* | Years considered in study period [years]
 | 
*op_length_instance* | Number of time intervals in study period
*op_period_instance* | Number of intervals in each operating period (rolling solution window)
*int_length_instance* | Length of interval (e.g., 1 for hourly, 0.25 for 15 minute)
*lookahead_instance* | Number of additional intervals to look past the current operating period
 | 
*energy_only_instance* | Toggle between optimizing only energy arbitrage and co-optimizing energy arbitrage and ancillary services
*Product_use_instance* | Determines if product is sold
*product_conv_inst* | Conversion factor used to establish the units of product produced, stored, and sold (e.g., hydrogen, electricity)
*CF_opt_instance* | Toggle to enable or disable optimization of the capacity factor
*CF_adj_inst* | If *CF_opt_instance* is toggled off then this value sets a fixed capacity factor
*Product_price_instance* | Sets the product price if product is sold [$/unit of product] (this value acts as an initial estimate if *run_opt_breakeven* is toggled on)
*base_op_instance* | Toggle that forces the input device to operate in baseload mode (i.e., at rated capacity for every interval)
*NG_price_adj_instance* | Sets the price of natural gas [$/MMBtu]
*REC_price_inst* | Price for Renewable Energy Credits (RECs) [$/MWh]
*run_retail_instance* | Toggles between different grid interaction configurations (wholesale, retail and hybrid)
*NBC_instance* | NEM2.0 Non-bypassable charges [$/MWh]
*one_active_device_inst* | Toggle that enables or disables storage devices from simultaneously charging and discharging
*ITC_inst* | Business Energy Investment Tax Credit (ITC) level [0 to 1]. Determines the fraction of capital cost that is eligible for a tax subsidy.
 | 
*current_int_instance* | Current interval for real-time controller optimization
*next_int_instance* | Next interval for real-time controller optimization
*current_stor_instance* | Current storage level for real-time controller optimization [0 to 1]
*current_max_instance* | Current monthly maximum demand for real-time controller optimization of retail rates [0 to 1]
*max_int_instance* | Maximum interval for real-time controller optimization
*read_MPC_file_instance* | Toggle to enable or disable the model from read controller values from csv file *controller_input_values.csv*.
 | 
*EneDens_inst* | Energy density of fuel (e.g., H2 = 120 MJ/kg)
*EER_inst* | Energy economy ratio relative to alternative fuel (pull from CARB documentation)
*Grid_CarbInt_inst* | Carbon intensity of electricity from the grid [gCO2e/MJ] (pull from CARB documentation)
*CI_base_line_inst* | Base line carbon intensity for the displaced fuel and current year [gCO2e/MJ] (pull from CARB documentation)
*LCFS_price_inst* | Low Carbon Fuel Standard credit prices [$ per credit]


