%% Collect, configure and output data into text files for use with GAMS
clear all, close all, clc

% dir2 = ['C:\Users\jeichman\Documents\gamsdir\projdir\RODeO\data_files\Wind_farm_plus_storage_UK_Prices\'];
% dir2 = ['C:\Users\jeichman\Documents\gamsdir\projdir\RODeO\data_files\Wind_farm_plus_storage\'];
% dir2 = ['C:\Users\jeichman\Documents\gamsdir\projdir\RODeO\data_files\Redispatch_hourly\'];
%dir2 = ['C:\Users\jeichman\Documents\gamsdir\projdir\RODeO\data_files\Central_vs_distributed\Output\'];
dir2 = ['C:\Users\jeichman\Documents\gamsdir\projdir\RODeO\data_files\Example\Output\'];

dir1 = [dir2,'CSV_data\'];      % Input folder
[status1,msg1] = mkdir(dir1);   % Create directory if it doesn't exist
dir0 = [dir2,'TXT_files\'];     % Output folder
[status0,msg0] = mkdir(dir0);   % Create directory if it doesn't exist
cd(dir1);

% dir0 = ['C:\Users\jeichman\Documents\Tariff_analysis\Output\TXT_files\Generic_file\'];    % Output folder
% dir1 = ['C:\Users\jeichman\Documents\Tariff_analysis\Output\CSV_data\Generic_file\'];     % Input folder
% cd(dir1);

% Prompt for which files to output
write_regular_files = 'yes'; %input('Write regular tariff files? (yes or no)... ','s');             % Prompt about which files to write to text
Year_select = 2018;     % select year to be analyzed
Year_length = ceil((datenum(Year_select,12,31,23,59,59)-datenum(Year_select,1,1,0,0,0))*24);   %8784;     % length of year in hours
interval_length = 1;    % used to create sub-hourly data files (1, 4, or 12)
% DST_year_beg = datenum([2015,3,8,2,0,0]);   %Daylight savings time
% DST_year_end = datenum([2015,11,1,2,0,0]);  %Daylight savings time
month_vec = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};

disp('Loading Files...')
% Electricity price data (input any number of regions/nodes)
[num1int] = xlsread('e_tou_8760.csv');                      % ($/kWh)
num1int = num1int(2:end,:);                                 % Remove first row which contains the scenario number
[num1A] = xlsread('e_prices.csv');                          % ($/kWh)
num1A = num1A(2:end,:);                                     % Remove first row which contains the scenario number
[m0,n0] = size(num1int); [m00,n00] = size(num1A);
num1int2 = zeros(size(num1int));
for i1=1:n0     % Convert integer values to price values from URDB 
    for i2=1:m00, num1int2(num1int(:,i1)==i2-1,i1)=num1A(i2,i1); end
    if mod(i1,1000)==0, display([num2str(i1),' of ',num2str(n0)]), end  % Display progress each 1000 intervals
end
num1 = interpolate_matrix(num1int2,Year_length,interval_length,2);

[num1Bint,txt1B,raw1B] = xlsread('GAMS_Energy_Sale');          % ($/kWh)
num1B = interpolate_matrix(num1Bint,Year_length,interval_length,2);
clear num1int num1int2 num1Bint

% Reserve price data (input a set of AS prices (NS, RD, RU, SP (in that order)))
[num2int2,txt2,raw2] = xlsread('GAMS_AS');                  % ($/MWh)
num2int2(:,1)=[];   % Remove first column of AS values
num2 = interpolate_matrix(num2int2,Year_length,interval_length,2); 
clear num2int2

% Fuel price data (input the fuel price and select the desired region from the inputted data)
[num3int,txt3,raw3] = xlsread('GAMS_FUEL');                 % ($/MMBTU)  
num3 = interpolate_matrix(num3int,Year_length,interval_length,2);  
clear num3int

% Normalized Reneawble data (input the normalized hourly renewable profile (one column for each region/node))
[num4Aint,txt4A,raw4A] = xlsread('GAMS_renewable_PV');      % (normalized)
 num4Aint(:,1)=[];   % Remove first column of AS values
 num4A = interpolate_matrix(num4Aint,Year_length,interval_length,1);
[num4Bint,txt4B,raw4B] = xlsread('GAMS_renewable_WIND');    % (normalized)
 num4Bint(:,1)=[];   % Remove first column of AS values
 num4B = interpolate_matrix(num4Bint,Year_length,interval_length,1);
[num4Cint,txt4C,raw4C] = xlsread('GAMS_renewable_33curt');  % (normalized)
 num4Cint(:,1)=[];   % Remove first column of AS values
 num4C = interpolate_matrix(num4Cint,Year_length,interval_length,1);
[num4Dint,txt4D,raw4D] = xlsread('GAMS_renewable_40curt');  % (normalized)
 num4Dint(:,1)=[];   % Remove first column of AS values
 num4D = interpolate_matrix(num4Dint,Year_length,interval_length,1);
clear num4Aint num4Bint num4Cint num4Dint

% Fixed demand charge data (input the fixed demand charge price (one column for each region/node))
[num5] = xlsread('d_flat_prices.csv');                      % ($/kW)
num5 = num5(2:end,:);                                       % Remove first row which contains the scenario number

% Timed demand charge data (input the timed demand charge price (one column for each region/node))
[num6int] = xlsread('d_tou_8760.csv');
num6int = num6int(2:end,:);                                 % Remove first row which contains the scenario number
[num6A] = xlsread('d_tou_prices.csv');
num6A = num6A(2:end,:);                                     % Remove first row which contains the scenario number
[m01,n01] = size(num6int);
[m02,n02] = size(num6A);
num6int2 = zeros(size(num6int));
for i1=1:n01     % Convert integer values to price values from URDB 
    for i2=1:m02, num6int2(num6int(:,i1)==i2-1,i1)=num6A(i2,i1); end
    if mod(i1,1000)==0, display([num2str(i1),' of ',num2str(n01)]), end  % Display progress each 1000 intervals
end
num6 = interpolate_matrix(num6int2,Year_length,interval_length,2);
num6B= interpolate_matrix(num6int,Year_length,interval_length,2);
clear num6int num6int2

% % % TOU tariff breakdown (input the TOU buckets for each region (one column for each region/node) (1=peak, 2=mid-peak, 3=off-peak))
% % [num7,txt7,raw7] = xlsread('GAMS_TOU_bucket');        % (N/A)

% Meter cost (cost per month for SCE and SDGE and cost per day for PGE)
[num8] = xlsread('fixed_charge.csv');                       % ($/month/meter)
num8 = num8(2:end,:);                                       % Remove first row which contains the scenario number

% % % Load file describing the nodal data to be analyzed
% % [num9,txt9,raw9] = xlsread('GAMS_nodes_caliso_v4_data');

% Load tariff file names
[numA,txtA,rawA] = xlsread('tariff_property_list.csv');   

%% Clean number matrix
disp('Clean and prepare matrices...')
num11 = num1;
num11(:,find(isnan(sum(num1)))) = [];  % Remove incomplete energy price nodes
num11(isnan(num11)) = 0;    % Remove NaN values
num11B = num1B;
num11B(:,find(isnan(sum(num1B)))) = [];  % Remove incomplete energy price nodes
num11B(isnan(num11B)) = 0;    % Remove NaN values

num21 = num2;  num21(isnan(num21)) = 0;    % Remove NaN values
num31 = num3;  num31(isnan(num31)) = 0;    % Remove NaN values
num41A= num4A; num41A(isnan(num41A)) = 0;  % Remove NaN values
num41B= num4B; num41B(isnan(num41B)) = 0;  % Remove NaN values
num41C= num4C; num41C(isnan(num41C)) = 0;  % Remove NaN values
num41D= num4D; num41D(isnan(num41D)) = 0;  % Remove NaN values
num51 = num5;  num51(isnan(num51)) = 0;    % Remove NaN values
num61 = num6;  num61(isnan(num61)) = 0;    % Remove NaN values
% % num71 = num7; num71(isnan(num71)) = 0;    % Remove NaN values
num81 = num8;  num81(isnan(num81)) = 0;    % Remove NaN values


%% Clean and prepare text
% Remove incomplete energy price node names
txt11 = rawA(2:(n0+1),2);       % URDB Tariff_id column
txt12 = rawA(2:(n0+1),6);       % Utility column
txt11(:,find(isnan(sum(num1)))) = [];  
txt12(:,find(isnan(sum(num1)))) = [];  
Scenarios1 = txt11(~cellfun('isempty',txt11));
Category1 = unique(txt12);  % List of utilities

clear num1 num1B num2 num3 num4A num4B num4C num4D num5 num6 num8


%% Create filenames for each txt file to be created
disp('Create filenames...')
filenames = [char(reshape(repmat(strrep(Scenarios1,' ','_')',1,1)',[],1)),...             
             repmat('.txt',length(Scenarios1),1)];
         
% Adjust text as necessary and put into cell array
for i4 = 1:length(Scenarios1)
    interim1 = strrep(filenames(i4,:),' ','');
    filename2(i4,:) = {strrep(interim1,'%','')};
end, clear interim1

% Create name values for utility rates for use in Excel and GAMS
for i5=1:length(filename2)
    interim2 = strrep(filename2(i5),'.txt','');
    filename3(i5,1) = {[char(interim2)]};
%     filename3(i5,1) = {[char(interim2),'_Eonly']};
%     filename3(i5+length(filename2),1) = {[char(interim2),'_All']};
end, clear interim2

%% Find Utilities
util2 = zeros(length(filename2),1);     % Create empty matrix for utility values
for i0=1:length(filename2)
    for i1=1:length(Category1)        
        if strcmp(txt12{i0},Category1{i1})==1
            util2(i0,1) = i1;
            break
        end
    end
    if mod(i0,1000)==0, display([num2str(i0),' of ',num2str(length(filename2))]), end  % Display progress each 1000 intervals
end, clear i0 i1

%% Create season values
disp('Create season values...')
date_values = (datenum(Year_select,1,1,0,0,0):(1/24/interval_length):datenum(Year_select,12,31,23,59,59))';
interval1 = (1:length(date_values))';
for i5=1:length(interval1)
    [Y1,M1,D1,H1,MN1,S1] = datevec(date_values(i5));
    month_values(i5,1) = M1;    
%     hour_values(i5,1) = H1+1;
end

%%% Create 4D matrix to separate hours for each month, TOU bin and utility        
display('Separate timed demand charge values...')
TOU_season = [];   % Initialize
c_TOU=zeros(12,10,length(Scenarios1));  % Create matrix with the ability to handle 10 unique demand charge prices
for i4=1:length(Scenarios1)
    for i5=1:length(interval1)
        TOU_interim = num6B(i5,i4)+1;  %Add 1 to adjust for 0 indexing in python
        c_TOU(month_values(i5),TOU_interim,i4)=c_TOU(month_values(i5),TOU_interim,i4)+1;
        TOU_season(c_TOU(month_values(i5),TOU_interim,i4),month_values(i5),TOU_interim,i4) = i5;   
    end
    if mod(i4,1000)==0, display([num2str(i4),' of ',num2str(length(Scenarios1))]), end  % Display progress each 1000 intervals
end, clear c_TOU TOU_interim i4 i5
Num_demand_tranches = 6;

[mm1,nn1,oo1,pp1] = size(TOU_season);  % hours, month, TOU bin, utility
if oo1>Num_demand_tranches  % Ensure that there are at least 6 entries in case we look at demand structures with more items in the future
    TOU_season(:,:,oo1+1:Num_demand_tranches,:)=0;
    error('Need to increase the number of demand charge tranches in Matlab script and in GAMS code')     
elseif oo1<Num_demand_tranches
    TOU_season(:,:,oo1+1:Num_demand_tranches,:)=0;
end
[mm1,nn1,oo1,pp1] = size(TOU_season);  % hours, month, TOU bin, utility

GAMS_string1 = {};  % Initialize
for i5=1:nn1                % month
    for i6=1:oo1            % TOU bin
        for i7=1:pp1        % Utility
% %             if mod(i7,1000)==0, disp(['    Utility ',num2str(i7)]); end
            col1 = TOU_season(:,i5,i6,i7); 
            col1(find(col1==0))=[]; 
            i4=1;
            if isempty(col1)    % Check if entry is empty and skip
                GAMS_string1(1,i5,i6,i7)={'//'}; continue
            end
            while i4<=length(col1)  % Hours
                % Create string for breakdown by TOU bins, months and utilities in GAMS                
                if isempty(col1)    % Check if entry is empty and skip
                    break
                end
                interim1=col1(i4); interim2=1; c2=0;                
                if i4==1
                    GAMS_string1(1,i5,i6,i7)={'/'};   % Begin entry
                end
                GAMS_string1(1,i5,i6,i7)={[GAMS_string1{1,i5,i6,i7},num2str(interim1),'*']}; % Add first item to current entry
                while interim2==1   % Loop and find the number of continuous items
                    if i4==length(col1)
                        c2=1; break
                    end
                    i4=i4+1; interim2=col1(i4)-col1(i4-1);
                end
                if c2==1, GAMS_string1(1,i5,i6,i7)={[GAMS_string1{1,i5,i6,i7},num2str(col1(i4)),'/']}; break % Final entry
                else      GAMS_string1(1,i5,i6,i7)={[GAMS_string1{1,i5,i6,i7},num2str(col1(i4-1)),',']};     % Make interim entry an continue looping
                end
            end
        end
        disp(['  TOU bin ',num2str(i6)]);
    end
    disp(['Month ',num2str(i5)]);
end
GAMS_string2 = reshape(GAMS_string1,12,oo1,[]);
clear i4 i5 i6 i7 Y1 M1 D1 H1 MN1 S1 c1 c2 interim1 interim2 col1

%%% Create monthly time vector
GAMS_stringA = cell(12,length(Scenarios1));  % Initialize
date_vector1 = datevec(date_values(:));
for i6=1:length(Scenarios1)
    for i5=1:12
        col1 = find(date_vector1(:,2)==i5);
        i4=1;
        
%         if (sum(num51(:,i6))+sum(num6A(:,i6)) == 0),  % Used to remove fixed demand intervals if there is no timed or fixed demand charge (encourages smooth operation profiles) 
%             if i5==1, col1 = (1:Year_length)';
%             else      GAMS_stringA(i5,i6)={'//'};
%                       continue
%             end
%         else
%             col1 = find(date_vector1(:,2)==i5);
%         end

        while i4<=length(col1)  % Hours
            % Create string for breakdown by TOU bins, months and utilities in GAMS                
            if isempty(col1)    % Check if entry is empty and skip
                break
            end
            interim1=col1(i4); interim2=1; c2=0;                
            if i4==1
                GAMS_stringA(i5,i6)={'/'};   % Begin entry
            end
            GAMS_stringA(i5,i6)={[GAMS_stringA{i5,i6},num2str(interim1),'*']}; % Add first item to current entry
            while interim2==1   % Loop and find the number of continuous items
                if i4==length(col1) c2=1;  break
                end
                i4=i4+1; interim2=col1(i4)-col1(i4-1);
            end
            if c2==1, GAMS_stringA(i5,i6)={[GAMS_stringA{i5,i6},num2str(col1(i4)),'/']}; break % Final entry
            else      GAMS_stringA(i5,i6)={[GAMS_stringA{i5,i6},num2str(col1(i4-1)),',']};     % Make interim entry an continue looping
            end
        end
    end
    if mod(i6,1000)==0, display([num2str(i6),' of ',num2str(length(Scenarios1))]), end  % Display progress each 1000 intervals
end, clear i4 i5 i6 col1 intermi1 intermi2

%% Populate each data row with basic information and utility data
disp('Populate data rows...')
Inputs1 = {'elec_purchase_price(interval)','elec_sale_price(interval)',...
           'nonspinres_price(interval)','regdn_price(interval)','regup_price(interval)','spinres_price(interval)',...
           'meter_mnth_chg(interval)','Fixed_dem(months)','Timed_dem(timed_dem_period)'};    
Inputs2 = {'NG_price(interval)','H2_consumed(interval)','H2_price(interval)','input_power_baseload(interval)'};
Inputs3 = {'renewable_signal(interval)'};
    
% Energy price: Utility tariffs (OASIS data added later)                   ($/MWh) 
    data11 = reshape(num11,[],1,length(Scenarios1))*1000;                       % Separate energy purchase price data by number of scenarios and categories
    data11B = zeros(size(data11)); %%% reshape(num11B,[],1,length(Scenarios1))*1000; % Separate energy sale price data by number of scenarios and categories
    % % data11B= data11;    % Repeat for sale price

% AS Data: NS,RegD,RegU,Spin                                               ($/MWh)
    data22 = zeros(size(data11,1),4,size(data11,3));  %%% data2; 

% Data: PRC_FUEL (drawn from CAISO OASIS)
%       H2 consumed (0.04166666666667 normalized per hour),                
%       H2_Price (set to 1, is scaled in GAMS), 
%       input_power_base (set to 1, scaled in GAMS)
%     [data_H2_consumption] = xlsread('hydrogen_demand_profile_central.csv');             % (kg/hour)
%     [data_H2_consumption] = xlsread('hydrogen_demand_profile_distributed.csv');         % (kg/hour)
    [data_H2_consumption] = ones(24,2)*0.04166666666667;                                % (kg/hour)
    data_H2_consumption_vals = data_H2_consumption(:,2)/sum(data_H2_consumption(:,2));  % Normalize production
    data_other = [zeros(Year_length*interval_length,1),...
                  repmat(data_H2_consumption_vals,Year_length/24,1),...       % ones(Year_length*interval_length,1)*0.04166666666667,...
                  ones(Year_length*interval_length,1),...
                  ones(Year_length*interval_length,1)];
% % % data_other = repmat(data_other,1,1,length(Scenarios1));
                  
% Data: Renewable signal (normalized to max of 1)
%       Facility demand charge
%       Timed demand charge
%       TOU bucket
%       Meter Monthly charge
data44A = num41A;      %%% reshape(num41A,[],1,length(Scenarios1));                       % (N/A) Renewable signal PV
data44B = num41B;      %%% reshape(num41B,[],1,length(Scenarios1));                       % (N/A) Renewable signal WIND
% % % data44C = repmat(num41C,1,1,length(Scenarios1));      %%% reshape(num41C,[],1,length(Scenarios1));                       % (N/A) Renewable signal 33curt
% % % data44D = repmat(num41D,1,1,length(Scenarios1));      %%% reshape(num41D,[],1,length(Scenarios1));                       % (N/A) Renewable signal 40curt
data55 = reshape(num51,[],1,length(Scenarios1))*1000;                    % ($/MW-month)
data66 = reshape(num6A(1:Num_demand_tranches,:),Num_demand_tranches,1,length(Scenarios1))*1000;   % ($/MW-month) 
% % % data77 = reshape(num71,[],1,length(Scenarios1));                         % (N/A) TOU
data88 = reshape(num81,[],1,length(Scenarios1));                         % ($/month/meter)
% % % data_most_PV = [data11,data11B,data22,data33,data_other,data44A];      % Combine energy price, AS price and other components listed in 'Inputs1'
% % % data_most_WND = [data11,data11B,data22,data33,data_other,data44B];     % Combine energy price, AS price and other components listed in 'Inputs1'
% % % data_most_33curt = [data11,data11B,data22,data33,data_other,data44C];  % Combine energy price, AS price and other components listed in 'Inputs1'
% % % data_most_40curt = [data11,data11B,data22,data33,data_other,data44D];  % Combine energy price, AS price and other components listed in 'Inputs1'


%% Write regular tariff text files
tic;
if strcmp(write_regular_files,'yes')
    [m1 n1 o1] = size(GAMS_string2);
    % Add additional text to specify the resolution of the file being used
    if     interval_length == 1;  add_txt1 = ['_hourly'];
    elseif interval_length == 4;  add_txt1 = ['_15min'];
    elseif interval_length == 12; add_txt1 = ['_5min'];
    else                          error('Need to define interval length')
    end
    init_val = 1;  % Used to adjust initial for loop value and for progress tracking
    for i5=init_val:length(Scenarios1)
        filename2_short = filename2{i5};        
        fileID = fopen([dir0,char(filename2_short(1:end-4)),add_txt1,'.txt'],'wt');
        data_most2 = [data11,data11B,data22];    % Combine energy price, AS price and other components listed in 'Inputs1'
        % data_most2(:,3:6,:) = 0;                        % AS     Remove AS prices
        % data_most2(:,[3,6],:) = 0;                      % REG    Remove SP NS prices
        % data_most2(:,[4:6],:) = 0;                      % NS     Remove SP Reg prices
        % data_most2(:,[4,5],:) = 0;                      % SP NS  Remove Reg prices
        
        % Add demand charge times
        fprintf(fileID,'%s\n','$onempty');
        fprintf(fileID,'%s\n','Set');
        for i6=1:m1
            fprintf(fileID,'\t%s\t%s\t%s\n',['Month_',month_vec{i6},'(interval)'],'hours',GAMS_stringA{i6,i5});
        end
        fprintf(fileID,'\n');
        for i6=1:m1
            for i66=1:n1
            fprintf(fileID,'\t%s\t%s\t%s\n',[month_vec{i6},'_',num2str(i66),'(interval)'],'hours',GAMS_string2{i6,i66,i5});
            end
        end                
        % Add yearly inputs
        yearly_inputs = length(Inputs1)-3;
        for i7=1:yearly_inputs
            fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
            for i8=1:Year_length*interval_length
                if i8==Year_length*interval_length, fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2(i8,i7,i5),'/;');
                else                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2(i8,i7,i5),'');
                end
            end
        end
        % Add meter charge
        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{yearly_inputs+1},'/');
        fprintf(fileID,'%i\t%g\t%s\n',1,data88(1,1,i5),'/;');
        % Add fixed demand inputs
        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{yearly_inputs+2},'/');
        for i8=1:12
            if i8==12, fprintf(fileID,'%i\t%g\t%s\n',i8,data55(i8,1,i5),'/;');
            else       fprintf(fileID,'%i\t%g\t%s\n',i8,data55(i8,1,i5),'');
            end
        end
        % Add timed demand inputs
        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{yearly_inputs+3},'/');
        for i8=1:size(data66,1)
            if i8==size(data66,1), fprintf(fileID,'%i\t%g\t%s\n',i8,data66(i8,1,i5),'/;');
            else                   fprintf(fileID,'%i\t%g\t%s\n',i8,data66(i8,1,i5),'');
            end
        end
        fclose(fileID); 
        disp([num2str(i5),' of ',num2str(length(Scenarios1)),' - ',num2str(round(toc/abs(i5-init_val)*(length(Scenarios1)-i5)/60)),' min. remain - ',char(filename2(i5))])   
    end
    clear data_most2
    
    %%% Create file with additional parameters
    fileID = fopen([dir0,'additional_parameters',add_txt1,'.txt'],'wt');        
    for i7=1:length(Inputs2)
        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs2{i7},'/');
        for i8=1:Year_length*interval_length
            if i8==Year_length*interval_length, fprintf(fileID,'%i\t%g\t%s\n',i8,data_other(i8,i7),'/;');
            else                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_other(i8,i7),'');
            end
        end
    end
    fclose(fileID);
    
    %%% Create file with no renewable profiles
    fileID = fopen([dir0,'renewable_profiles_none',add_txt1,'.txt'],'wt');    
    fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs3{1},'/');
    for i7=1:length(Inputs3)
        for i8=1:Year_length*interval_length
            if i8==Year_length*interval_length, fprintf(fileID,'%i\t%g\t%s\n',i8,0,'/;');
            else                                fprintf(fileID,'%i\t%g\t%s\n',i8,0,'');
            end
        end
    end
    fclose(fileID);
    
    %%% Create file with renewable profiles
    fileID = fopen([dir0,'renewable_profiles_PV',add_txt1,'.txt'],'wt');    
    fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs3{1},'/');
    for i7=1:length(Inputs3)
        for i8=1:Year_length*interval_length
            if i8==Year_length*interval_length, fprintf(fileID,'%i\t%g\t%s\n',i8,data44A(i8,i7),'/;');
            else                                fprintf(fileID,'%i\t%g\t%s\n',i8,data44A(i8,i7),'');
            end
        end
    end
    fclose(fileID);
    
    fileID = fopen([dir0,'renewable_profiles_WIND',add_txt1,'.txt'],'wt');    
    fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs3{1},'/');
    for i7=1:length(Inputs3)
        for i8=1:Year_length*interval_length
            if i8==Year_length*interval_length, fprintf(fileID,'%i\t%g\t%s\n',i8,data44B(i8,i7),'/;');
            else                                fprintf(fileID,'%i\t%g\t%s\n',i8,data44B(i8,i7),'');
            end
        end
    end
    fclose(fileID);
