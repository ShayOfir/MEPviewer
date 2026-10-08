% COSTFUNCTION - sum of the square difference
function cost = costfunction(params,MEPs,MEP0,x)

deltay = params(1);
s = params(2);
m = params(3);

y = evaluateIOfunction(x,deltay,s,m);

LHS = log10(MEPs./MEP0);

cost = sum((LHS - y).^2);