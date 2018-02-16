%%  RODeO batch Prep file
%
%     Creates batch file by quickly assembling different sets of runs and 
%       can create multiple batch files for parallel processing
%
%     Steps to run
%       1. Select Project_name
%       2. Adjust any other properties in Section 1
%       3. Setup values in Batch_header in Section 2
%       4. Add relationships between fields by loading files in Section 3
%            (Make sure that you appropraitely define the relationships between properties)
%       5. Adjust filename creatino in Section 6 as necessary
% 

%% SECTION 1: Prepare data to populate batch file.
clear all, close all, clc
disp(['Prepare data...'])

Project_name = 'Central_vs_distributed';
% Project_name = 'Example';

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
files_tariff2={files_tariff.name}';             % Identify files in a folder    
load_file1 = zeros(1,length(files_tariff2));    % Initialize matrix
for i0=1:length(files_tariff2)                  % Remove items from list that do not fit criteria
    if ((~isempty(strfind(files_tariff2{i0},'additional_parameters'))+...
         ~isempty(strfind(files_tariff2{i0},'renewable_profiles'))+...
         ~isempty(strfind(files_tariff2{i0},'controller_input_values'))+...
         ~isempty(strfind(files_tariff2{i0},'building')))>0)     % Skip files called "additional_parameters" or "renewable profile" 
    else
        load_file1(i0)=~isempty(strfind(files_tariff2{i0},'.txt'));       % Find only txt files
    end
end 
files_tariff2=files_tariff2(find(load_file1));    clear load_file1 files_tariff

files_add_load = dir([dir1,indir]);
files_add_load2={files_add_load.name}';         % Identify files in a folder
load_file1 = zeros(1,length(files_add_load2));  % Initialize matrix
for i0=1:length(files_add_load2)                % Remove items from list that do not fit criteria
    if ~isempty(strfind(files_add_load2{i0},'Additional_load')>0)
        load_file1(i0)=~isempty(strfind(files_add_load2{i0},'.csv'));	 % Find only Additional load csv files        
    end
end 
files_add_load2=files_add_load2(find(load_file1));    clear load_file1 files_add_load