end


%% Put node data into text strings
if 1==0

    c6=0;               % Initialize value
    missing_items = []; % Initialize value
    data_DA_vec = zeros(Year_length,length(files2load2));
    data_RT_vec = zeros(Year_length,length(files2load2));
    missing_hours = []; % Initialize vector to keep track of the occurence of missing hours
    for i4 = file_ind'
        c6 = c6+1;
        if strcmp(file_data(i4,2),'Generator') % Break out of loop if item is for generator
            continue
        end
        if i4 == file_ind(1)
            fileID = fopen([node_csv_loc,files2load2{i4}]);
            file_header1 = textscan(fileID,'%s %s %s %s %s %s %s %*[^\n] %*[^\n]',1,'Delimiter',',');
            fclose(fileID);
        end

        fileID = fopen([node_csv_loc,files2load2{i4}]);
        TEXT1 = textscan(fileID,'%s %s %s %s %{M/dd/yyyy HH:mm}D %{M/dd/yyyy HH:mm}D %{M/dd/yyyy HH:mm}D %*[^\n] %*[^\n]','HeaderLines',1,'Delimiter',','); % %{M/dd/yyyy HH:mm}D
        fclose(fileID);

        TEXT2 = TEXT1;
        Row1 = horzcat(TEXT2{:,1}); 
        Row2 = horzcat(TEXT2{:,2}); 
        Row3 = horzcat(TEXT2{:,3}); 
        Row4 = horzcat(TEXT2{:,4}); 
        Row5 = horzcat(TEXT2{:,5}); 
        Row6 = horzcat(TEXT2{:,6}); 
        Row7 = horzcat(TEXT2{:,7}); 

    %     Sort by DA/RT
        [Sorted_1, Index_1] = sort(Row3);
        Row5_1 = Row5(Index_1,:);   % Sort by DA-RT
        for i0=1:length(Row5_1)     % Find DA-RT break point
            DA_RT_break = strcmp(Sorted_1(i0),'RT5AVG');
            if(DA_RT_break>0)
                DA_RT_break = i0;
                break
            end
        end
        Row5_DA = Row5_1(1:DA_RT_break-1,:); % Separate DAH and RT5AVG
        Row5_RT = Row5_1(DA_RT_break:end,:); % Separate DAH and RT5AVG
        Row7_1 = Row7(Index_1,:);   % Sort by DA-RT
        Row7_DA = Row7_1(1:DA_RT_break-1,:); % Separate DAH and RT5AVG
        Row7_RT = Row7_1(DA_RT_break:end,:); % Separate DAH and RT5AVG
        Row4_1 = Row4(Index_1,:);   % Sort by DA-RT
        Row4_DA = Row4_1(1:DA_RT_break-1,:); % Separate DAH and RT5AVG
        Row4_RT = Row4_1(DA_RT_break:end,:); % Separate DAH and RT5AVG
    %     Sort by datenum 6 
        [Sorted_2_1, Index_2_1] = sort(Row5_DA);
        [Sorted_2_2, Index_2_2] = sort(Row5_RT);
        Row7_DA_2 = Row7_DA(Index_2_1,:);   % Sort by BegHr
        Row7_RT_2 = Row7_RT(Index_2_2,:);   % Sort by BegHr
        Row4_DA_2 = Row4_DA(Index_2_1,:);   % Sort by BegHr
        Row4_RT_2 = Row4_RT(Index_2_2,:);   % Sort by BegHr
    %     Sort by datenum 8
        [Sorted_3_1, Index_3_1] = sort(Row7_DA_2);
        [Sorted_3_2, Index_3_2] = sort(Row7_RT_2);
        Row7_DA_3 = Row7_DA_2(Index_3_1,:);   % Sort by BegHr
        Row7_RT_3 = Row7_RT_2(Index_3_2,:);   % Sort by BegHr
        Row4_DA_3 = Row4_DA_2(Index_3_1,:);   % Sort by BegHr
        Row4_RT_3 = Row4_RT_2(Index_3_2,:);   % Sort by BegHr
        Row7_DA_3_num = round((datenum(Row7_DA_3)-datenum(Year_select,1,1))*24+1,1);
        Row7_RT_3_num = round((datenum(Row7_RT_3)-datenum(Year_select,1,1))*24+1,1);
        Row7_DA_4_num = Row7_DA_3_num;  % Initialize vector to account for DST
        for i1=1:length(Row7_DA_3_num)  % Account for DST changes in interval number
            if Row7_DA_4_num(i1)>=round((DST_year_beg-datenum(Year_select,1,1))*24+1,1)
                Row7_DA_4_num(i1)=Row7_DA_4_num(i1)-1;
                if Row7_DA_4_num(i1)+1==round((DST_year_end-datenum(Year_select,1,1))*24,1)  % Kick out of loop after DST_year_end
                    break
                end
            end
        end

        Row7_RT_4_num = Row7_RT_3_num;  % Initialize vector to account for DST 
        for i1=1:length(Row7_RT_3_num)  % Account for DST changes in interval number
            if Row7_RT_4_num(i1)>=round((DST_year_beg-datenum(Year_select,1,1))*24+1,1)
                Row7_RT_4_num(i1)=Row7_RT_4_num(i1)-1;
                if Row7_RT_4_num(i1)+1==round((DST_year_end-datenum(Year_select,1,1))*24,1)  % Kick out of loop after DST_year_end
                    break
                end
            end
        end
        data_DA = [];
        for i2=1:length(Row4_DA_3)
            data_DA(i2,:) = [str2num(Row4_DA_3{i2,1}),Row7_DA_4_num(i2)];
        end
        data_RT = [];
        for i2=1:length(Row4_RT_3)
            data_RT(i2,:) = [str2num(Row4_RT_3{i2,1}),Row7_RT_4_num(i2)];
        end

    %     Remove hours outside of 2015
        data_DA([find(data_DA(:,2)<=0);find(data_DA(:,2)>Year_length)],:)=[];
        data_RT([find(data_RT(:,2)<=0);find(data_RT(:,2)>Year_length)],:)=[];

    %     Add missing hours
        missing_items(:,c6) = ([Year_length-length(data_DA),Year_length-length(data_RT)]);    
        c7 = 0;     % Initialize
        c8 = 0;     % Initialize
        for i3=1:Year_length
            if i3>length(data_DA), data_DA = [data_DA(1:i3-1,:);[data_DA(i3-1,1),i3]]; c7=c7+1; missing_hours(c7,c6,1)=i3; end  % Add item to end if array is less than Year_length
            if i3>length(data_RT), data_RT = [data_RT(1:i3-1,:);[data_RT(i3-1,1),i3]]; c8=c8+1; missing_hours(c8,c6,2)=i3; end  % Add item to end if array is less than Year_length
            if data_DA(i3,2)~=i3
                if i3==1, data_DA = [[data_DA(i3+1,1),i3];data_DA(i3:end,:)]; 
                          c7=c7+1; missing_hours(c7,c6,1)=i3;
                else      data_DA = [data_DA(1:i3-1,:);[(data_DA(i3-1,1)+data_DA(i3,1))/2,i3];data_DA(i3:end,:)];
                          c7=c7+1; missing_hours(c7,c6,1)=i3;
                end
            end
            if data_RT(i3,2)~=i3
                if i3==1, data_RT = [[data_RT(i3+1,1),i3];data_RT(i3:end,:)]; 
                          c8=c8+1; missing_hours(c8,c6,2)=i3;
                else      data_RT = [data_RT(1:i3-1,:);[(data_RT(i3-1,1)+data_RT(i3,1))/2,i3];data_RT(i3:end,:)];
                          c8=c8+1; missing_hours(c8,c6,2)=i3;
                end
            end
        end
        data_DA_vec(:,i4) = data_DA(:,1);
        data_RT_vec(:,i4) = data_RT(:,1);
        clear TEXT1 TEXT2 Row1 Row2 Row3 Row4 Row5 Row6 Row7 Row5_1 
        clear Sorted_1 Index_1 Sorted_2_1 Index_2_1 Sorted_2_2 Index_2_2 Sorted_3_1 Index_3_1 Sorted_3_2 Index_3_2 
        clear DA_RT_break Row5_DA Row5_RT Row7_1 Row7_DA Row7_RT Row7_DA_1 Row7_RT_1 Row4_1 Row4_DA Row4_RT Row7_DA_2 Row7_RT_2 Row4_DA_2 Row4_RT_2
        clear Row7_DA_3 Row7_RT_3 Row4_DA_3 Row4_RT_3 Row7_DA_3_num Row7_RT_3_num Row7_DA_4_num Row7_RT_4_num
        clear data_DA data_RT
        disp([num2str(c6),' of ',num2str(length(file_ind))])

        % Write direct access data to txt files in-situ
        if (strcmp(write_direct_access_files,'yes') && sum(missing_items(:,c6))<50) % makes files if there are less than 50 missing hours
            for i5=Direct_access_secondary
                filename4 = filename2{i5};
                if (find(i4==file_ind(find(util1==util2(i5))))>0)                
                    filename_csv = files2load2{i4};

                    % Make profiles (ASSUME THAT T&D charges are not recovered when selling electricity)
                    data_most2_DA_PV = data_most_PV;
                    data_most2_RT_PV = data_most_PV;
                    data_most2_DA_PV(:,1,i5) = data_most_PV(:,1,i5)+data_DA_vec(:,i4); % Purchase: Add OASIS energy data to direct access rates
                    data_most2_DA_PV(:,2,i5) = data_DA_vec(:,i4);                      % Sale:     OASIS energy data
                    data_most2_RT_PV(:,1,i5) = data_most_PV(:,1,i5)+data_RT_vec(:,i4); % Purchase: Add OASIS energy data to direct access rates
                    data_most2_RT_PV(:,2,i5) = data_RT_vec(:,i4);                      % Sale:     OASIS energy data

                    data_most2_DA_WND = data_most_WND;
                    data_most2_RT_WND = data_most_WND;
                    data_most2_DA_WND(:,1,i5) = data_most_WND(:,1,i5)+data_DA_vec(:,i4); % Purchase: Add OASIS energy data to direct access rates
                    data_most2_DA_WND(:,2,i5) = data_DA_vec(:,i4);                       % Sale:     OASIS energy data
                    data_most2_RT_WND(:,1,i5) = data_most_WND(:,1,i5)+data_RT_vec(:,i4); % Purchase: Add OASIS energy data to direct access rates
                    data_most2_RT_WND(:,2,i5) = data_RT_vec(:,i4);                       % Sale:     OASIS energy data

                    % Create Day Ahead PV files
                    fileID = fopen([dir1,'Tariff_test\',filename4(1:end-4),'__DA_',filename_csv(1:end-4),'_PV.txt'],'wt');
                    % Add yearly inputs
                    yearly_inputs = length(Inputs1)-5;
                    for i7=1:yearly_inputs
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:Year_length
                            if i8==Year_length
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_DA_PV(i8,i7,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_DA_PV(i8,i7,i5),'');
                            end
                        end
                    end
                    % Add meter charge
                    fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{yearly_inputs+1},'/');
                    fprintf(fileID,'%i\t%g\t%s\n',1,data88(1,1,i5),'/;');
                    % Add monthly inputs
                    for i7=yearly_inputs+2:length(Inputs1)
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:12
                            if i8==12
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'');
                            end
                        end
                    end
                    fclose(fileID);

                    % Create Day Ahead Wind files
                    fileID = fopen([dir1,'Tariff_test\',filename4(1:end-4),'__DA_',filename_csv(1:end-4),'_WIND.txt'],'wt');
                    % Add yearly inputs
                    yearly_inputs = length(Inputs1)-5;
                    for i7=1:yearly_inputs
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:Year_length
                            if i8==Year_length
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_DA_WND(i8,i7,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_DA_WND(i8,i7,i5),'');
                            end
                        end
                    end
                    % Add meter charge
                    fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{yearly_inputs+1},'/');
                    fprintf(fileID,'%i\t%g\t%s\n',1,data88(1,1,i5),'/;');
                    % Add monthly inputs
                    for i7=yearly_inputs+2:length(Inputs1)
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:12
                            if i8==12
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'');
                            end
                        end
                    end
                    fclose(fileID);

                    % Create Real-time PV files
                    fileID = fopen([dir1,'Tariff_test\',filename4(1:end-4),'__RT_',filename_csv(1:end-4),'_PV.txt'],'wt');
                    % Add yearly inputs
                    yearly_inputs = length(Inputs1)-5;
                    for i7=1:yearly_inputs
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:Year_length
                            if i8==Year_length
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_RT_PV(i8,i7,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_RT_PV(i8,i7,i5),'');
                            end
                        end
                    end
                    % Add meter charge
                    fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{yearly_inputs+1},'/');
                    fprintf(fileID,'%i\t%g\t%s\n',1,data88(1,1,i5),'/;');
                    % Add monthly inputs
                    for i7=yearly_inputs+2:length(Inputs1)
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:12
                            if i8==12
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'');
                            end
                        end
                    end
                    fclose(fileID);

                    % Create Real-time Wind files
                    fileID = fopen([dir1,'Tariff_test\',filename4(1:end-4),'__RT_',filename_csv(1:end-4),'_WIND.txt'],'wt');
                    % Add yearly inputs
                    yearly_inputs = length(Inputs1)-5;
                    for i7=1:yearly_inputs
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:Year_length
                            if i8==Year_length
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_RT_WND(i8,i7,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_RT_WND(i8,i7,i5),'');
                            end
                        end
                    end
                    % Add meter charge
                    fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{yearly_inputs+1},'/');
                    fprintf(fileID,'%i\t%g\t%s\n',1,data88(1,1,i5),'/;');
                    % Add monthly inputs
                    for i7=yearly_inputs+2:length(Inputs1)
                        fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
                        for i8=1:12
                            if i8==12
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'/;');
                            else
                                fprintf(fileID,'%i\t%g\t%s\n',i8,data_monthly(i8,i7-yearly_inputs-1,i5),'');
                            end
                        end
                    end
                    fclose(fileID);                
                    disp([num2str(find(file_ind==i4)),' of ',num2str(length(file_ind)),' | ',num2str(i5),' of ',num2str(max(Direct_access_indices)),' - ',filename4(1:end-4),' - ',filename_csv]); %' - Direct Access Tariffs'])   
                end
            end 
        end
    end
