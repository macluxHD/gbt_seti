function [Out,Sim]=sim_getcoo(Sim,varargin)
%--------------------------------------------------------------------------
% sim_getcoo function                                             ImAstrom
% Description: Get J2000.0 R.A. and Dec. from image header or SIM header.
% Input  : - SIM or FITS images (see images2sim.m for options).
%          * Arbitrary number of pairs of arguments: ...,keyword,value,...
%            where keyword are one of the followings:
%            'KeyRA'  - Cell array of R.A. keyword names. The function will
%                       retrieve all the keyword's values and will select
%                       the first one which is defined.
%                       Default is {'RA','OBJRA','OBJRAD','CRVAL1'}.
%                       If a numeric scalar value is provided, then this
%                       will assumed to be all the images RA.
%                       If a numeric vector then each element will assumed
%                       to be the corresponding image RA.
%            'KeyDec' - Cell array of Dec. keyword names. The function will
%                       retrieve all the keyword's values and will select
%                       the first one which is defined.
%                       Default is {'DEC','OBJDEC','OBJDECD','CRVAL2'}.
%                       If a numeric scalar value is provided, then this
%                       will assumed to be all the images Dec.
%                       If a numeric vector then each element will assumed
%                       to be the corresponding image Dec.
%            'IsRad'  - A flag indicating if the RA/Dec in the header
%                       are given in radians (false).
%                       Default is false.
%            'KeyEquinox' - Cell array of Equinox. keyword names. The
%                       function will retrieve all the keyword's values and
%                       will select the first one which is defined.
%                       Default is {'EQUINOX'}.
%                       If KeyRA and KeyDec are numeric then the
%                       Equinox can be the Equinox year (scalar).
%                       If KeyRA and KeyDec are numeric and KeyEquinox
%                       is empty then will set Equinox to
%                       2000.0.
%            'IsJD'   - Is Equinox given in JD. Default is false.
%            'OutUnits' - Output units of RA and Dec fields:
%                       'deg' - degrees.
%                       'r'   - radians.
%                       's'   - sexagesimal.
%            'MaxDisc' - Check for discrepency between the various RA/Dec
%                        values. If the difference is larger than this
%                        value then show a warning. Default is Inf [arcsec].
%            'GetJD'   - Get also julian day (JD) for each image using
%                        sim_julday.m. Default is true.
%            'GetLST'  - Calculate local sidreal time for each image.
%                        Default is true.
%                        GetJD must be true in order to calculate LST.
%            'TypeLST' - 'm' (mean) or 'a' (apparent). Default is 'm'.
%            'GetAzAlt'- Calculate also Azimuth/Altitude for each image.
%                        Default is true.
%                        GetJD must be true in order to calculate Az/Alt.
%            'GeodLon' - Observatory geodetic East longitude
%                        in radians. 
%                        If string then will attempt to retrieve from
%                        header keyword name (assuming in deg).
%                        Default is 'OBSLON'.
%            'GeodLat' - Observatory geodetic North latitude
%                        in radians. 
%                        If string then will attempt to retrieve from
%                        header keyword name (assuming in deg).
%                        Default is 'OBSLAT'.
%            'GetParAng'- Calculate also parallactic angle or each image.
%                        Default is true.
%                        GetJD must be true in order to calculate Az/Alt.
%            --- Additional parameters
%            Any additional key,val, that are recognized by one of the
%            following programs:
%            images2sim.m, image2sim.m
% Output : - A structure array with the coordinates for each image.
%            The following fields are available:
%            .RA - Header RA
%            .Dec  Header Dec.
%            .Equinox - Header Equinox.
%            .RA2000 - J2000.0 R.A. [radians].
%            .Dec2000 - J2000.0 Dec. [radians].
%            Optionally:
%            .JD
%            .GeodLon
%            .GeodLat
%            .Az
%            .Alt
%            .ParAng
%          - The SIM images.
% License: GNU general public license version 3
% Tested : Matlab R2014a
%     By : Eran O. Ofek                    Mar 2015
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: Out=sim_getcoo('*.fits');
%          Out=sim_getcoo('*.fits','KeyRA',100);
% Reliable: 2
%--------------------------------------------------------------------------

