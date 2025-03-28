function [OmegaMz]=omega_z(Z,OmegaPar);
%------------------------------------------------------------------------------
% omega_z function                                                   cosmology
% Description: Calculate \Omega_{m} as a function of redshift z.
% Input  : - Redshift vector.
%          - Parameters at zero redshift.
%            [\Omega_{m}, \Omega_{\Lambda}]
% Output : - Vector of \Omega_{m}(Z) corresponding to redshift vector.
% Reference : Porciani & Madau 2000 ApJ 532, 679.
% Tested : Matlab 5.3
%     By : Eran O. Ofek                   
%    URL : http://wise-obs.tau.ac.il/~eran/matlab.html
% Example: [OmegaMz]=omega_z(1,[0.3 0.7]);
% Reliable: 1
%------------------------------------------------------------------------------

OmegaM = OmegaPar(1);
OmegaL = OmegaPar(2);
%the curvature contribution to the present density parameter.
OmegaK = 1 - OmegaM - OmegaL;

OmegaMz = OmegaM.*(1+Z).^3./(OmegaM.*(1+Z).^3 + OmegaK.*(1+Z).^2 + OmegaL);
