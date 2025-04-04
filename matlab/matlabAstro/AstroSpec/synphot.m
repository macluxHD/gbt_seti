function [Mag,Flag,FiltEffWave]=synphot(Spec,FiltFam,FiltName,MagSys,Algo,Ebv,R)
%------------------------------------------------------------------------------
% synphot function                                                   AstroSpec
% Description: Calculate synthetic photometry of a spectrum.
% Input  : - Spectrum [wavelength(Ang), Flux(F_{\lambda})].
%          - Filter normalized transmission curve,
%            or a string containing filter familiy name,
%            see get_filter.m for details.
%            Filter transmission curve override filter name.
%          - Filter name, see get_filter.m for details.
%          - Magnitude system: {'Vega' | 'AB'}
%          - Algorithm used:
%            'Poz' - D. Poznanski, basic_synthetic_photometry.m
%            'cos' - transmission curve interpolated on spectrum.
%                    Default.
%            'soc' - spectrum interpolated on transmission curve.
%            If empty matrix, then use default.
%          - E_{B-V} extinction to apply to spectrum before calculating
%            the synthetic photometry. Default is 0.
%            This function is using the Cardelli et al. model implemented
%            in extinction.m
%          - R_v of extinction. Default is 3.08.
% Output : - Synthetic magnitude.
%          - The fraction of flux that was extrapolated in case of
%            partial coverage between spectrum and filter.
%            0 - means no extrapolation.
%          - Filter effective wavelength [Ang].
% Tested : Matlab 7.3
%     By : Eran O. Ofek                    May 2008
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Comments: The 'Poz' option requires basic_synthetic_photometry.m 
%           by: Dovi Poznanski.
% Example: Spec=get_spectra('Gal_E');
%          [Mag,Flag]=synphot(Spec,'SDSS','r','AB');
%          [Mag,Flag]=synphot(Spec,'SDSS','r','AB',[],0.1); % apply extinction
% Reliable: 1
%------------------------------------------------------------------------------
InterpMethod = 'linear';
Def.Algo = 'cos';
Def.Ebv  = 0;
Def.R    = 3.08;
if (nargin==4),
   Algo   = Def.Algo;
   Ebv    = Def.Ebv;
   R      = Def.R;
elseif (nargin==5),
   Ebv    = Def.Ebv;
   R      = Def.R;
elseif (nargin==6),
   R      = Def.R;
elseif (nargin==7),
   % do nothing
else
   error('Illegal number of input arguments');
end

if (isempty(Algo)),
   Algo = Def.Algo;
end

if (ischar(FiltFam)==1),
   Filter = get_filter(FiltFam,FiltName);
   Tran   = Filter.nT{1};
   FiltEffWave = Filter.eff_wl{1};
else
   Tran   = FiltFam;
   FiltEffWave = trapz(Tran(:,1),Tran(:,1).*Tran(:,2))./trapz(Tran(:,1),Tran(:,2));
end
%FiltEffWave = Filter.eff_wl{1};

if (Ebv>0),
   % apply extinction
   A = extinction(Ebv,Spec(:,1)./10000,[],R);
   Spec(:,2) = Spec(:,2).*10.^(-0.4.*A);
end

TranNorm = trapz(Tran(:,1),Tran(:,2));

switch lower(Algo)
 case 'poz'
    [Mag,Dmag,Flag] = basic_synthetic_photometry(Spec,Tran,MagSys,[],[0 1]);
 otherwise

    Direction = 'cos';
    switch lower(Direction)
     case {'curve_on_spec','cos'}
        % Interp transminssion curve on Spec
        [Spec,Tran]     = eq_sampling(Spec,Tran,Spec(:,1),InterpMethod);
        I = find(~isnan(Tran(:,2)));
        Spec = Spec(I,:);
        Tran = Tran(I,:);
     case {'spec_on_curve','soc'}
        % Interp Spec on transminssion curve
        Spec     = eq_sampling(Spec,Tran,Tran(:,1));
     otherwise
        error('Unknown Direction option');
    end

    [MinSpec,MinI] = min(Spec(:,1));
    [MaxSpec,MaxI] = max(Spec(:,1));
    Flag = 1 - trapz(Tran(MinI:MaxI,1),Tran(MinI:MaxI,2))./TranNorm;
    if (Flag<1e-5),
        Flag = 0;
    end
    %Min = min(min(Tran(:,1))-min(Spec(:,1)),0);
    %Max = max(max(Spec(:,1))-max(Tran(:,1)),0);
    %Flag = (Min+Max)./range(Tran(:,1));

    switch lower(MagSys)
     case 'ab'
        % convert F_lambda to F_nu
        Freq     = convert_energy(Tran(:,1),'A','Hz');
        SpecFnu  = convert_flux(Spec(:,2),'cgs/A','cgs/Hz',Tran(:,1),'A');

        NormTran = trapz(Freq,Tran(:,2));
        Fnu      = trapz(Freq,SpecFnu.*Tran(:,2))./NormTran;
        %Flam     = convert_flux(Fnu,'cgs/Hz','cgs/A',FiltEffWave,'A');
        Mag      = -48.6 - 2.5.*log10(Fnu);

     case 'vega'
        load vega_spec.mat;
        VegaF   = eq_sampling(vega_spec,Tran,Tran(:,1));
        Freq    = convert_energy(Tran(:,1),'A','Hz');
        Fvega   = trapz(Tran(:,1),Spec(:,2).*Tran(:,2)./VegaF(:,2));
        Mag     = -2.5.*log10(Fvega);

     otherwise
        error('Unknown MagSys option');
    end
end
