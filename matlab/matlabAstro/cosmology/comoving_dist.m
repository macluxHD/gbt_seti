function ComovDist=comoving_dist(Z,CosmoPars);
%------------------------------------------------------------------------------
% comoving_dist function                                             cosmology
% Description: Calculate the line of sight comoving distance.
% Input  : - Redshift.
%          - Cosmological parameters:
%          - Cosmological parameters :
%            [H0, \Omega_{m}, \Omega_{\Lambda}, \Omega_{radiation}],
%            or cosmological parmeters structure, or a string containing
%            parameters source name, default is 'wmap3' (see cosmo_pars.m).
%            Default for Omega_radiation is 0.
% Output : - Comoving distance [pc].
% Reference : http://nedwww.ipac.caltech.edu/level5/Hogg/frames.html
% Tested : Matlab 7.0
%     By : Eran O. Ofek                      July 2006
%    URL : http://wise-obs.tau.ac.il/~eran/matlab.html
% Example: ComovDist=comoving_dist([1;2]);
% Reliable: 2
%------------------------------------------------------------------------------

if (nargin==1),
   CosmoPars = 'wmap3';
elseif (nargin==2),
   % do nothing
else
   error('Illegal number of input arguments');
end



if (isstr(CosmoPars)==0 & isstruct(CosmoPars)==0),
   % do nothing
else
   Par = cosmo_pars(CosmoPars);
   CosmoPars = [Par.H0, Par.OmegaM, Par.OmegaL, Par.OmegaRad];
end
if (length(CosmoPars)==3),
   CosmoPars(4) = 0;
end

H0        = CosmoPars(1);
C         = get_constant('c','cgs');
DH        = C./(H0.*1e5)  .*1e6;   % [pc]

OmegaPars = CosmoPars(2:end);
Fun       = inline('1./e_z(Z,OmegaPars)','Z','OmegaPars');
ComovDist = zeros(size(Z));
for I=1:1:length(Z),
   if (Z(I)==0),
      ComovDist(I) = 0;
   else
      ComovDist(I) = DH.*quad(Fun,0,Z(I),[],[],OmegaPars);
   end
end
