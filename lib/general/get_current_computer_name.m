function computer_name = get_current_computer_name
% computer_name = get_current_computer_name
%
% retrieves computer-specific details as specified
%
% it is worthwhile storing a local copy of this function across updates

computer_name = 'unknown';

% macgyver
if isunix
    try
        [status result] = system('/sbin/ifconfig | grep 00:21:9b:03:37:ee | wc -l');
        if str2num(result(1))
            computer_name = 'macgyver';
        end
    catch
    end
end

% rabbit
if isunix
    try
        [status result] = system('/sbin/ifconfig | grep 00:1d:09:bb:11:46 | wc -l');
        if str2num(result(1))
            computer_name = 'rabbit';
        end
    catch
    end
end

% blueweasel
if isunix
    try
        [status result] = system('/sbin/ifconfig | grep 00:25:64:61:d2:16 | wc -l');
        if str2num(result(1))
            computer_name = 'blueweasel';
        end
    catch
    end
end

% welshcob
try
    [status result] = system('/sbin/ifconfig | grep 00:21:70:5e:99:33 | wc -l');
    if str2num(result(1))
        computer_name = 'welshcob';
    end
catch
end

% chai
if isunix
    try
        [status result] = system('/sbin/ifconfig | grep 00:18:8b:2d:ad:f1 | wc -l');
        if str2num(result(1))
            computer_name = 'chai';
        end
    catch
    end
end

