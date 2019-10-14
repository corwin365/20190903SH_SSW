%  clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.TimeRange = datenum(THEYEAR,9,1):1:datenum(THEYEAR,9,3);
Settings.Levels    = [30,40,50];%25:5:55;
Settings.Vars      = {'A','k','l'};

Settings.DataDir = [LocalDataDir,'/corwin/ssw_airs'];

Settings.LatScale =  -90:1:-30;
Settings.LonScale = -180:1:180;

Settings.OutFile = ['maps_',num2str(THEYEAR),'.mat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create results arrays (and other stuff needed generally)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%results arrays
for iVar=1:1:numel(Settings.Vars)
  
  Results.(Settings.Vars{iVar}) = NaN(numel(Settings.Levels),    ...
                                      numel(Settings.LonScale),  ...
                                      numel(Settings.LatScale),  ...
                                      numel(Settings.TimeRange), ...
                                      2); %the 2 is day or night
end

%mapping coords
[xi,yi] = meshgrid(Settings.LonScale,Settings.LatScale);

%loop-internal storage
DayStore = NaN(numel(Settings.Vars)+3, ...  %the +3 is for DN, lat and lon
               240,90,135,             ...
               numel(Settings.Levels));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% core loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iDay=1:1:numel(Settings.TimeRange)
  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% load and process data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  textprogressbar(['Loading and transforming ',datestr(Settings.TimeRange(iDay)),': '])


  File = [Settings.DataDir,'/st_airs_',num2str(Settings.TimeRange(iDay)),'.mat'];
  if ~exist(File); clear File; continue; end
  
  Data = load(File); Data = Data.Results;
  if ~isfield(Data,'Z'); Data.Z = [21,24,27,30,33,36,39,42,45,48,51,54,57,60]; end %oops


  
  for iGranule=1:1:240;
    textprogressbar(iGranule./240.*100)
 
    %find the data we want, and store
    for iVar=1:1:numel(Settings.Vars)+3
      
      %get variables
      if iVar <= numel(Settings.Vars);      
        
        VarData = Data.(Settings.Vars{iVar});
        VarData = squeeze(VarData(iGranule,:,:,:));

        %store for each level
        for iLevel=1:1:numel(Settings.Levels)
          %find level
          idx = closest(Data.Z,Settings.Levels(iLevel));
          %store
          DayStore(iVar,iGranule,:,:,iLevel) = VarData(:,:,idx);
        end; clear iLevels
        
      %geolocation
      elseif iVar == numel(Settings.Vars)+1; VarData = squeeze(Data.Lon(iGranule,:,:));
        DayStore(iVar,iGranule,:,:,1) = VarData;
      elseif iVar == numel(Settings.Vars)+2; VarData = squeeze(Data.Lat(iGranule,:,:));
        DayStore(iVar,iGranule,:,:,1) = VarData;        
      elseif iVar == numel(Settings.Vars)+3; VarData = squeeze(Data.DN(iGranule,:,:));
        DayStore(iVar,iGranule,:,:,1) = VarData;                
      end
      

    end; clear iVar VarData
    
    clear Airs ST Error ErrorInfo Spacing
  end; clear iGranule
  textprogressbar('!')
  
  clear idx
  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% bin and store data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if nansum(DayStore(:)) == 0; 
    disp('No data this day; skipping splitting and binning')
    continue; 
  end %don't waste time binning  
  
  textprogressbar(['Splitting and binning ',datestr(Settings.TimeRange(iDay)),':   '])  
  
  Lon     = flatten(DayStore(numel(Settings.Vars)+1,:,:,:,     1));
  Lat     = flatten(DayStore(numel(Settings.Vars)+2,:,:,:,     1));   
  DN      = flatten(DayStore(numel(Settings.Vars)+3,:,:,:,     1));
       
  
  for iVar=1:1:numel(Settings.Vars)
    textprogressbar(iVar ./ numel(Settings.Vars) .* 100)
  
    for iLevel=1:1:numel(Settings.Levels)
      
      ThisVar = flatten(DayStore(iVar,:,:,:,iLevel));
      if nansum(ThisVar(:)) == 0; continue; end %don't waste time binning
       
      zzN = bin2matN(2,Lon(DN == 0),Lat(DN == 0),ThisVar(DN == 0),xi,yi,'@nanmedian');
      zzD = bin2matN(2,Lon(DN == 1),Lat(DN == 1),ThisVar(DN == 1),xi,yi,'@nanmedian');

      Res = Results.(Settings.Vars{iVar});
      Res(iLevel,:,:,iDay,1) = zzN';
      Res(iLevel,:,:,iDay,2) = zzD';      
     
      Results.(Settings.Vars{iVar}) = Res;
      
      clear ThisVarzzN zzD Res
      
    end; clear iLevel
  end; clear iVar  Lon Lat DN 
  textprogressbar('!')  
  
  %reinitialise
  DayStore = DayStore.*NaN;
  
  %save every so often
  if mod(iDay,5) == 0;  save(Settings.OutFile,'Settings','Results','-v7.3'); end

      
  
end; clear iDay DayStore xi yi

save(Settings.OutFile,'Settings','Results','-v7.3')
