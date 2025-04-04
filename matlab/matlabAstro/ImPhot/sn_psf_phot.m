function [SN,SNrad]=sn_psf_phot(S,Sigma,B,R,Radius)
%--------------------------------------------------------------------------
% sn_psf_phot function                                              ImPhot
% Description: Calculate the S/N (signal-to-noise ratio) for a point
%              source with a symmetric Gaussian profile for PSF (optimal)
%              photometry.
% Input  : - Source signal [electrons].
%          - Sigma of PSF [pixels].
%          - Background [e/pix].
%          - Readout noise [e].
%          - PSF radius [pix]. Default is 20.
% Output : - Theoretical S/N of PSF photometry (with radius
%            from 0 to infinity).
%          - S/N of PSF photometry with PSF truncated at Radius.
% See also: optimal_phot_aperture.m, sn_aper_phot.m, sn_psfn_phot.m,
%           sn_psf_det.m
% License: GNU general public license version 3
% Tested : Matlab R2014a
%     By : Eran O. Ofek                    Mar 2015
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: SN=sn_psf_phot(1000,1,500,10)
% Reliable: 2
%--------------------------------------------------------------------------

if (nargin==4),
    Radius = 20;
end

SN = sqrt(S + 2.*pi.*Sigma.^2.*(B+R.^2).*log( (2.*pi.*Sigma.^2.*(B+R.^2) )./(2.*pi.*Sigma.^2.*(B+R.^2) + S )));
%SN = sqrt(S - 2.*pi.*Sigma.^2.*(B+R.^2).*log(1 +
%S./(2.*pi.*Sigma.^2.*(B+R.^2))))  % the same...

FunInt = @(Sigma,S,B,R,r) 2.*pi.*Sigma.^2.*log(S.*exp(-r.^2./(2.*Sigma.^2)) + 2.*pi.*R.^2.*Sigma.^2 + 2.*B.*pi.*Sigma.^2).*(B + R.^2) - S.*exp(-r.^2./(2.*Sigma.^2));

SNrad = sqrt(FunInt(Sigma,S,B,R,Radius) - FunInt(Sigma,S,B,R,0));
