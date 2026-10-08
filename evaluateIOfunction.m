% EVALUATEIOFUNCTION - from Koponen et al paper

function y = evaluateIOfunction(x,deltay,s,m)

y = deltay * (1 + erf(sqrt(pi)/20/deltay*s*(x-m)))./2;