RAD = 180./pi;
InvRAD = pi./180;

%ImageField  = 'Im';
HeaderField = 'Header';
%FileField   = 'ImageFileName';
%MaskField   = 'Mask';
%BackImField = 'BackIm';
%ErrImField  = 'ErrIm';


DefV.KeyRA          = {'RA','OBJRA','OBJRAD','CRVAL1'};
DefV.KeyDec         = {'DEC','OBJDEC','OBJDECD','CRVAL2'};
DefV.IsRad          = false;   % is RA/Dec given in radians
DefV.KeyEquinox     = {'EQUINOX'};
DefV.IsJD           = false;   % is Equinox in JD - default is Julian years
DefV.OutUnits       = 'deg';   % 'deg','r','S'
DefV.MaxDisc        = Inf;   % max discrepency [arcsec]
DefV.GetJD          = true;
DefV.GetLST         = true;
DefV.TypeLST        = 'm';
DefV.GetAzAlt       = true;
DefV.GeodLon        = 'OBSLON';
DefV.GeodLat        = 'OBSLAT';
DefV.GetParAng      = true;

InPar = set_varargin_keyval(DefV,'n','use',varargin{:});

if (ischar(InPar.KeyRA)),
    InPar.KeyRA = {InPar.KeyRA};
end
if (ischar(InPar.KeyDec)),
    InPar.KeyDec = {InPar.KeyDec};
end
if (ischar(InPar.KeyEquinox)),
    InPar.KeyEquinox = {InPar.KeyEquinox};
end


% read image into SIM
Sim = images2sim(Sim,varargin{:});
Nim = numel(Sim);

NkeyRA      = numel(InPar.KeyRA);
NkeyDec     = numel(InPar.KeyDec);
NkeyEq      = numel(InPar.KeyEquinox);

if (~isnumeric(InPar.KeyRA)),
    CellRA      = sim_getkeyvals(Sim,InPar.KeyRA);
end
if (~isnumeric(InPar.KeyDec)),
    CellDec     = sim_getkeyvals(Sim,InPar.KeyDec);
end
if (~isnumeric(InPar.KeyEquinox)),
    CellEquinox = sim_getkeyvals(Sim,InPar.KeyEquinox);
end

Out = struct_def({'RA','Dec','Equinox','RA2000','Dec2000','JD','LST','GeodLon','GeodLat','Az','Alt','ParAng'},Nim,1);

