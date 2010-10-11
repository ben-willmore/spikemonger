function stars = significanceStars(pvalue)
    % SIGNIFICANCESTARS
    %   significanceStars(pvalue)
    %
    % takes a p-value, and returns a string representing the significance
    %   '':    p > 0.05
    %   '*':   p < 0.05
    %   '**':  p < 0.01
    %   '***': p < 0.001
    
    if pvalue < 0.001,
        stars = '***';
    elseif pvalue < 0.01,
        stars = '**';
    elseif pvalue < 0.05,
        stars = '*';
    else
        stars = '';
    end
    
end