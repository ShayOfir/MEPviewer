function R_squared = compute_R2 (y,yfit)
    
    if ~iscolumn(yfit)
        yfit = yfit';
    end

    if ~iscolumn(y)
        y = y';
    end
    % Calculate the total sum of squares (SST)
    y_mean = mean(y);

    SST = sum((y - y_mean).^2);
    
    % Calculate the residual sum of squares (SSR)
    SSR = sum((y - yfit).^2);
    
    % Calculate R-squared
    R_squared = 1 - (SSR / SST);


end