%% Build Script:Derived Calcs
% Builds CTF for derived calcs:
%   reconstructDensity
%   apcQuantExpression

run(fullfile('..','..','..','..','..','cceSetup.m'))
run(fullfile('..','..','setupDerivedCalcs.m'))
buildCTF('derivedCalcs', {'reconstructDensity', 'apcQuantExpression'})