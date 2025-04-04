function Cat=get_apass(RA,Dec,SearchRad)
%--------------------------------------------------------------------------
% get_apass function                                             Catalogue
% Description: Search the APASS (AAVOS photometric all sky survey)
%              catalog around a given coordinate.
% Input  : - Scalar J2000.0 R.A. (radians, sexagesimal string or [H M S]).
%          - Scalar J2000.0 Dec. (radians, sexagesimal string
%            or [sign D M S]).
%          - Search radius [radians]. Default is 1 deg.
% Output : - Catalog of APASS source within the search region.
%            This is a structure containing the following fields:
%            .Cat     - The catalog.
%            .ColCell - Cell array of column names.
%            .Col     - Structure array of column names/index.
%            .ColUnits - Cell array of column units.
%            .SortedBy - Sorted by column name.
%            .SortedByCol - Sorted by column index.
% Tested : Matlab R2014a
%     By : Eran O. Ofek                    Feb 2015
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: Cat=get_apass(2,1);
%          Cat=get_apass('18:00:00','-20:00:00');
% Reliable: 2
%--------------------------------------------------------------------------
InvRAD = pi./180;

HTMcenters    = 'APASS_htm.mat';
%HTM_BASE_NAME = 'APASS_htm%05d.mat';
DataDir       = 'APASS_htm';

if (nargin==2),
    SearchRad = InvRAD;   % Default search radius is 1 deg.
end

% convert coordinates to radians
RA  = convertdms(RA,'gH','r');
Dec = convertdms(Dec,'gD','R');

DataPath = sprintf('%s%s%s%s',which_dir(HTMcenters),filesep,DataDir,filesep);
    
% pointers to HTMs within search region
HTMcenters = load2(HTMcenters);
HTM_BASE_NAME = HTMcenters.FileBaseName;

Col        = HTMcenters.CatHTM.Col;
ColCell    = HTMcenters.CatHTM.ColCell;
HTMind = search_htm_coocat(RA,Dec,SearchRad,HTMcenters,false);
% construct HTM file names
Files  = sprintf2cell(HTM_BASE_NAME,HTMind);
% load files
Cat.Cat = zeros(0,length(ColCell));
for Ifiles=1:1:numel(Files),
    Cat1 = load2(sprintf('%s%s',DataPath,Files{Ifiles}));
    Cat.Cat = [Cat.Cat; Cat1];
end
% return sources within search radius
D = sphere_dist_fast(Cat.Cat(:,Col.RA),Cat.Cat(:,Col.Dec),RA,Dec);
Cat.Cat         = Cat.Cat(D<SearchRad,:);
Cat.Cat         = sortrows(Cat.Cat,Col.Dec);
Cat.Col         = Col;
Cat.ColCell     = ColCell;
Cat.ColUnits    = HTMcenters.CatHTM.ColUnits;
Cat.SortedBy    = HTMcenters.CatHTM.SortedBy;
Cat.SortedByCol = HTMcenters.CatHTM.SortedByCol;

    
    
