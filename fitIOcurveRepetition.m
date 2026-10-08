function [result,percent_threshold,logMEPsMEP0,r2] = fitIOcurveRepetition(subject,repetition,channels,toplot)

if nargin<4 || isempty(toplot)
    toplot = 0;
end

[~,measures] = calculateMeasuresRepetition(subject,repetition,channels);

for c=1:2
    MEPs = measures.PeakToPeak_mean(:,c);
    MEP0 = measures.PeakToPeakBaseline(:,c);
    this_percent_threshold = measures.percent_threshold;

    good = find(~isnan(MEPs) & ~isnan(MEP0) & ~isnan(this_percent_threshold));
    MEPs = MEPs(good);
    MEP0 = MEP0(good);
    this_percent_threshold = this_percent_threshold(good);

    if isempty(MEPs)
        result(c,:) = NaN;
        logMEPsMEP0(c) = NaN;
        r2(c) = NaN;
        percent_threshold(c) = NaN;
        order(c) = NaN;      
    else
        [result(c,:),logMEPsMEP0(c),r2(c)] = fitIOcurve(this_percent_threshold,MEPs,MEP0,toplot);
        [percent_threshold(c,:),order(c,:)] = sort(this_percent_threshold);
        logMEPsMEP0(c,:) = logMEPsMEP0(order(c,:));
    end
end
