%% GAMS_batch_func
%  Takes a file that relates two fields and turns it into a constraint that can be read by the script

function Batch_header = load_relation_file(load_files1,indir,Batch_header)
        for i0=1:length(load_files1)
            [~,~,raw1] = xlsread([indir,'\',load_files1{i0}]);      % Load file(s) 
            header1 = raw1(1,:);                                    % Pull out header file
            raw1 = raw1(2:end,:);                                   % Remove first row
            raw1 = cellfun(@num2str,raw1,'UniformOutput',false);    % Convert any numbers to strings
            [M0,~] = size(raw1);                                    % Find size

            V1 = length(Batch_header.(header1{1}).val);
            V2 = length(Batch_header.(header1{2}).val);    
            Int1 = zeros(V1,V2);                                    % Initialize matrix
            for i1=1:V1
                for i2=1:V2
                    for i3=1:M0
                        eval(sprintf('if (strcmp(Batch_header.%s.val{%d},raw1{%d,1}) && strcmp(Batch_header.%s.val{%d},raw1{%d,2}) ), Int1(%d,%d) = 1; end',header1{1},i1,i3,header1{2},i2,i3,i1,i2))
        % LEGACY                      if (strcmp(Batch_header.elec_rate_instance.val{i0},raw1{i2,1}) && strcmp(Batch_header.load_prof_instance.val{i1},raw1{i2,2}) ), Int1(i0,i1) = 1; end
                    end
                end
            end
            eval(sprintf('Batch_header.%s.%s = Int1;',header1{1},header1{2}))
        % LEGACY          Batch_header.elec_rate_instance.load_prof_instance = Int1;
        end
end