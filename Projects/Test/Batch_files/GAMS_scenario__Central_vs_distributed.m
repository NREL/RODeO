%% Contains Scenerio specific information to be loaded into GAMS_prep_batch_v6_2.m
%
%     Steps to add new fields
%       1. Add entry into Batch_header (Second section)
%       2. Add value(s) for new fields (Third section)

%% Initialize values
clear all, close all, clc
Project_name = 'Central_vs_distributed'; 

dir1 = 'C:\Users\jeichman\Documents\gamsdir\projdir\RODeO\';   % Set directory to send files
dir2 = [dir1,'Projects\',Project_name,'\Batch_files\'];
cd(dir1); 

% Define overall properties
GAMS_loc = 'C:\GAMS\win64\24.8\gams.exe';
GAMS_file= {'Storage_dispatch_v22_1'};      % Define below for each utility (3 file options)
GAMS_lic = 'license=C:\GAMS\win64\24.8\gamslice.txt';
files_to_create = 2;  % Select the number of batch files to create

outdir = ['Projects\',Project_name,'\Output'];
indir  = ['Projects\',Project_name,'\Data_files\TXT_files'];

% Load filenames
files_tariff = dir([dir1,indir]);
files_tariff2={files_tariff.name}';  % Identify files in a folder    
for i0=1:length(files_tariff2) % Remove items from list that do not fit criteria
    if ((~isempty(strfind(files_tariff2{i0},'additional_parameters'))+...
         ~isempty(strfind(files_tariff2{i0},'renewable_profiles'))+...
         ~isempty(strfind(files_tariff2{i0},'controller_input_values'))+...
         ~isempty(strfind(files_tariff2{i0},'building')))>0)     % Skip files called "additional_parameters" or "renewable profile" 
    else
        load_file1(i0)=~isempty(strfind(files_tariff2{i0},'.txt'));       % Find only txt files
    end
end 
files_tariff2=files_tariff2(load_file1);    clear load_file1 files_tariff

Batch_header = struct;

Batch_header.elec_rate_instance.val = strrep(files_tariff2,'.txt','');
Batch_header.H2_price_hourly.val = {'additional_parameters_hourly'};        
Batch_header.Hydrogen_consumed_hourly.val = {'H2_consumption_central_hourly','H2_consumption_distributed_hourly'};        
Batch_header.Input_power_baseload_hourly.val = {'Input_power_baseload_hourly'};        
Batch_header.NG_price_hourly.val = {'NG_price_Price1_hourly'};        
Batch_header.ren_prof_instance.val = {'renewable_profiles_none_hourly'};
Batch_header.load_prof_instance.val = {'Additional_load_Load1_hourly'};
Batch_header.energy_price_inst.val = {'Energy_prices_empty_hourly'};
Batch_header.AS_price_inst.val = {'Ancillary_services_hourly'};
[status,msg] = mkdir(outdir);       % Create output file if it doesn't exist yet  
Batch_header.outdir.val = {outdir}; % Reference is dynamic from location of batch file (i.e., exclue 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)
Batch_header.indir.val = {indir};       % Reference is dynamic from location of batch file (i.e., exclue 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)

Batch_header.gas_price_instance.val = {'NA'};
Batch_header.zone_instance.val = {'NA'};
Batch_header.year_instance.val = {'NA'};

Batch_header.input_cap_instance.val = {'1000'};
Batch_header.output_cap_instance.val = {'0'};
Batch_header.price_cap_instance.val = {'10000'};

Batch_header.Apply_input_cap_inst.val = {'0'};
Batch_header.Apply_output_cap_inst.val = {'0'};
Batch_header.max_output_cap_inst.val = {'inf'};
Batch_header.allow_import_instance.val = {'1'};

Batch_header.input_LSL_instance.val = {'0.1'};
Batch_header.output_LSL_instance.val = {'0'};
Batch_header.Input_start_cost_inst.val = {'0'};
Batch_header.Output_start_cost_inst.val = {'0'};
Batch_header.input_efficiency_inst.val = {'0.613668913'};
Batch_header.output_efficiency_inst.val = {'1'};

Batch_header.input_cap_cost_inst.val = {'0'};
Batch_header.output_cap_cost_inst.val = {'0'};
Batch_header.input_FOM_cost_inst.val = {'0'};
Batch_header.output_FOM_cost_inst.val = {'0'};
Batch_header.input_VOM_cost_inst.val = {'0'};
Batch_header.output_VOM_cost_inst.val = {'0'};
Batch_header.input_lifetime_inst.val = {'0'};
Batch_header.output_lifetime_inst.val = {'0'};
Batch_header.interest_rate_inst.val = {'0'};

Batch_header.in_heat_rate_instance.val = {'0'};
Batch_header.out_heat_rate_instance.val = {'0'};
Batch_header.storage_cap_instance.val = {'6'};
Batch_header.storage_set_instance.val = {'1'};
Batch_header.storage_init_instance.val = {'0.5'};
Batch_header.storage_final_instance.val = {'0.5'};
Batch_header.reg_cost_instance.val = {'0'};
Batch_header.min_runtime_instance.val = {'0'};
Batch_header.ramp_penalty_instance.val = {'0'};

Batch_header.op_length_instance.val = {'8760'};
Batch_header.op_period_instance.val = {'8760'};
Batch_header.int_length_instance.val = {'1'};

Batch_header.lookahead_instance.val = {'0'};
Batch_header.energy_only_instance.val = {'1'};        
Batch_header.file_name_instance.val = {'0'};    % 'file_name_instance' created in the next section (default value of 0)
Batch_header.H2_consume_adj_inst.val = {'0.9'};
Batch_header.H2_price_instance.val = {'6'};
Batch_header.H2_use_instance.val = {'1'};
Batch_header.base_op_instance.val = {'0','1'};
Batch_header.NG_price_adj_instance.val = {'1'};
Batch_header.Renewable_MW_instance.val = {'0'};

Batch_header.CF_opt_instance.val = {'0'};
Batch_header.run_retail_instance.val = {'1'};
Batch_header.one_active_device_inst.val = {'1'};

Batch_header.current_int_instance.val = {'-1'};
Batch_header.next_int_instance.val = {'1'};
Batch_header.current_stor_intance.val = {'0.5'};
Batch_header.current_max_instance.val = {'0.8'};
Batch_header.max_int_instance.val = {'Inf'};
Batch_header.read_MPC_file_instance.val = {'0'};
