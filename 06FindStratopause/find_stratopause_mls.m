clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir = [LocalDataDir,'/MLS/L2/'];
Settings.Days    = date2doy([datenum(2002,9,1):1:datenum(2002,9,30)]);
Settings.Years   = 2002:1:2019;
Settings.LatScale =  -90:5:-30;
Settings.LonScale = -180:20:180;

Settings.OutFile = 'stratopause_mls.mat';

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
    MlsFile = wildcardsearch([Settings.DataDir,sprintf('%04d',Settings.Years(iYear)),'/']  , ...
                             ['*d',sprintf('%03d',Settings.Days(iDay))]);
    if numel(MlsFile) == 0; continue; end
    MlsFile = MlsFile{1};
    Data = get_MLS(MlsFile,'Temperature');
    
    Z = p2h(Data.Pressure);
    T = Data.L2gpValue;
    Lon = Data.Longitude;
    Lat = Data.Latitude;
    clear Data
       
    %find stratopause using method of https://agupubs.onlinelibrary.wiley.com/doi/full/10.1029/2011JD016893
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    %interpolate to fixed height scale of 1km
    NewZ = 1:1:100;
    T = interp1(Z,T,NewZ)';


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

   
    %and grid onto the map
    zz = bin2matN(2,Lon(:),Lat(:),StratoPause(:),xi,yi,'@mode');
    
    zz = inpaint_nans(zz); %only a few points per day
    
    %store
    Results(iYear,iDay,:,:) = zz';
    clear zz StratoPause

    
  end; clear iDay
  textprogressbar('!') 
  
  save(Settings.OutFile,'Settings','Results');
end; clear iYear

