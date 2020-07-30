RODeO
=====
The Revenue, Operation, and Device Optimization (RODeO) model explores optimal system design and operation considering different levels of grid integration, equipment cost, operating limitations, financing, and credits and incentives. RODeO is a price-taker model formulated as a mixed-integer linear programming (MILP) model in the GAMS modeling platform. The objective is to maximizes the net revenue for a collection of equipment at a given site. The equipment includes generators (e.g., gas turbine, steam turbine, solar, wind, hydro, fuel cells, etc.), storage systems (batteries, pumped hydro, gas-fired compressed air energy storage, long-duration systems, hydrogen), and flexible loads (e.g., electric vehicles, electrolyzers, flexible building loads). The input data required by RODeO can be classified into three bins. 1). utility service data, which refers to retail utility rate information (meter cost, energy and demand charges).  2). Electricity market data, which include energy and reserve prices. 3) other inputs, which refer to additional electrical demand, product output demand, technological assumptions, financial properties, and operational parameters. 

This model requires GAMS (https://www.gams.com/) and an appropriate solver (developed using CPLEX). Additionally there are scripts written in Python and Matlab that can aid in input/output functionality but are not required to run RODeO. Below are seven easy steps to run RODeO.


Step 1.
Open the "Projects" folder and create a new project item by copying the "Test" folder.
Decide if you want to perform an analyis using wholesale or retail rates. If retail continue to step 2, if wholesale skip to step 4

Step 2.
Determine the retail utility rates that you want to model from URDB and populate "RODeO/Projects/Test/Data_files/CSV_data/Profile_selection/list_of_rates.csv" with the URDB id values


Step 3. 
Open "RODeO/create_tariff_files/example_tariff_generator.py".
Update "Analysis_path" with your desired path and run.


Step 4.
All files in "RODeO/Projects/Test/Data_files/TXT_files" can be created manually if preferred; however, if you are using retail rates or you want to create data input files in bulk you can use "RODeO/create_tariff_files/GAMS_output.m" in Matlab

Bulk file creation can be done by first, updating the files in "RODeO/Projects/Test/Data_files/CSV_data" that begin with "GAMS", as desired. Then running GAMS_output.m. With the exception of the "GAMS_AS.xlsx" all other files can be used to create multiple sets of inputs by increasing the number of columns with data, as shown in "GAMS_renewables.xlsx".
 
Running that script will create all the files needed to run RODeO except for "Devices_parameters_empty.csv", "Devices_ren_parameters_empty.csv" and "Compressors_cost.csv", which are already in the "Test" project directory. 


Step 5. 
Open Storage_dispatch.gms in GAMS.
Make desired adjustments.


Step 6.
If you are running from the GUI skip to the next step. If you want to run in parallel using batch files continue with this step.
Open "RODeO/Projects/Batch_files"
There are three methods to create batch files. 
1) Use "Gams caller text generator.xlsx" to create text strings which then can be split into multiple files using "Split_files.xlsx" and copied into batch files
2) Use GAMS_prep_batch_v6_3 if you are creating many complicated runs (>1000). This script uses relationship files between inputs to create batch runs
3) [NOT COMPLETE] Use "Run_GAMS_from_python.py" to run one or more runs from python.
Once the batch files are produced (for options 1 and 2). Copy them to the main RODeO directory (i.e., the folder that contains "Storage_dispatch.gms") and run them from there.


Step 7.
After running all of the desired scenarios the results are contained in the "RODeO/Projects/Test/Output" folder.
There are several ways of compiling those results.
1) Use "RODeO/Combine_output_files/combine_output_files.m" to combine all summary files into a single csv.
	Open the script file, set the destination folder, run the script. The output will be in the project "Output" folder titled "Combined_results1.csv"
2) Use "RODeO/Combine_output_files/GAMS_combine_csv_files.py" to combine any output files into a mySQL database. 
	Open the script file, use the first section to sort out machine readable information from the filename of each file. Then run.






