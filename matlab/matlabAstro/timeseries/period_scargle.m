function PS=period_scargle(Data,FreqVec,Norm)
%--------------------------------------------------------------------------
% period_scargle function                                       timeseries
% Description: Calculate the un-normalized Scargle power spectrum of a times
%              series. See period.m for a more flexiable function.
% Input  : - Two column matrix containing the time series
%            [Time, measurment] or [Time, measurment, error].
%          - Frequency range and interval in which to calculate the
%            power spectrum.
%            This is a column vector of frequencies at which to
%            calculate the power spectrum.
%          - Normalization method:
%            'Var' - Normalize by variance (Default).
%            'Amp' - Normalize by amplitude.
% Output : - Two columns matrix of the un-normalized power spectrum
%            [frequency, power_spec].
% Reference: Scargle, J.D. ApJ 263, 835-853 (1982).
%            Horne, J.H. & Baliunas, S.L. ApJ 302, 757-763 (1986).
% See also: period.m
% Tested : Matlab 7.11
%     By : Eran O. Ofek                    May 2011
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Reliable: 2
%--------------------------------------------------------------------------

Def.Norm = 'Var';
if (nargin==2),
   Norm = Def.Norm;
end

Col.T = 1;
Col.M = 2;
T       = Data(:,Col.T);
N       = numel(T);
Nf      = numel(FreqVec);

M       = Data(:,Col.M) - mean(Data(:,Col.M));
PS      = zeros(Nf,2);
PS(:,1) = FreqVec;
for FreqInd=1:1:Nf,
   Tau           = atan(sum(sin(4.*pi.*FreqVec(FreqInd).*T))./sum(cos(4.*pi.*FreqVec(FreqInd).*T)))./(4.*pi.*FreqVec(FreqInd));

   PS(FreqInd,2) = abs(sum(M.*exp(-2.*pi.*1i.*(T-Tau).*FreqVec(FreqInd)))).^2./N;
end

switch lower(Norm)
 case 'amp'
    % do nothing
 case 'var'
    PS(:,2) = PS(:,2)./var(M);
 otherwise
    error('Unknwon normalization option');
end
