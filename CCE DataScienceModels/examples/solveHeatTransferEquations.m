%% Full set of equations, assuming variable slag temps as well

syms t Tm(t) Ts(t) hm(t) hs(t) a c1 c2 c3 c4 c5 mDotFeed mDotFeedTot ...
    b mDotDust mDotAccSlag hHole U qDotHXL qDotCond cBarS alpha deltaHF ...
    deltaHC mDotCoal cBarEq deltaTs Tamb cBarOffgas cBarDust ...
    

% Matte Bath - Mass balance
matteMassBalance = diff(hm(t)) == a*c2*mDotFeed - c3*(c1*hs(t) + hm(t))^0.5;

% Full Bath - Mass balance
fullMassBalance = diff(hm(t)) + c1*diff(hs(t)) == c2*(mDotFeedTot*(1 - b) - mDotDust - mDotAccSlag) - ...
    c3*(c1*hs(t) + hm(t))^0.5; % - c5*c1*(hm(t) + hs(t) - hHole)^0.5

% Matte Bath - Energy balance
matteEnergyBalance = diff(hm(t)*Tm(t)) == c4*U*(Ts(t) - Tm(t)) + a*c2*mDotFeed*(Ts(t) - ...
    Tm(t)) - 2*c4*qDotHXL*hm(t) - c4*qDotCond - c3*Tm(t)*(c1*hs(t) + hm(t))^0.5;

% Full Bath - Energy balance
% fullEnergyBalance = diff(Tm(t)*hm(t) + c1*cBarS*Ts(t)*hs(t)) == c2*(mDotFeedTot*alpha*deltaHF +...
%     mDotCoal*deltaHC - mDotFeedTot*cBarEq*(Ts(t) + deltaTs - Tamb) - (b*mDotFeedTot*cBarOffgas +...
%     mDotDust*cBarDust + mDotAccSlag*

% fullEnergyBalance = diff(E) == Qgen - Qrad - Qhx



%% Solution to basic gravity flow (with constant source)

syms h(t) t c1 h0 c2

eqn = diff(h(t)) + c1*h(t)^0.5 == c2;

soln = dsolve(eqn, h(0) == h0)
pretty(soln)

% Plot the solution
h0 = 2;
c1 = 0.1;
c2 = 0.14;

fplot(real(subs(soln(2))), [0 1000])