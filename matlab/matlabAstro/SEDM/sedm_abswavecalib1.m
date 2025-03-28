function AbsCalib=sedm_abswavecalib1(varargin)
%--------------------------------------------------------------------------
% sedm_abswavecalib1 function                                         SEDM
% Description: Find an absolute wavelength calibration solution, relative
%              to a calibrated template, for selected segments.
%              The solutions are found by searching for a distortion
%              transformation that match between the template and
%              the observed spectra.
%              This is later used by sedm_wavecalib.m to solve for
%              the wavelength calibration for all the segments.
%              This is an older version of sedm_abswavecalib.m that may be
%              usefull sometimes.
% Input  : * Arbitrary number of pairs of ...,key,val,.. arguments.
%            The following keywords are available:
%            'SI'    - Input SegmentsInfo structure array
%                      as returned by sedm_extract_spexcell.m after it
%                      was run on an ARC image. 
%                      If a string is provided then will assume this is
%                      a mat file containing a structure.
%                      This parameter must be provided.
%            'Template' - Wavelength calibrated template.
%                      This can either a matrix [wave(nm), intensity],
%                      or a mat file name containing [wave(nm), intensity],
%                      or a lamp tempate name {'Hg','HgXe'}.
%                      This argument must be provided.
%            'GridVecX' - The X vector of grid points in which to
%                      find an absolute wavelength solution.
%                      Default is (400:400:1600).'.
%            'GridVecY' - The Y vector of grid points in which to
%                      find an absolute wavelength solution.
%                      Default is (400:400:1600).'.
%            'FunDispLam' - A function that describe the distortion
%                      transformation between the spectra.
%                      Default is @(K,Pix,K1) K1.*K(1).^(Pix) + K(2).*(Pix).^2;
%            'MinFun' - The function that is minimized in order to find
%                      the wavelength solution.
%                      Default is @sedm_wavelength_xcorr.
%            'Plot'  - Plot the matched spectra {false|true}.
%                      Default is false.
%            'SpecField' - The field name in SegmentsInfo from which to
%                      get the spectrum. Default is 'SpexSpecFit'.
%            'RefineWaveCalib' - Refine wavelength calibration by 
%                      matching spectral lines {true|false}.
%                      Default is true.
%            'MaxLinesDist' - Maximum distance in nm between the matched
%                      lines. Default is 6.
%            'PolyDeg' - Degree of polynomial used in the line matching.
%                      Default is 2.
%            'LowerK' - Vector of lower bounds on the free parameters
%                      of the distortion transformation.
%                      Default is [ 0.997.*239./240 -0.001].
%            'UpperK' - Vector of upper bounds on the free parameters
%                      of the distortion transformation.
%                      Default is [ 1.003.*239./240 +0.001].
%            'GuessK' - Vector of best guess for the free parameters
%                      of the distortion transformation.
%                      Default is [ 239./240 0].
%            'VecK1' - Values of the K1 parameters to test.
%                      Default is [1100:1:1300].'
% Output : - Structure array containing information about the absolute
%            calibration of the desired spexcell in the grid points.
%            The following fields
%            are available:
%            .Arc_BestCorr
%            .Arc_BestK
%            .Arc_BestK1
%            .WaveCalib
%            .NumberMatchedLines
%            .Resid_WaveCalibLines
%            .RMS_WaveCalibLines
%            .RefinedWaveCalib
%            .BestWaveCalib
%            .CalibSpec - The calibrated spectrum of the segment.
%            .Iseg      - The segment ID which was used in the calibration.
%            .Xpos      - The grid point X position
%            .Ypos      - The grid point Y position
% Tested : Matlab R2011b
%     By : Eran O. Ofek                    Aug 2013
%    URL : http://weizmann.ac.il/home/eofek/matlab/
% Example: sedm_abswavecalib1('SI',ArcSegmentsInfo(1130))
% Reliable: 2
%--------------------------------------------------------------------------