for Iim=1:1:Nim,
    if (isnumeric(InPar.KeyRA) || ischar(InPar.KeyRA)),
        Out(Iim).RA = InPar.KeyRA(min(Iim,NkeyRA));
    else
        % RA from header
        RA = zeros(NkeyRA,1);
        for Ikey=1:1:NkeyRA,
            Tmp = CellRA{Iim}{Ikey};
            if (ischar(Tmp)),
                RA(Ikey) = convertdms(Tmp,'gH','r').*RAD;
            else
                RA(Ikey) = Tmp;
                if (InPar.IsRad);
                    RA(Ikey) = RA(Ikey).*RAD;
                end
            end
        end
        I_RA = find(~isnan(RA),1,'first');
        if (isempty(I_RA)),
            Out(Iim).RA = NaN;
        else
            Out(Iim).RA = RA(I_RA);   % deg
            if (max(abs(RA - Out(Iim).RA))>InPar.MaxDisc./3600),
                warning('A possible discrepency between various RA keyword values');
            end
        end
    end
    
    if (isnumeric(InPar.KeyDec) || ischar(InPar.KeyDec)),
        Out(Iim).Dec = InPar.KeyDec(min(Iim,NkeyDec));
    else
        % Dec from header
        Dec = zeros(NkeyDec,1);
        for Ikey=1:1:NkeyDec,
            Tmp = CellDec{Iim}{Ikey};
            if (ischar(Tmp)),
                Dec(Ikey) = convertdms(Tmp,'gD','R').*RAD;
            else
                Dec(Ikey) = Tmp;
                if (InPar.IsRad);
                    Dec(Ikey) = Dec(Ikey).*RAD;
                end
            end
        end
        I_Dec = find(~isnan(Dec),1,'first');
        if (isempty(I_Dec)),
            Out(Iim).Dec = NaN;
        else
            Out(Iim).Dec = Dec(find(~isnan(Dec),1,'first'));   % deg
            if (max(abs(Dec - Out(Iim).Dec))>InPar.MaxDisc./3600),
                warning('A possible discrepency between various RA keyword values');
            end
        end
    end
    
    if (isnumeric(InPar.KeyEquinox) || isempty(InPar.KeyEquinox)),
        Out(Iim).Equinox = Inapr.KeyEquinox(min(Iim,NkeyEquinox));
    else
        % Equinox from header
        Equinox = zeros(NkeyEq,1);
        for Ikey=1:1:NkeyEq,
            Tmp = CellEquinox{Iim}{Ikey};
            if (ischar(Tmp)),
                Equinox(Ikey) = str2double(Tmp);
            else
                Equinox(Ikey) = Tmp;
                if (InPar.IsRad);
                    Dec(Ikey) = Dec(Ikey).*RAD;
                end
            end
        end
        I_Eq = find(~isnan(Equinox),1,'first');
        if (isempty(I_Eq)),
            Out(Iim).Equinox = NaN;
        else
            Out(Iim).Equinox = Equinox(I_Eq);
        end
    end
    
    % convert to J2000
    if (InPar.IsJD),
        Equinox = jd2year(Out(Iim).Equinox,'J');
    else
        Equinox = Out(Iim).Equinox;
    end
    if (Equinox~=2000),
        CooJ2000 = coco([Out(Iim).RA,Out(Iim).Dec]./RAD,sprintf('j%6.1f',Equinox),'j2000.0');
        Out(Iim).RA2000  = CooJ2000(1);
        Out(Iim).Dec2000 = CooJ2000(2);
    else
        Out(Iim).RA2000  = Out(Iim).RA./RAD;
        Out(Iim).Dec2000 = Out(Iim).Dec./RAD;
    end
    
    
    switch lower(InPar.OutUnits)
        case 'deg'
            % do nothing
        case 'r'
            Out(Iim).RA   = Out(Iim).RA./RAD;
            Out(Iim).Dec  = Out(Iim).Dec./RAD;
        case 's'
            Out(Iim).RA   = convertdms(Out(Iim).RA,'r','SH');
            Out(Iim).Dec  = convertdms(Out(Iim).Dec,'r','SD');
        otherwise
            error('Unknown OutUnits option');
    end
    
    % get extra information:
    % JD
    if (InPar.GetJD && isfield_notempty(Sim(Iim),HeaderField)),
        Out(Iim).JD = sim_julday(Sim(Iim));
    end
    
    % Geod longitude
    if (ischar(InPar.GeodLon)),
        Tmp = sim_getkeyval(Sim(Iim),InPar.GeodLon);
        Out(Iim).GeodLon = Tmp{1}.*InvRAD;
    else
        Out(Iim).GeodLon = InPar.GeodLon; % assume in radians.
    end
    
    % Geod latitude
    if (ischar(InPar.GeodLat)),
        Tmp = sim_getkeyval(Sim(Iim),InPar.GeodLat);
        Out(Iim).GeodLat = Tmp{1}.*InvRAD;
    else
        Out(Iim).GeodLat = InPar.GeodLat; % assume in radians.
    end
    
    % LST
    if (InPar.GetLST && isfield_notempty(Sim(Iim),HeaderField)),
        Out(Iim).LST = lst(Out(Iim).JD,Out(Iim).GeodLon,InPar.TypeLST);
    end
    
    % Az/Alt
    if (InPar.GetAzAlt && isfield_notempty(Sim(Iim),HeaderField)),
        HCoo = horiz_coo([Out(Iim).RA2000, Out(Iim).Dec2000],Out(Iim).JD,[Out(Iim).GeodLon, Out(Iim).GeodLat],'h');
        Out(Iim).Az  = HCoo(1);
        Out(Iim).Alt = HCoo(2);
    end
    
    % parallactic angle
    if (InPar.GetParAng && isfield_notempty(Sim(Iim),HeaderField)),
        Out(Iim).ParAng = parallactic_angle([Out(Iim).RA2000, Out(Iim).Dec2000],Out(Iim).LST, Out(Iim).GeodLat);
    end
end


