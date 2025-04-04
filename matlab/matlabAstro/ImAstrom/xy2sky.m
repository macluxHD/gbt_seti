function [Long,Lat]=xy2sky(FileName,X,Y,HDUnum)
%--------------------------------------------------------------------------
% xy2sky function                                                 ImAstrom
% Description: Given a FITS image, SIM or a structure containing the FITS
%              WCS keyword (returned by fits_get_wcs.m), convert X and Y
%              position in the image to longitude and latitude.
% Input  : - A string containing a FITS image name, SIM, or a structure
%            containing the FITS WCS keyword, returned by fits_get_wcs.m.
%          - Vector of X positions [pixel].
%          - Vector of Y positions [pixel].
%          - HDU number in FITS image from which to read the header.
%            Default is 1.
% Output : - Column vector of Longitudes [radian].
%          - Column vector of Latitude [radian].
% Tested : Matlab R2014a
%     By : Eran O. Ofek                    Dec 2014
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: [X,Y]=xy2sky_tan('File.fits',1,1);
%          % or:
%          WCS = get_fits_wcs('File.fits');
%          [X,Y]=xy2sky_tan(WCS,1,1);
%          % or:
%          Sim = images2sim('File.fits');
%          [X,Y]=xy2sky_tan(Sim,1,1);
% Reliable: 2
%--------------------------------------------------------------------------


if (nargin==3),
    HDUnum = 1;
end

% deal with types of input
if (isstruct(FileName)),
    if (isfield(FileName,'CTYPE1')),
        % assume input is a WCS structure (generated by fits_get_wcs.m)
        WCS = FileName;
        CallGetWCS = false;
    else
        CallGetWCS = true;
    end
else
    CallGetWCS = true;
end

if (CallGetWCS),
    WCS = fits_get_wcs(FileName,'HDUnum',HDUnum);
end

if (isnan(WCS.CTYPE1)),
    % no valid WCS in header
    Long = nan(size(X));
    Lat  = nan(size(Y));
else
    
    ProjType1 = WCS.CTYPE1(6:8);  % see also read_ctype.m
    ProjType2 = WCS.CTYPE2(6:8);
    if (~strcmp(ProjType1,ProjType2)),
        error('Axes have different orojection types');
    end

    switch lower(ProjType1)
        case 'tan'
            [Long,Lat] = xy2sky_tan(WCS,X,Y,HDUnum);
        case 'ait'
            [Long,Lat] = xy2sky_ait(WCS,X,Y,HDUnum);
        otherwise
            error('Unsupported projection type: %s',ProjType1);
    end
    
end
        