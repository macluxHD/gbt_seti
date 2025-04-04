function Cat=get_first(RA,Dec,SearchRad)
%--------------------------------------------------------------------------
% get_first function                                             Catalogue
% Description: Search the FIRST (21 cm radio survey)
%              catalog around a given coordinate.
% Input  : - Scalar J2000.0 R.A. (radians, sexagesimal string or [H M S]).
%          - Scalar J2000.0 Dec. (radians, sexagesimal string
%            or [sign D M S]).
%          - Search radius [radians]. Default is 1 deg.
% Output : - Catalog of FIRST source within the search region.
%            This is a structure containing the following fields:
%            .Cat     - The catalog.
%            .ColCell - Cell array of column names.
%            .Col     - Structure array of column names/index.
%            .ColUnits - Cell array of column units.
%            .SortedBy - Sorted by column name.
%            .SortedByCol - Sorted by column index.
% See also: get_nvss.m, get_cat.m
% Tested : Matlab R2014a
%     By : Eran O. Ofek                    Feb 2015
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: Cat=get_first(2,1);
%          Cat=get_first('12:00:00','+20:00:00');
% Reliable: 2
%--------------------------------------------------------------------------
InvRAD = pi./180;

HTMcenters    = 'FIRST_htm.mat';
%HTM_BASE_NAME = 'FIRST_htm%05d.mat';
DataDir       = 'FIRST_htm';

if (nargin==2),
    SearchRad = InvRAD;   % Default search radius is 1 deg.
end

% convert coordinates to radians
RA  = convertdms(RA,'gH','r');
Dec = convertdms(Dec,'gD','R');

DataPath = sprintf('%s%s%s%s',which_dir(HTMcenters),filesep,DataDir,filesep);
    
% pointers to HTMs within search region
HTMcenters = load2(HTMcenters);
HTMind = search_htm_coocat(RA,Dec,SearchRad,HTMcenters,false);
% construct HTM file names
HTM_BASE_NAME = HTMcenters.FileBaseName;
Files  = sprintf2cell(HTM_BASE_NAME,HTMind);
% load files
Cat.Cat = zeros(0,length(HTMcenters.CatHTM.ColCell));
for Ifiles=1:1:numel(Files),
    Cat1 = load2(sprintf('%s%s',DataPath,Files{Ifiles}));
    Cat.Cat = [Cat.Cat; Cat1];
end
% return sources within search radius
Cat.Col         = HTMcenters.CatHTM.Col;
Cat.ColCell     = HTMcenters.CatHTM.ColCell;
D = sphere_dist_fast(Cat.Cat(:,Cat.Col.RA),Cat.Cat(:,Cat.Col.Dec),RA,Dec);
Cat.Cat         = Cat.Cat(D<SearchRad,:);
Cat.Cat         = sortrows(Cat.Cat,Cat.Col.Dec);
Cat.ColUnits    = HTMcenters.CatHTM.ColUnits;
Cat.SortedBy    = HTMcenters.CatHTM.ColCell{HTMcenters.CatHTM.Col.Dec};
Cat.SortedByCol = HTMcenters.CatHTM.Col.Dec;

    