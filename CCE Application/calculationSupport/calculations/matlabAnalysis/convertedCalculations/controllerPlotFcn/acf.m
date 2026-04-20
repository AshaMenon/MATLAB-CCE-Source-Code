function acor = acf(x,n,period)
%ACF Autocorrelation of time series
%  Performs the autocorrelation function of a time series.
%  The inuputs are the time series vector (x),
%  the number of sample periods to consider (n),
%  and the optional variable of the sample time
%  (period) which is used to scale the output plot.
%  The output is the autocorrelation function (acor).
%
%I/O: acor = autocor(x,n,period);
%
%See also: CORRMAP, CROSSCOR, CCORDEMO

%Copyright Eigenvector Research, Inc. 1992-98
%Modified BMW 11/93

[mp,np] = size(x);
if np > mp
  x = x';
  mp = np;
end
acor = zeros(2*n+1,1);

ax = acfauto(x);
for i = 1:n
  ax1 = ax(1:mp-n-1+i,1);
  ax2 = ax(n+2-i:mp,1);
  acor(i,1) = ax1'*ax2/(mp-n+i-2);
end
acor(n+1,1) = ax'*ax/(mp-1);
for i = 1:n
  acor(n+i+1) = acor(n+1-i);
end 
if nargin == 3
  scl = period*(-n:1:n);
else
  scl = -n:1:n;
end
% plot(scl,acor)
% title('Autocorrelation Function')
% xlabel('Signal Time Shift (Tau)')
% ylabel('Correlation [ACF(Tau)]') 
% hold on
% plot(scl,zeros(size(scl)),'--g',[0 0],[-1 1],'--g')
% axis([scl(1,1) -scl(1,1) -1 1])
% hold off