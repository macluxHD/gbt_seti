function [Cat,ColCell,Col,UnitsCell,Comments]=wget_ucac4(RA,Dec,SearchSize,SearchShape)
%------------------------------------------------------------------------------
% wget_2mass function                                                Catalogue
% Description: Query the UCAC4 catalog using the VizieR web service.
% Installation: 1. install cdsclient (instructions can be found
%               in: http://cdsarc.u-strasbg.fr/doc/cdsclient.html)
%               in $USER/matlab/fun/bin/vizquery/cdsclient-3.71/
%               2. If you installed the cdsclient in a different location,
%               then edit the first few lines of the code accordingly.
% Input  : - R.A. in [H M S] format or in radians or in sexagesimal string.
%          - Dec. in [Sign D M S] format or in radians or in sexagesimal
%            string.
%          - Search radius in radians.
%          - Search shape {'circle','box'}, default is 'circle'.
% Output : - Matrix of 2MASS sources found within search region.
%            The matrix contains the following columns:
%            1. RA (J2000) [rad].
%            2. Dec (J2000) [rad].
%            3. J mag [mag].
%            4. J ma err [mag].
%            5. H mag [mag].
%            6. H ma err [mag].
%            7. K mag [mag].
%            8. K ma err [mag].
%            9. JD of observation [days].
%            10. Distance to nearest USNO-A2 source.
%            11. PA of nearst USNO-A2 source.
%            12. B mag of nearest source [mag].
%            12. R mag of nearest source [mag].
%          - Cell array of column names.
%          - A structure in which the fields are the column names,
%            and the field value is the column index.
%          - Cell array of column units.
% Tested : Matlab R2011b
%     By : Eran O. Ofek                    Jan 2014
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: [Cat,ColCell,Col,Units,Comments]=wget_ucac4([10 0 0],[+1 40 0 0],900./(RAD.*3600));
% Reliable: 2
%------------------------------------------------------------------------------
RAD  = 180./pi;
MaxNumStar  = 100000;

Dir = which_dir('wget_ucac4');
ProgPath = '../bin/vizquery/cdsclient-3.72/';
ProgName = 'finducac4';
Prog     = sprintf('%s/%s%s',Dir,ProgPath,ProgName);

% ProgName = 'finducac4';
% Path     = vizquery_path(ProgName);   % GO THIS THIS PROGRAM AND EDIT IF NEEDED
% Prog     = sprintf('%s%s',Path,ProgName);

DefSearchShape   = 'circle';
if (nargin==3),
   SearchShape   = DefSearchShape;
elseif (nargin==4),
   % do nothing
else
   error('Illegal number of input arguments');
end

RA  = convertdms(RA,'gH','SH');
Dec = convertdms(Dec,'gD','SD');

switch SearchShape
 case {'circ','circle'}
    ShapeKey = '-rs';
 case 'box'
    ShapeKey = '-bs';
 otherwise
    error('Unknown SearchShape option');
end


%sprintf('%s %s -c %s %s %7.1f -m %d',Prog, RA, Dec, ShapeKey, SearchSize, MaxNumStar);
SearchSizeAS = SearchSize.*RAD.*3600;  % search size in arcsec
[Stat,Res]=system(sprintf('%s -c %s %s %s %7.1f -m %d',Prog, RA, Dec, ShapeKey, SearchSizeAS, MaxNumStar));

%Res

[Lines]=textscan(Res,'%s %s %s %s %s %s %s %s %s %s %s %s\n','commentstyle','#','delimiter','|');

Nl = length(Lines{1});
if (Nl==0),
  Out = [];
end

ColCell    = {'RA','Dec','errRAm','errDecm','errJ2000','EpochRA','EpochDec','ModelMag','AperMag','ErrMag','Flag','DoubleStar','Na','Nu','Nc','pmRA','pmDec','ErrPMRA','ErrPMDec'};
Cat        = zeros(Nl,length(ColCell)).*NaN;
Col        = cell2struct(num2cell([1:1:length(ColCell)]),ColCell,2);
UnitsCell  = {'rad','rad','mas','mas','mas','yr','yr','mag','mag','mag','','','','','','mas/yr','mas/yr','mas/yr','mas/yr'};
Comments{1}= 'RA equinox and epoch J2000';
Comments{2}= 'Dec equinox and epoch J2000';
Comments{3}= 'RA error at mean epoch';
Comments{4}= 'Dec error at mean epoch';
Comments{5}= 'Total position error at J2000';
Comments{11}='Class flag:\n 0=clean\n 1=near overexposed star\n 2=possible streak object\n 3=high proper motion (HPM) star\n 4=external HPM data\n 5=poor proper motion solution\n 6=data from FK6/Hip/Tycho-2 data\n 7=added fron FK6/Hip/Tycho-2\n 8=high proper motion solution in UCAC4, not matched with PPMXL\n 9=high proper motion solution in UCAC4, discrepant motion to PPMXL\n';
Comments{12}='double star flag:\n 0-single';


Nl = length(Lines{1});
for Il=1:1:Nl,
   Info                  = textscan(Lines{2}{Il},'%11s %11s %s %s %s %s %s');
  
   Cat(Il,1)  = str2double(Info{1})./RAD;    % RA [rad] J2000 Epoch J2000
   Cat(Il,2)  = str2double(Info{2})./RAD;    % Dec [rad] J2000 Epoch J2000
   Cat(Il,3)  = str2double(Info{3});         % eRA [mas] at mean epoch
   Cat(Il,4)  = str2double(Info{4});         % eDec [mas] at mean epoch
   Cat(Il,5)  = str2double(Info{5});         % ePos [mas] total at J2000.0
   Cat(Il,6)  = str2double(Info{6});         % Epoch RA [JY]
   Cat(Il,7)  = str2double(Info{7});         % Epoch Dec [JY]

   Info                  = textscan(Lines{3}{Il},'%s %s %s');
   Cat(Il,8)  = str2double(Info{1});         % model mag
   Cat(Il,9)  = str2double(Info{2});         % aperture mag
   Cat(Il,10) = str2double(Info{3});         % error mag

   Info                  = textscan(Lines{4}{Il},'%s %s');
   Cat(Il,11) = str2double(Info{1});         % flag 
   Cat(Il,12) = str2double(Info{2});         % double star flag

   Info                  = textscan(Lines{5}{Il},'%s %s %s');
   Cat(Il,13) = str2double(Info{1});         % Number of UCAC obs
   Cat(Il,14) = str2double(Info{2});         % Number of UCAC used obs
   Cat(Il,15) = str2double(Info{3});         % Number of catalog positions used for PM
   
   if (isempty(Lines{6}{Il})),
       Cat(Il,16) = NaN;
       Cat(Il,17) = NaN;
       Cat(Il,18) = NaN;
       Cat(Il,19) = NaN;
   else
       Info                  = textscan(Lines{6}{Il},'%s %s %s %s');
       Cat(Il,16) = str2double(Info{1});         % PM RA [mas/yr]
       Cat(Il,17) = str2double(Info{2});         % PM Dec [mas/yr]
       Cat(Il,18) = str2double(Info{3});         % errPM RA [mas/yr]
       Cat(Il,19) = str2double(Info{4});         % errPM Dec [mas/yr]
   end

end


% sort by declination
Cat = sortrows(Cat,Col.Dec);