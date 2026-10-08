% FITIOCURVE - fit the IO curve to a sigmoidal function

function [result,y,r2] = fitIOcurve(percent_threshold,MEPs,MEP0,toplot)

if nargin<4
    toplot = 0;
end

x = percent_threshold;
y = log10(MEPs./MEP0);

% The three parameters are deltay, s and m
% Use starting values as in paper
deltay_0 = max(y);
s_0 = 1; % dB / % MSO
m_0 = (min(x)+max(x))/2;

x0 = [deltay_0 s_0 m_0];

options = optimset('fminsearch');
options = optimset(options,'MaxFunEvals',1e12);

result = fminsearch(@(p) costfunction(p,MEPs,MEP0,x),x0,options);

deltay = result(1);
s = result(2);
m = result(3);

minx = 0; %min(x);
maxx = 200; %max(x);
%xs = linspace(minx,maxx,100);
xs=0:200;
yfit = evaluateIOfunction(xs,deltay,s,m);

yfit_focus = zeros(1,length(x));
for j=1:length(x)
    %this is a patch to fix a bug in one of the files (S302_Shlomi_rt_rf)
    %without requiring us to repeat cleaning again:
    if x(j) == 1505
        x(j) = 150;
    end
    yfit_focus(j) = yfit(xs == x(j));
end

r2 = compute_R2(y,yfit_focus);



if toplot
    figure;
    % minx = 0; %min(x);
    % maxx = 200; %max(x);
    % xs = linspace(minx,maxx,100);
    % yfit = evaluateIOfunction(xs,deltay,s,m);
    plot(xs,yfit);
    hold on;
    plot(x,y,'r*');
end