%% SECTION 2: Set values to vary by scenario
disp(['Set batch file values...'])
if strcmp(Project_name,'Central_vs_distributed')
%%% Central_vs_distributed
    Batch_header.elec_rate_instance.val = strrep(files_tariff2,'.txt','');
    Batch_header.H2_consumed_instance.val = {'H2_consumption_central_hourly','H2_consumption_distributed_hourly'};        
    Batch_header.baseload_pwr_instance.val = {'Input_power_baseload_hourly'};        
    Batch_header.NG_price_instance.val = {'NG_price_Price1_hourly'};        
    Batch_header.ren_prof_instance.val = {'renewable_profiles_none_hourly'};
    Batch_header.load_prof_instance.val = strrep(files_add_load2,'.csv','');
    Batch_header.energy_price_inst.val = {'Energy_prices_empty_hourly'};
    Batch_header.AS_price_inst.val = {'Ancillary_services_hourly'};
    [status,msg] = mkdir(outdir);       % Create output file if it doesn't exist yet  
    Batch_header.outdir.val = {outdir}; % Reference is dynamic from location of batch file (i.e., exclue 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)
    Batch_header.indir.val = {indir};   % Reference is dynamic from location of batch file (i.e., exclue 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)

    Batch_header.gas_price_instance.val = {'NA'};
    Batch_header.zone_instance.val = {'NA'};
    Batch_header.year_instance.val = {'NA'};

    % Input capacity and location relationship
    [~,~,raw0]=xlsread([indir,'\Match_inputcap_station']);  % Load file(s) 
    header1 = raw0(1,:);                                    % Pull out header file
    raw0 = raw0(2:end,:);                                   % Remove first row
    raw0 = cellfun(@num2str,raw0,'UniformOutput',false);    % Convert any numbers to strings
    input_cap_instance_values = unique(raw0(:,1));          % Find unique capacity values
    input_cap_instance_values(strcmp(input_cap_instance_values,'NaN')) = [];    % Removes NaNs                        
    
    Batch_header.input_cap_instance.val = input_cap_instance_values';
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

    % Input capacity and location relationship
    [~,~,raw1]=xlsread([indir,'\Match_capcost_FOM']);       % Load file(s) 
    header1 = raw1(1,:);                                    % Pull out header file
    raw1 = raw1(2:end,:);                                   % Remove first row
    raw1 = cellfun(@num2str,raw1,'UniformOutput',false);    % Convert any numbers to strings
    input_cap_cost_inst_values = unique(raw1(:,1));         % Find unique capacity values
    input_FOM_cost_inst_values = unique(raw1(:,2));         % Find unique capacity values
    
    Batch_header.input_cap_cost_inst.val = input_cap_cost_inst_values;
    Batch_header.output_cap_cost_inst.val = {'0'};
    Batch_header.input_FOM_cost_inst.val = input_FOM_cost_inst_values;
    Batch_header.output_FOM_cost_inst.val = {'0'};
    Batch_header.input_VOM_cost_inst.val = {'0'};
    Batch_header.output_VOM_cost_inst.val = {'0'};
    Batch_header.input_lifetime_inst.val = {'0','20','40'};      % Central, Forecourt
    Batch_header.output_lifetime_inst.val = {'0'};
    Batch_header.interest_rate_inst.val = {'0.07'};

    Batch_header.in_heat_rate_instance.val = {'0'};
    Batch_header.out_heat_rate_instance.val = {'0'};
    Batch_header.storage_cap_instance.val = {'0','8','24'};
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
    Batch_header.file_name_instance.val = {'0'};    % 'file_name_instance' created in a later section (default value of 0)
    Batch_header.H2_consume_adj_inst.val = {'1','0.9'};
    Batch_header.H2_price_instance.val = {'0'};
    Batch_header.H2_use_instance.val = {'1'};
    Batch_header.base_op_instance.val = {'0'};
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
elseif strcmp(Project_name,'Example')
%%% Example
    Batch_header.elec_rate_instance.val         = strrep(files_tariff2,'.txt','');
    Batch_header.H2_consumed_instance.val       = {'H2_consumption_flat_hourly'};        
    Batch_header.baseload_pwr_instance.val      = {'Input_power_baseload_hourly'};        
    Batch_header.NG_price_instance.val          = {'NG_price_Price1_hourly'};        
    Batch_header.ren_prof_instance.val          = {'renewable_profiles_none_hourly'};
    Batch_header.load_prof_instance.val         = {'Additional_load_Station1_hourly'};
    Batch_header.energy_price_inst.val          = {'Energy_prices_empty_hourly'};
    Batch_header.AS_price_inst.val              = {'Ancillary_services_hourly'};
    [status,msg] = mkdir(outdir);       % Create output file if it doesn't exist yet  
    Batch_header.outdir.val = {outdir}; % Reference is dynamic from location of batch file (i.e., exclue 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)
    Batch_header.indir.val = {indir};   % Reference is dynamic from location of batch file (i.e., exclue 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)

    Batch_header.gas_price_instance.val         = {'NA'};
    Batch_header.zone_instance.val              = {'NA'};
    Batch_header.year_instance.val              = {'NA'};

    Batch_header.input_cap_instance.val         = {'0','1300','2600','3900'};
    Batch_header.output_cap_instance.val        = {'0'};
    Batch_header.price_cap_instance.val         = {'10000'};

    Batch_header.Apply_input_cap_inst.val       = {'0'};
    Batch_header.Apply_output_cap_inst.val      = {'0'};
    Batch_header.max_output_cap_inst.val        = {'inf'};
    Batch_header.allow_import_instance.val      = {'1'};

    Batch_header.input_LSL_instance.val         = {'0.1'};
    Batch_header.output_LSL_instance.val        = {'0'};
    Batch_header.Input_start_cost_inst.val      = {'0'};
    Batch_header.Output_start_cost_inst.val     = {'0'};
    Batch_header.input_efficiency_inst.val      = {'1'};
    Batch_header.output_efficiency_inst.val     = {'1'};

    Batch_header.input_cap_cost_inst.val        = {'0'};
    Batch_header.output_cap_cost_inst.val       = {'0'};
    Batch_header.input_FOM_cost_inst.val        = {'0'};
    Batch_header.output_FOM_cost_inst.val       = {'0'};
    Batch_header.input_VOM_cost_inst.val        = {'0'};
    Batch_header.output_VOM_cost_inst.val       = {'0'};
    Batch_header.input_lifetime_inst.val        = {'0'};
    Batch_header.output_lifetime_inst.val       = {'0'};
    Batch_header.interest_rate_inst.val         = {'0'};

    Batch_header.in_heat_rate_instance.val      = {'0'};
    Batch_header.out_heat_rate_instance.val     = {'0'};
    Batch_header.storage_cap_instance.val       = {'6'};
    Batch_header.storage_set_instance.val       = {'1'};
    Batch_header.storage_init_instance.val      = {'0.5'};
    Batch_header.storage_final_instance.val     = {'0.5'};
    Batch_header.reg_cost_instance.val          = {'0'};
    Batch_header.min_runtime_instance.val       = {'0'};
    Batch_header.ramp_penalty_instance.val      = {'0'};

    Batch_header.op_length_instance.val         = {'8760'};
    Batch_header.op_period_instance.val         = {'8760'};
    Batch_header.int_length_instance.val        = {'1'};

    Batch_header.lookahead_instance.val         = {'0'};
    Batch_header.energy_only_instance.val       = {'1'};        
    Batch_header.file_name_instance.val         = {'0'};    % 'file_name_instance' created in a later section (default value of 0)
    Batch_header.H2_consume_adj_inst.val        = {'0.97','0.95','0.9','0.8'};
    Batch_header.H2_price_instance.val          = {'6'};
    Batch_header.H2_use_instance.val            = {'1'};
    Batch_header.base_op_instance.val           = {'0'};
    Batch_header.NG_price_adj_instance.val      = {'1'};
    Batch_header.Renewable_MW_instance.val      = {'0'};

    Batch_header.CF_opt_instance.val            = {'0'};
    Batch_header.run_retail_instance.val        = {'1'};
    Batch_header.one_active_device_inst.val     = {'1'};

    Batch_header.current_int_instance.val       = {'-1'};
    Batch_header.next_int_instance.val          = {'1'};
    Batch_header.current_stor_intance.val       = {'0.5'};
    Batch_header.current_max_instance.val       = {'0.8'};
    Batch_header.max_int_instance.val           = {'Inf'};
    Batch_header.read_MPC_file_instance.val     = {'0'};