DefV.SI              = [];
DefV.Template        = 'HgXe';
DefV.GridVecX        = 1024; %(400:400:1600).';
DefV.GridVecY        = 1024; %(400:400:1600).';
DefV.FunDispLam      = @(K,Pix,K1) K1.*K(1).^(Pix) + K(2).*(Pix).^2; % + K(3);
DefV.MinFun          = @sedm_wavelength_xcorr;
DefV.Plot            = false;
DefV.SpecField       = 'SpexSpecFit';   % spectrum field to use in SegmentsInfo
DefV.RefineWaveCalib = true;
DefV.MaxLinesDist    = 6;   % [nm]
DefV.PolyDeg         = 2;   % wavelength refinment polynomial order
DefV.LowerK          = [0.994  -0.0005]; %[ 0.997.*239./240 -0.001 ];
DefV.UpperK          = [0.9965 +0.002]; %[ 1.003.*239./240 +0.001 ];
DefV.GuessK          = [0.995 +0.0008]; %[ 239./240 0 ];
DefV.VecK1           = (1100:10:1300).';  % use to be [1100:1:1300].'; 
    
InPar = set_varargin_keyval(DefV,'y','use',varargin{:});


if (isempty(InPar.Template)),
    error('Template argument must be provided');
end

% read SegmentsInfo
if (isempty(InPar.SI)),
    error('SegmentsInfo (SI) must be provided');
end
if (ischar(InPar.SI)),
    SegmentsInfo = load2(InPar.SI);
else
   SegmentsInfo = InPar.SI;
   InPar = rmfield(InPar,'SI');
end

% Grid of X/Y positions at which to calibrate the tarces
[GridMatX,GridMatY] = meshgrid(InPar.GridVecX,InPar.GridVecY);


%------------------------------------------------------------------------
%--- Find initial solution for wavecalib in each spexcell using xcorr ---
%------------------------------------------------------------------------

if (ischar(InPar.Template)),
    switch lower(InPar.Template)
        case 'hg'
            load RefSpectrum.mat
            % pix, intensity, wavelength(nm)
            CalibratedRefSpectrum = RefSpectrum.Hg;
            RefSpecInt    = CalibratedRefSpectrum(:,2);
            CalRefSpecPix = CalibratedRefSpectrum(:,3);
        case 'hgxe'
            load RefSpectrum.mat
             CalibratedRefSpectrum = RefSpectrum.HgXe;
             RefSpecInt    = CalibratedRefSpectrum(:,2);
             CalRefSpecPix = CalibratedRefSpectrum(:,3);
         otherwise
             CalRefSpec = load2(InPar.Template);
             CalRefSpecPix = CalRefSpec(:,1);
             RefSpecInt    = CalRefSpec(:,2);
     end
else
     CalRefSpecPix = InPar.Template(:,1);
     RefSpecInt    = InPar.Template(:,2);
end     
        

switch lower(InPar.RefineWaveCalib)
    case true
        % find lines in ref spec

        [RefLineList]=find_contrast_peaks(flipud(CalRefSpecPix),...
                                          flipud(RefSpecInt),10);
    case false
        % do nothing
    otherwise
        error('Unknown RefineWaveCalib option');
end



if (InPar.Plot),
   subplot1(numel(InPar.GridVecX),numel(InPar.GridVecY));
end

MeanX = [SegmentsInfo.MeanX].';
MeanY = [SegmentsInfo.MeanY].';

if (isempty(InPar.GridVecX)),
    % instead of grid use the positions around each spexcell
    NgridPt = numel(SegmentsInfo);
else
    NgridPt = numel(GridMatX);
end

