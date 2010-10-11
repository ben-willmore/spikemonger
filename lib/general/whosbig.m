allvars = whos;
allvars = allvars([allvars.bytes] > 1e6);


tabletoshow = cell(L(allvars),3);
maxnamelength = 0;
for av_ii=1:L(allvars)
	tabletoshow{av_ii,1} = allvars(av_ii).name;
        if L(allvars(av_ii).name) > maxnamelength, maxnamelength = L(allvars(av_ii).name); end
    tabletoshow{av_ii,2} = round(allvars(av_ii).bytes / 1e6);
    tabletoshow{av_ii,3} = allvars(av_ii).class;
end

disp(' ');
titlestoshow = {'Name','Mbytes','Class'};
for av_ii=5:(maxnamelength-2)
    titlestoshow{1} = [titlestoshow{1} ' '];
end
disp(titlestoshow);
disp(tabletoshow);
clear allvars tabletoshow av_ii maxnamelength;