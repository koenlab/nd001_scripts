ab = zeros(EEG.trials,1);

for i = 1:length(EEG.event)
    mem  = EEG.event(i).memory_bin;
    
    % Handle AB
    if ismember(mem,{'HH2'})
        ab(i,1) = 1;
    elseif ismember(mem,{'HM1' 'HM2'})
        ab(i,1) = 1;
    elseif ismember(mem,{'MH1' 'MH2'})
        ab(i,1) = 2;
    elseif ismember(mem,{'MM0' 'MM1' 'MM2'})
        ab(i,1) = 2;
    end
    
end
        