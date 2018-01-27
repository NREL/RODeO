%%% Creates files to update the current dispatch based on Price-taker runs
%%% Instructions: populate 'List_of_generator.xlsx' with
%%%               desired file numbers, select timestep, check the 
%%%               filenames that are created in filename 1, change
%%%               increment within t3 as appropriate and run.

clear all
close all
clc

% % [num1,txt1,raw1] = xlsread('List_of_generators.xlsx');
% % [num2,txt2,raw2] = xlsread('Properties_storage_short.xlsx');
% % num1 = num2(:,end);     % Collect all the generator ID values to create files

[num3,txt3,raw3] = xlsread('Gen1.xlsx');
[num4,txt4,raw4] = xlsread('Pmp1.xlsx');

[Markets1,ia1,ic1] = unique(txt3(1,2:end));
Generator0 = num3(3,2:end);
Generator0 = Generator0(find(ic1==3));
[Generator1,ia2,ic2] = unique(num3(3,2:end));

Gen1 = num3(4:end,2:end);
Gen1 = Gen1(:,find(ic1==3));    % Use only 'RT' runs
Pmp1 = num4(4:end,2:end);
Pmp1 = Pmp1(:,find(ic1==3));    % Use only 'RT' runs

year_val = 2024;
% filename1 = {'Available Capacity','Generation','Price Received','Pump Load','Units Generating'};
filename1 = {'Generation','Pump Load'};
File_num = 2;       % Set the number of files that the year is broken down into.
                    % 1=yearly, 2=quarterly, 3=monthly
Look_ahead = 0;     % hours of look-ahead to remove from files
                
if File_num==1,
    %%% Yearly
    t1 = datetime(year_val,1,1,0,0,0);                      %,'Format','d/M/yyyy, h:mm a');
    t2 = datetime(year_val+1,1,1,0,0,0);                    %,'Format','d/M/yyyy, h:mm a');
    t3 = (t1:hours(1):t2)'; t3(end-Look_ahead:end)=[];      % Create hourly matrix and remove the last hour
    file_identifier = 'Year';
elseif File_num==2,
    %%% Quarterly
    clear t3
    for i1=1:4
        i2 = [((i1-1)*3+1),i1*3+1];
        t1 = datetime(year_val,i2(1),1,0,0,0);              %,'Format','d/M/yyyy, h:mm a');
        if i1==4, t2 = datetime(year_val+1,1,1,0,0,0);      %,'Format','d/M/yyyy, h:mm a');
        else      t2 = datetime(year_val,i2(2),1,0,0,0);    %,'Format','d/M/yyyy, h:mm a');
        end
        Quarter_length = (datenum(t2)-datenum(t1))*24;
        t3_interim = (t1:hours(1):t2)'; t3_interim(end-Look_ahead:end)=[];	% Create hourly matrix and remove the last row
        t3(1:Quarter_length-Look_ahead,i1) = t3_interim;
    end
    file_identifier = 'Q';
elseif File_num==3,
    %%% Monthly
    clear t3
    for i1=1:12    
        t1 = datetime(year_val,i1,1,0,0,0);                 %,'Format','d/M/yyyy, h:mm a');
        if i1==12, t2 = datetime(year_val+1,1,1,0,0,0);     %,'Format','d/M/yyyy, h:mm a');
        else       t2 = datetime(year_val,i1+1,1,0,0,0);    %,'Format','d/M/yyyy, h:mm a');
        end
        Month_length = (datenum(t2)-datenum(t1))*24;
        t3_interim = (t1:hours(1):t2)'; t3_interim(end-Look_ahead:end)=[];	% Create hourly matrix and remove the last row
        t3(1:Month_length-Look_ahead,i1) = t3_interim;
    end    
    file_identifier = 'M';
end

[M1,N1] = size(t3);
t3_times = ~isnat(t3);
[M2,N2] = size(Gen1);
c0 = 0;
Gen2 = cell(M1,N1,N2);
Pmp2 = cell(M1,N1,N2);
for i2=1:N1
    for i1=1:M1
        if t3_times(i1,i2)==0, continue, end
        c0=c0+1;   % Iterate value
%         t4(i1,i2) = {[datestr(t3(i1,i2),'mm/dd/yyyy HH:MM AM'),', 0']};
        for i3=1:N2            
            Gen2(i1,i2,i3) = {[datestr(t3(i1,i2),'mm/dd/yyyy HH:MM AM'),', ',num2str(Gen1(c0,i3))]};
            Pmp2(i1,i2,i3) = {[datestr(t3(i1,i2),'mm/dd/yyyy HH:MM AM'),', ',num2str(Pmp1(c0,i3))]};
        end
        disp([num2str(i2),' of ',num2str(N1),' - ',num2str(i1),' of ',num2str(M1)])    
    end
end


for i1=1:length(filename1)
    for i2=1:length(Generator0)       
        for i3=1:N1    
            % Previously used to isolate 'RT'      ',Markets1{ic1(i2)},'
            [status, msg, msgID] = mkdir(['RT_dispatch\RT\',file_identifier,num2str(i3)]);
            fileID = fopen([pwd,'\RT_dispatch\RT\',file_identifier,num2str(i3),'\ST Generator(',num2str(Generator0(i2)),').',filename1{i1},'.csv'],'wt');
            fprintf(fileID,'%s\n','DATETIME, VALUE');
            if strcmp(filename1{i1},'Generation')
                fprintf(fileID,'%s\n',Gen2{:,i3,i2});
            elseif strcmp(filename1{i1},'Pump Load')
                fprintf(fileID,'%s\n',Pmp2{:,i3,i2});
            else
                error(['No data to load for ''',filename1(i1),''' file type'])
            end
            %                     fprintf(fileID,'%s\n',t4{:,i3});
            fclose(fileID);
        end
        disp([num2str(i1),' of ',num2str(length(filename1)),'  -  ',num2str(i2),' of ',num2str(length(Generator0))])    
    end
end