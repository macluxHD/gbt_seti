function [Lines,DistL,PAL]=cat_search(Cat,ColCoo,SearchCoo,DistThresh,SearchShape,WorkCoo,CooType)
%------------------------------------------------------------------------------
% cat_search function                                                Catalogue
% Description: Search a sorted astronomical catalog for all objects
%              found within a given distance from the search position.
% Input  : - Catalog sorted by Dec or RA.
%            RA and Dec should be in radians.
%          - RA and Dec columns in catalog (e.g., [1 2]).
%          - Coordinates to search [RA, Dec] in radians.
%          - Distance radius/half-width threshold in radians.
%          - Shape of search region: {'circle' | 'box'},
%            default is 'circle'.
%          - Coordinate to search by {'RA' | 'Dec'}, default is 'Dec'.
%            The catalog should be sorted by this column.
%          - Coordinates type:
%            'sphere' - Spherical coordinates. Coordinates must be
%                       given in radians. Default.
%            'plane'  - plan coordinates.
% Output : - Indices of lines in catalog found in search radius.
%          - Respective distance from search coordinates (radians).
%          - Respective PA from search coordinates (radians).
% Tested : Matlab 5.3
%     By : Eran O. Ofek                       Feb 2004
%    URL : http://wise-obs.tau.ac.il/~eran/matlab.html 
% RunTime: Typical search of FIRST catalog is 50 times faster than
%          a simple find command.
% Example: [Lines,DistL,PAL]=cat_search(first_030411,[1 2],[2.61 0.17],0.003);
% Reliable: 1
%------------------------------------------------------------------------------
if (nargin==4),
   SearchShape = 'circle';
   WorkCoo     = 'Dec';
   CooType     = 'sphere';
elseif (nargin==5),
   WorkCoo     = 'Dec';
   CooType     = 'sphere';
elseif (nargin==6),
   CooType     = 'sphere';
elseif (nargin==7),
   % do nothing
else
   error('Illegal number of input arguments');
end

CatSize  = size(Cat,1);

switch WorkCoo
 case 'RA'
    WorkCooCat    = ColCoo(1);
    WorkCooSearch = 1;

    MaxAbsDec = max(abs(SearchCoo(2)+[-DistThresh;+DistThresh]));
    if (MaxAbsDec>=(pi./2)),
       LowerRA = 0;
       UpperRA = 2.*pi;
    else
       LowerRA  = min(SearchCoo(WorkCooSearch) - DistThresh./cos(MaxAbsDec));
       UpperRA  = max(SearchCoo(WorkCooSearch) + DistThresh./cos(MaxAbsDec));
    end

    if (LowerRA>0 && UpperRA<(2.*pi)),
       Ilower   = bin_sear(Cat(:,WorkCooCat),LowerRA);
       Iupper   = bin_sear(Cat(:,WorkCooCat),UpperRA);

       if (Ilower>1),
          Ilower = Ilower - 1;
       end
       if (Ilower<=0),
          Ilower = 1;
       end
       if (Iupper<CatSize),
          Iupper = Iupper + 1;
       end
       if (Iupper>CatSize),
          Iupper = CatSize;
       end
   
       Range = (Ilower:1:Iupper).';

    else
       if (LowerRA<0 && UpperRA>(2.*pi)),
          Range = (1:1:CatSize).';
       else
          if (LowerRA<0),
             Iupper1 = CatSize;
             Ilower1 = bin_sear(Cat(:,WorkCooCat), 2.*pi + LowerRA);
             if (Ilower1>1),
                Ilower1 = Ilower1 - 1;
             end

             Ilower2 = 1;
             Iupper2 = bin_sear(Cat(:,WorkCooCat), UpperRA);
             if (Iupper2<CatSize),
                Iupper2 = Iupper2 + 1;
             end

             Range = [(Ilower1:1:Iupper1).';(Ilower2:1:Iupper2).'];

          elseif (UpperRA>(2.*pi)),
             Ilower1 = bin_sear(Cat(:,WorkCooCat), LowerRA);
             if (Ilower1>1),
                Ilower1 = Ilower1 - 1;
             end
             Iupper1 = CatSize;
             
             Ilower2 = 1;
             Iupper2 = bin_sear(Cat(:,WorkCooCat), UpperRA - 2.*pi);
             if (Iupper2<CatSize),
                Iupper2 = Iupper2 + 1;
             end

             Range = [(Ilower1:1:Iupper1).';(Ilower2:1:Iupper2).'];

          else
             error('Impossible - error');
          end

       end
       if (UpperRA>(2.*pi)),
          Iupper = CatSize;
       end
    end


 case 'Dec'
    WorkCooCat    = ColCoo(2);
    WorkCooSearch = 2;

    LowerDec = min(SearchCoo(WorkCooSearch) - DistThresh);
    UpperDec = max(SearchCoo(WorkCooSearch) + DistThresh);
    
    Ilower   = bin_sear(Cat(:,WorkCooCat),LowerDec);
    Iupper   = bin_sear(Cat(:,WorkCooCat),UpperDec);

    
    if (Ilower>1),
       Ilower = Ilower - 1;
    end
    if (Ilower<=0),
       Ilower = 1;
    end
    if (Iupper<CatSize),
       Iupper = Iupper + 1;
    end
    if (Iupper>CatSize),
       Iupper = CatSize;
    end

    Range = (Ilower:1:Iupper).';


 otherwise
    error('Unknown WorkCoo option');
end





if (isempty(Range)),
   Lines = [];
   DistL = [];
   PAL   = [];
else
   if (length(DistThresh)>1),
      DistThresh = DistThresh(Range);
   end
   switch CooType
    case 'sphere'
       [Dist,PA]  = sphere_dist(SearchCoo(1),SearchCoo(2),Cat(Range,ColCoo(1)),Cat(Range,ColCoo(2)),'rad');
    case 'plane'
       [Dist,PA]  = plane_dist(SearchCoo(1),SearchCoo(2),Cat(Range,ColCoo(1)),Cat(Range,ColCoo(2)));
    otherwise
       error('Unknown CooType Option');
   end

   switch SearchShape
    case 'circle'
       %--- circle shape search ---
       I     = find(Dist<=DistThresh);
       Lines = Range(I);
       DistL = Dist(I);
       PAL   = PA(I);
    case 'box'
       %--- box shape search ---
       I     = find(Dist<=(DistThresh.*sqrt(2)));

       X     = Dist(I).*cos(PA(I));
       Y     = Dist(I).*sin(PA(I));
       IndBox= find(abs(X)<=DistThresh & abs(Y)<=DistThresh);

       Lines = Range(I(IndBox));
       DistL = Dist(I(IndBox));
       PAL   = PA(I(IndBox));
    otherwise
       error('Unknown SearchShape');
   end  
end