end

% % %% Write direct access tariff files for secondary generation voltages
% % if strcmp(write_direct_access_files,'yes')
% %     for i5=Direct_access_secondary
% %         filename4 = filename2{i5};
% %         if isempty(file_ind(find(util1==util2(i5))))
% %         else
% %             for i6 = file_ind(find(util1==util2(i5)))'
% %                 filename_csv = files2load2{i6};
% %                 data_most2_DA = data_most;
% %                 data_most2_RT = data_most;
% %                 data_most2_DA(:,1,i5) = data_most(:,1,i5)+data_DA_vec(:,i6); % Add OASIS energy data to direct access rates
% %                 data_most2_RT(:,1,i5) = data_most(:,1,i5)+data_RT_vec(:,i6); % Add OASIS energy data to direct access rates
% % 
% %                 % Create Day Ahead files
% %                 fileID = fopen([dir1,'Tariff_test\',filename4(1:end-4),'__DA_',filename_csv(1:end-4),'.txt'],'wt');
% %                 for i7=1:length(Inputs1)-1
% %                     fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
% %                     for i8=1:Year_length
% %                         if i8==Year_length, fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_DA(i8,i7,i5),'/;');
% %                         else                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_DA(i8,i7,i5),'');
% %                         end
% %                     end
% %                 end
% %                 fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{length(Inputs1)},'/');    % Add meter cost
% %                 fprintf(fileID,'%i\t%g\t%s\n',1,data88(1,1,i5),'/;');                       % Add meter cost
% %                 fclose(fileID);
% % 
% %                 % Create Real-time files
% %                 fileID = fopen([dir1,'Tariff_test\',filename4(1:end-4),'__RT_',filename_csv(1:end-4),'.txt'],'wt');
% %                 for i7=1:length(Inputs1)-1
% %                     fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{i7},'/');
% %                     for i8=1:Year_length
% %                         if i8==Year_length, fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_RT(i8,i7,i5),'/;');
% %                         else                fprintf(fileID,'%i\t%g\t%s\n',i8,data_most2_RT(i8,i7,i5),'');
% %                         end
% %                     end
% %                 end
% %                 fprintf(fileID,'%s\t%s\t%s\n','parameter',Inputs1{length(Inputs1)},'/');    % Add meter cost
% %                 fprintf(fileID,'%i\t%g\t%s\n',1,data88(1,1,i5),'/;');                       % Add meter cost
% %                 fclose(fileID);
% %                 disp([num2str(find(file_ind==i6)),' of ',num2str(length(file_ind)),' | ',num2str(i5),' of ',num2str(max(Direct_access_indices)),' - ',filename4(1:end-4),' - ',filename_csv]); %' - Direct Access Tariffs'])   
% %             end
% %         end
% %     end
% % end


%% Scratch
if 1==0 % Copies CSV files to computer (all active nodes, that are not 'Generators')
    node_csv_loc = '\\nrelgis-24141s\share\josh\csv_update\';
    node_csv_dest= 'C:\Users\jeichman\Documents\CAISO_Data\CAISO 2015 LAP Prices\CSV\';
    Skip_files = [];
    for i0=1:length(file_ind)
        % Move csv files        
        if strcmp(file_data(i0,2),'Generator') % Break out of loop if item is for generator
            Skip_files(i0,1)=1;
            continue
        end
        copyfile([node_csv_loc,files2load2{file_ind(i0)}],...
                 [node_csv_dest,files2load2{file_ind(i0)}]);
        disp([num2str(i0),' of ',num2str(length(file_ind))])
    end
end