else
%%% Default
    Batch_header.elec_rate_instance.val = strrep(files_tariff2,'.txt','');
    Batch_header.H2_price_hourly.val = {'additional_parameters_hourly'};        
    Batch_header.H2_consumed_instance.val = {'H2_consumption_hourly'};        
    Batch_header.baseload_pwr_instance.val = {'Input_power_baseload_hourly'};        
    Batch_header.NG_price_instance.val = {'NG_price_hourly'};        
    Batch_header.ren_prof_instance.val = {'renewable_profiles_none_hourly'};
    Batch_header.load_prof_instance.val = {'Additional_load_hourly'};
    Batch_header.energy_price_inst.val = {'Energy_prices_hourly'};
    Batch_header.AS_price_inst.val = {'Ancillary_services_hourly'};
    [status,msg] = mkdir(outdir);           % Create output file if it doesn't exist yet  
    Batch_header.outdir.val = {outdir};     % Reference is dynamic from location of batch file (i.e., exclude 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)
    Batch_header.indir.val = {indir};       % Reference is dynamic from location of batch file (i.e., exclude 'RODeO\' in the filename for batch runs but include for runs within GAMS GUI)

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
    Batch_header.file_name_instance.val = {'0'};    % 'file_name_instance' created in a later section (default value of 0)
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
end
fields1 = fieldnames(Batch_header);

%% SECTION 3: Define how values are varied between fields
%  Load excel files that contain relationships between values. 
%  The load_relation_file.m function will process the files and adjust Batch_header appropriately
disp(['Define relationship between fields...'])
if strcmp(Project_name,'Central_vs_distributed')
%%% Central_vs_distributed
    V1 = length(Batch_header.input_cap_instance.val);
    V2 = length(Batch_header.H2_consume_adj_inst.val);
    V3 = length(Batch_header.load_prof_instance.val);
    V4 = length(Batch_header.H2_consumed_instance.val);
    V5 = length(Batch_header.elec_rate_instance.val);
   
    % Each file constructs relationship between two fields (field names should be in first row)
    load_files1 = {'Match_inputcap_CF','Match_inputcap_load','Match_inputcap_rates',...
                   'Match_inputcap_H2Cons','Match_load_rates','Match_load_storagecap',...
                   'Match_inputcap_capcost','Match_inputcap_FOM','Match_capcost_FOM','Match_inputcap_lifetime'};    
    Batch_header = load_relation_file(load_files1,indir,Batch_header);  % Run function file load_relation_file
elseif strcmp(Project_name,'Example')
%%% Example
    Batch_header.input_cap_instance.H2_consume_adj_inst = [1,0,0,0;1,1,1,1;1,1,1,1;1,1,1,1];
else   
%%% Default
end
fprintf('\n') 

%% SECTION 4: Create 2D matrix and reduce based on relationships
relationship_matrix = [];
fields1_length = numel(fields1);
for i0=1:fields1_length        
    num_items = numel(Batch_header.(fields1{i0}).val);
    if i0==1,
        relationship_matrix = [1:num_items]';
    else
        [M0,N0] = size(relationship_matrix);               
        relationship_matrix_interim = relationship_matrix;  % Copy matrix to repeat
        fields1_val = [1:num_items]';                       % Capture all values for selected field        
        fields2_val = Batch_header.(fields1{i0}).val;       % Capture all values for selected field        
        for i1=1:num_items
            add_column = ones(M0,1)*i1;                     % Create empty matrix to add to existing matrix
            relationship_matrix_interim([(i1-1)*M0+1:i1*M0],[1:(N0+1)]) = [relationship_matrix,add_column]; 
        end
        relationship_matrix = relationship_matrix_interim;  % Overwrite matrix with completed 
    end  
    
    %%% Check to see if any relationships exist for the current item
    fields2 = fieldnames(Batch_header.(fields1{i0}));
    [M1,~] = size(fields2);
    if i0==1        
    elseif M1>1
        for i1=2:M1
            [M0,N0] = size(relationship_matrix); 
            find_index1 = i0;                                       % Repeat value for i0
            find_index2 = strfind(fields1,fields2(i1));             % Find string in cell array 
            find_index2 = find(not(cellfun('isempty',find_index2)));% Find string in cell array 
            if find_index2>i0
                continue            % Skip applying relationships for columns that have not been added yet as the matrix expands
            end
            find_val1 = Batch_header.(fields1{find_index1}).val;    % Find values in row
            find_val2 = Batch_header.(fields1{find_index2}).val;    % Find values in column
            find_rel1 = Batch_header.(fields1{find_index1}).(fields1{find_index2});  % Find relationship between items

            relationship_toggle = zeros(M0,1);
            for i2=1:M0
                [~,~,ib] = intersect(relationship_matrix(i2,[find_index1,find_index2]),find_rel1,'rows');
                if isempty(ib)
                    relationship_toggle(i2)=1;
                end                
            end            
            relationship_matrix(find(relationship_toggle(:)),:)=[];           
        end
    end 
    if i0==1
        fprintf('Completed %3d of %3d',i0,fields1_length)
    else
        fprintf('%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%c%cCompleted %3d of %3d',8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,8,i0,fields1_length)
    end
end
clear i0 M0 N0 add_column relationship_matrix_interim relationship_toggle
fprintf('\n'), fprintf('\n') 


%% SECTION 5: Convert integer matrix to cell array
[~,N0] = size(relationship_matrix); 
relationship_matrix_final = cell(size(relationship_matrix));
for i0=1:N0
     find_index1 = i0;                                       % Repeat value for i0
     find_val1 = Batch_header.(fields1{find_index1}).val;    % Find values in row
     relationship_matrix_final(:,i0) = find_val1(relationship_matrix(:,i0));    
end

%% SECTION 6: Create file names
disp(['Create file names...'])
[M0,~] = size(relationship_matrix); 
if strcmp(Project_name,'Central_vs_distributed')
%%% Central_vs_distributed
    Index_file_name = strfind(fields1,'file_name_instance');    Index_file_name = find(not(cellfun('isempty',Index_file_name)));
    Index_elec_rate = strfind(fields1,'elec_rate_instance');    Index_elec_rate = find(not(cellfun('isempty',Index_elec_rate)));
    Index_base = strfind(fields1,'base_op_instance');           Index_base = find(not(cellfun('isempty',Index_base)));
    Index_CF = strfind(fields1,'H2_consume_adj_inst');          Index_CF = find(not(cellfun('isempty',Index_CF)));
    Index_H2_cons = strfind(fields1,'H2_consumed_instance');    Index_H2_cons = find(not(cellfun('isempty',Index_H2_cons)));
    Index_load = strfind(fields1,'load_prof_instance');         Index_load = find(not(cellfun('isempty',Index_load)));
    Index_input_cap = strfind(fields1,'input_cap_instance');    Index_input_cap = find(not(cellfun('isempty',Index_input_cap)));
    Index_capcost = strfind(fields1,'input_cap_cost_inst');     Index_capcost = find(not(cellfun('isempty',Index_capcost)));
    
    
    % Select timeframe  (used for interim5)      
    [~,~,timeframe1] = xlsread([indir,'\','Match_inputcap_capcost']);       % Load file(s) 
    timeframe1 = timeframe1(2:end,2:3);                                     % Pull out header file
    timeframe1 = cellfun(@num2str,timeframe1,'UniformOutput',false);        % Convert any numbers to strings
    [M1,~] = size(timeframe1);
    timeframe2 = cell(M1,1);        
    for i1=1:M1, timeframe2{i1} = strjoin(timeframe1(i1,:)); end            % Concatenate cell array
    [~,idxTime]=unique(timeframe2);                                         % Find unique rows in concatenated cell array

    for i0=1:M0    
        interim1 = relationship_matrix_final{i0,Index_elec_rate};
        Find_underscore1 = strfind(interim1,'_');
        interim1 = interim1(1:Find_underscore1-1);    

        interim2 = relationship_matrix_final{i0,Index_load};
        interim2 = strrep(interim2,'Additional_load_','');
        interim2 = strrep(interim2,'_hourly','');
        interim2 = strrep(interim2,'Central','');
        interim2 = strrep(interim2,'Dist','');
        if strcmp(interim2,'none')==1               % If value is none then change
            Index_location = strfind(raw0(:,1),relationship_matrix_final{i0,Index_input_cap});
            Index_location = find(not(cellfun('isempty',Index_location)));
            interim2 = [raw0{Index_location,2}];
        end

        interim3 = relationship_matrix_final{i0,Index_CF};
        interim3 = ['CF',num2str(round(str2num(interim3)*100,0))];

        interim4 = relationship_matrix_final{i0,Index_H2_cons};
        
        interim5 = timeframe1{[idxTime(strcmp(timeframe1(idxTime,1),relationship_matrix_final(i0,Index_capcost)))],2};

        if strcmp(interim4,'H2_consumption_central_hourly'),     interim4='Central';
        elseif strcmp(interim4,'H2_consumption_distributed_hourly'), interim4='Distributed';
        end
        relationship_matrix_final{i0,Index_file_name} = horzcat(interim1,'_',interim2,'_',interim3,'_',interim4,'_',interim5);
    end
elseif strcmp(Project_name,'Example')
%%% Example
    Index_file_name = strfind(fields1,'file_name_instance');    Index_file_name = find(not(cellfun('isempty',Index_file_name)));
    Index_elec_rate = strfind(fields1,'elec_rate_instance');    Index_elec_rate = find(not(cellfun('isempty',Index_elec_rate)));
    Index_base = strfind(fields1,'base_op_instance');           Index_base = find(not(cellfun('isempty',Index_base)));
    Index_CF = strfind(fields1,'H2_consume_adj_inst');          Index_CF = find(not(cellfun('isempty',Index_CF)));
    Index_input_cap = strfind(fields1,'input_cap_instance');    Index_input_cap = find(not(cellfun('isempty',Index_input_cap)));

    for i0=1:M0    
        interim1 = relationship_matrix_final{i0,Index_elec_rate};
        Find_underscore1 = strfind(interim1,'_');
        interim1 = interim1(1:Find_underscore1-1);    

        interim2 = relationship_matrix_final{i0,Index_input_cap};
        if strcmp(interim2,'0'),     interim2='NoDevice';
        else                         interim2=['Flex',num2str(relationship_matrix_final{i0,Index_input_cap})];
        end

        interim3 = relationship_matrix_final{i0,Index_CF};
        interim3 = ['CF',num2str(round(str2num(interim3)*100,0))];

        relationship_matrix_final{i0,Index_file_name} = horzcat(interim1,'_',interim2,'_',interim3);
    end
else   
%%% Default
end


%% SECTION 7: Create batch file names for tariffs
disp(['Create batch files...'])
c2=1;   % Initialize batch file number
[M0,N0] = size(relationship_matrix_final); 
fileID = fopen([dir2,['RODeO_batch',num2str(c2),'.bat']],'wt');

% Create GAMS run command and write to text file
for i0=1:M0
GAMS_batch_init = ['"',GAMS_loc,'" "',GAMS_file,'" ',GAMS_lic];
    for i1=1:N0
        GAMS_batch{i1,1} = horzcat([' --',fields1{i1},'="',relationship_matrix_final{i0,i1},'"']);        
    end
    fprintf(fileID,'%s\n\n',[[GAMS_batch_init{:}],[GAMS_batch{:}]]);
    if mod(i0,ceil(M0/files_to_create))==0
        if i0==M0
        else
            %%% Create new file and copy contents
            fclose(fileID);
            c2=c2+1;
            if exist(horzcat(indir,num2str(c2)))>0            
            else
                if size(dir(indir),1)>1000
                    disp(['Folder to copy has many files'])
                    prompt1 = 'Would you like to continue (Y/N)? ';
                    promptA = input(prompt1,'s');
                    if (strcmp(promptA,'Y') || strcmp(promptA,'y')) 
                         copyfile(indir,horzcat(indir,num2str(c2)))
                    else
                        error('Folder''s not copied. Exiting program.')
                    end
                else
                    copyfile(indir,horzcat(indir,num2str(c2)))            
                end                
            end
            
            Index_indir = strfind(fields1,'indir');     Index_indir = find(not(cellfun('isempty',Index_indir)));    % Find index of 'indir'
            for i1=1:M0
                relationship_matrix_final(i1,Index_indir) = {horzcat(relationship_matrix_final{i1,Index_indir},num2str(c2))};
            end            
            fileID = fopen([dir2,['RODeO_batch',num2str(c2),'.bat']],'wt');
        end
    end 
    if mod(i0,100)==0
        disp(['  File ',num2str(c2),' : ',num2str(i0),' of ',num2str(M0)]);   % Display progress    
    end    
end
fclose(fileID);
disp([num2str(c2),' batch file(s) for ',num2str(M0),' runs (~',num2str(ceil(M0/files_to_create)),' each)']);


%% Function file
% function Batch_header = load_relation_file(load_files1,indir,Batch_header)
%         for i0=1:length(load_files1)
%             [~,~,raw1] = xlsread([indir,'\',load_files1{i0}]);      % Load file(s) 
%             header1 = raw1(1,:);                                    % Pull out header file
%             raw1 = raw1(2:end,:);                                   % Remove first row
%             raw1 = cellfun(@num2str,raw1,'UniformOutput',false);    % Convert any numbers to strings
%             [M0,~] = size(raw1);                                    % Find size
% 
%             V1 = length(Batch_header.(header1{1}).val);
%             V2 = length(Batch_header.(header1{2}).val);    
% 
%             %%% Check to make sure all values are defined to avoid inadvertantly deleting scenarios
%             V1_int = unique(raw1(:,1));         % Find length of unique non-'NaN' array
%             V1_int(strcmp(V1_int,'NaN')) = [];            
%             V1_check = length(V1_int);
%             
%             V2_int = unique(raw1(:,2));         % Find length of unique non-'NaN' array
%             V2_int(strcmp(V2_int,'NaN')) = [];            
%             V2_check = length(V2_int);
%             
%             % Warnings below do not necessarily mean an error. Ignore if this is intentional (e.g., have more electricity rate files than are used)
%             % V1_check or V2_check can be larger than V1 or V2
%             if (V1_check~=V1)
%                warning([header1{1},' from ',load_files1{i0},'.xlsx has fewer values than initially defined (',num2str(V1_check),' out of ',num2str(V1),')']);
%             end
%             if (V2_check~=V2)
%                warning([header1{2},' from ',load_files1{i0},'.xlsx has fewer values than initially defined (',num2str(V2_check),' out of ',num2str(V2),')']);
%             end
%           
%             Col1 = zeros(M0,1); % Initialize
%             for i1=1:V1         % Convert text to values based on order from Batch_header
%                 Col1(strcmp(raw1(:,1),Batch_header.(header1{1}).val{i1}))=i1;
%             end
%             Col2 = zeros(M0,1); % Initialize
%             for i2=1:V2         % Convert text to values based on order from Batch_header
%                 Col2(strcmp(raw1(:,2),Batch_header.(header1{2}).val{i2}))=i2;
%             end
% 
%             Batch_header.(header1{1}).(header1{2}) = [Col1,Col2];   % Include field relationship
%             Batch_header.(header1{2}).(header1{1}) = [Col2,Col1];   % Include reciprocal field relationship
%          disp(['  ',load_files1{i0},'.xlsx Completed'])
%         clear header1 raw1 Int1 M0 V1 V2 i1 i2 i3
%         end
% end