%for Iseg=1:1:Nseg,
for Igrid=1:1:NgridPt,
    if (isempty(InPar.GridVecX)),
        % instead of grid use the positions around each spexcell
        Iseg = Igrid;
        Xpos = SegmentsInfo(Iseg).MeanX;
        Ypos = SegmentsInfo(Iseg).MeanY;
    else
        Xpos = GridMatX(Igrid);
        Ypos = GridMatY(Igrid);
        [~,Iseg] = min(plane_dist(Xpos,Ypos,MeanX,MeanY));
    end
    
    %---
    SpecPix = (1:1:length(SegmentsInfo(Iseg).(InPar.SpecField))).';
    SpecInt = SegmentsInfo(Iseg).(InPar.SpecField).';
       
    BestCorr = 1;
    for Ik1=1:1:length(InPar.VecK1),
        K1 = InPar.VecK1(Ik1);
        [BestK,NegCorr]=fminsearch_my({InPar.MinFun,[SpecPix, SpecInt],[CalRefSpecPix, RefSpecInt],K1,InPar.FunDispLam,InPar.LowerK,InPar.UpperK},InPar.GuessK);
        if (NegCorr<BestCorr),
            BestCorr = NegCorr;
            BestBestK = BestK;
            BestK1 = K1;
        end
    end
    
    AbsCalib(Igrid).Arc_BestCorr = BestCorr;
    AbsCalib(Igrid).Arc_BestK    = BestBestK;
    AbsCalib(Igrid).Arc_BestK1   = BestK1;

    % try to refine using lines
    SpecWave = InPar.FunDispLam(BestBestK,SpecPix,BestK1);
    AbsCalib(Igrid).WaveCalib = SpecWave;
    switch lower(InPar.RefineWaveCalib)
       case true
            [LineList]=find_contrast_peaks(flipud(SpecWave),...
                                           flipud(SpecInt),8);

            LinesCounter = 0;
            %clear MatchedLines;
            MatchedLines = zeros(size(RefLineList,1),2).*NaN;                                            

            for Irll=1:1:size(RefLineList,1),
                Dist = RefLineList(Irll,1) - LineList(:,1);
                Ill = find(abs(Dist)<InPar.MaxLinesDist);
                if (~isempty(Ill)),
                    LinesCounter = LinesCounter + 1;    
                    if (length(Ill)>1),
                        % if more than one line - choose highest (rather
                        % than nearest).
                        [~,MaxIll] = max(LineList(Ill,2));
                        Ill = Ill(MaxIll);
                    end
                    MatchedLines(Irll,:) = [RefLineList(Irll,1), LineList(Ill,1)];
                end
            end
            %MatchedLines
            Ilnn = find(~isnan(MatchedLines(:,2)));
            AbsCalib(Igrid).NumberMatchedLines = length(Ilnn);
            ParWR = polyfit(MatchedLines(Ilnn,2),...
                            MatchedLines(Ilnn,1)-MatchedLines(Ilnn,2),InPar.PolyDeg);
            AbsCalib(Igrid).ParWR = ParWR;
            
            RMS = std(polyval(ParWR,MatchedLines(Ilnn,2))  - (MatchedLines(Ilnn,1)-MatchedLines(Ilnn,2)));
            AbsCalib(Igrid).Resid_WaveCalibLines = polyval(ParWR,MatchedLines(Ilnn,2))  - (MatchedLines(Ilnn,1)-MatchedLines(Ilnn,2));
            AbsCalib(Igrid).RMS_WaveCalibLines = RMS;
            AbsCalib(Igrid).RefinedWaveCalib = polyval(ParWR,AbsCalib(Igrid).WaveCalib);
            
        case false
            AbsCalib(Igrid).RefinedWaveCalib = zeros(size(AbsCalib(Igrid).WaveCalib));

    end
    AbsCalib(Igrid).BestWaveCalib   = AbsCalib(Igrid).WaveCalib + AbsCalib(Igrid).RefinedWaveCalib;

    AbsCalib(Igrid).CalibSpec = [AbsCalib(Igrid).BestWaveCalib, SegmentsInfo(Iseg).(InPar.SpecField)'];
    AbsCalib(Igrid).Iseg      = Iseg;
    AbsCalib(Igrid).Xpos      = Xpos;
    AbsCalib(Igrid).Ypos      = Ypos;

    if (InPar.Plot),
        subplot1(Igrid);
        plot(AbsCalib(Igrid).BestWaveCalib,SpecInt,'r-')
        hold on;
        plot(CalRefSpecPix, RefSpecInt)    
        drawnow
    end
end
