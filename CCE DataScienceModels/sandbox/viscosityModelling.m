%% Viscosity Modelling
v_sMax = 5;
r = [-r_s, 0, r_s];
v = [0, v_sMax, 0];

r = [-r_s,-r_s+0.01 , 0, r_s-0.01, r_s];
v = [0, v_sMax, 0];


coeffs = polyfit(r,v,2);
a1 = coeffs(1,1);
b1 = coeffs(1,2);
c1 = coeffs(1,3);
syms x
y = a1*x^2 + b1*x^2 + c1;
f = int(y,[-r_s r_s]);

%%
a1 = 1;

v1 = a1*(r.^2-r_s^2);
v2 = a1*(r_s^2-r.^2);

figure
plot(v1,r)


figure
plot(v2,r)


%%
syms r_s r
eqn = (r_s^2 - r^2)/r_s^2;
integral = int(eqn, [-r_s r_s]);
vbar_vmax = integral/2*r_s;

