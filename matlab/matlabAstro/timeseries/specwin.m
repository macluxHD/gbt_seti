function Pxw = specwin(x,l_f,h_f,df,c_x);
%------------------------------------------------------------------------------
% specwin function                                                  timeseries
% Description: Calculate the spectral window of a time series.
%              THIS FUNCTION IS BEING REPLACED BY period.m
% Input  : - Time series matrix.
%          - h_l, is the low frequency.
%          - h_f, is the high frequency.
%          - df, is the frequency interval.
%          - Time column, default is 1.
% Output : - Spectral window, [Freq, Power].
% Tested : Matlab 4.2
%     By : Eran O. Ofek                   October 1994
%    URL : http://wise-obs.tau.ac.il/~eran/matlab.html
% Reliable: 2
%------------------------------------------------------------------------------

c_y = 2;
if nargin==4,
   c_x = 1;
elseif nargin==5,
   % do nothing
else
   error('Illegal number of input arguments');
end

N0 = length(x(:,c_x));

Freq = [l_f:df:h_f].';
Nf   = length(Freq);
Pxw = zeros(Nf,2);
for I=1:1:Nf;
   Pxw(I,1) = Freq(I);
   Pxw(I,2) = abs(sum(exp(-i.*2.*pi.*Freq(I).*x(:,c_x)))).^2./N0;
end
