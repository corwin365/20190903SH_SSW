clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir = [LocalDataDir,'/ERA5/'];
Settings.Days    = date2doy([datenum(2002,9,1):1:datenum(2002,9,30)]);
Settings.Years   = 2002:1:2019;
Settings.LatScale =  -90:5:-30;
Settings.LonScale = -180:5:180;

Settings.OutFile = 'stratopause_era5.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%create results arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[xi,yi] = meshgrid(Settings.LonScale,Settings.LatScale);

Results = NaN(numel(Settings.Years),    ...
              numel(Settings.Days),     ...
              numel(Settings.LonScale), ...
              numel(Settings.LatScale));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%process
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iYear=1:1:numel(Settings.Years)
  textprogressbar(['Processing ',num2str(Settings.Years(iYear)),': '])
  for iDay=1:1:numel(Settings.Days)
    textprogressbar(iDay./numel(Settings.Days).*100)
    
    
    %find data for this day
    EcmwfFile = [Settings.DataDir,sprintf('%04d',Settings.Years(iYear)),'/', ...
                 'era5_',sprintf('%04d',Settings.Years(iYear)), ...
                 'd',sprintf('%03d',Settings.Days(iDay)),'.nc'];
               
    if ~exist(EcmwfFile,'file'); continue; end
    
    Data = cjw_readnetCDF(EcmwfFile);
    Data.Z = p2h(ecmwf_prs_v2([],137));
    
    %pull out region of interest, and take daily mean
    InLatRange = inrange(Data.latitude, [min(Settings.LatScale),max(Settings.LatScale)],1);
    InLonRange = inrange(Data.longitude,[min(Settings.LonScale),max(Settings.LonScale)],1);  
    
    T   = nanmean(Data.t(InLonRange,InLatRange,:,:),4);
    Lon = Data.longitude(InLonRange);
    Lat = Data.latitude( InLatRange);
    [Lon,Lat] = meshgrid(Lon,Lat);

    
    %find stratopause using method of https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2011JD016893
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %reshape data to make it easier to work with
    sz = size(T);
    T = reshape(T,sz(1)*sz(2),sz(3));
    
    %interpolate to fixed height scale of 1km
    NewZ = 1:1:80;
    T = interp1(Data.Z,T',NewZ)';
    
    %pull out height range stratopause could be in
    InHeightRange = inrange(NewZ,[20,80],1);
    T = T(:,InHeightRange);
    NewZ  = NewZ(InHeightRange);
    
    %apply 11km boxcar smoother
    T = smoothn(T,[1,11]);
    
    %find height of maximum
    [~,maxidx] = max(T,[],2);
    StratoPause  = NewZ(maxidx);

    clear Data
    clear T NewZ InHeightRange maxidx InLonRange InLatRange

    %reshape and store
    StratoPause = reshape(StratoPause,sz(1),sz(2))';
   
    %and grid onto the map
    zz = bin2matN(2,Lon(:),Lat(:),StratoPause(:),xi,yi,'@mode');
    
    %store
    Results(iYear,iDay,:,:) = zz';
    clear zz StratoPause

    
  end; clear iDay
  textprogressbar('!') 
  
  save(Settings.OutFile,'Settings','Results');
end; clear iYear

