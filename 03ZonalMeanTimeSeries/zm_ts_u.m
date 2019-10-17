clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate data for zonal mean time series plot comparing years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir   = [LocalDataDir,'/corwin/ssw_airs/'];
Settings.LatBand   = [-65,-55];
Settings.Altitudes = [30,35,40,45,50];
Settings.Years     = 2002:1:2019;
Settings.Vars      = {'u','v'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create results storage arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results = NaN(numel(Settings.Vars),      ...
              numel(Settings.Altitudes), ...
              numel(Settings.Years),     ...
              365);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% main loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iYear=1:1:numel(Settings.Years)
  
  textprogressbar(['Processing ',num2str(Settings.Years(iYear)),' '])
  for iDay=1:1:365;
    textprogressbar(iDay./365.*100)
    
    %locate relevant ERA5 file
    FilePath = era5_path(datenum(Settings.Years(iYear),1,iDay));
    if ~exist(FilePath); continue; end

    %load and produce height axis
    Data = cjw_readnetCDF(FilePath);
    Data.Prs = ecmwf_prs_v2([],137);
    Data.Z = p2h(Data.Prs);
    
    %find data in latitude band
    InLatRange = inrange(Data.latitude,Settings.LatBand);
    
    %loop over levels, extract data, take mean, store
    for iLevel=1:1:numel(Settings.Altitudes) 
      idx = closest(Data.Z,Settings.Altitudes(iLevel));
      for iVar=1:1:numel(Settings.Vars)
      
      
        Var = Data.(Settings.Vars{iVar});
        Var = squeeze(Var(:,:,idx,:));
        Var = nanmean(Var,3);
        Var = Var(:,InLatRange);
      
        if strcmp(Settings.Vars{iVar},'theta') == 1;
          Results(iVar,iLevel,iYear,iDay) = circ_mean(Var(:));
        else
          Results(iVar,iLevel,iYear,iDay) = nanmean(Var(:)); 
        end
      end
    end
    
    
  end
  textprogressbar('!')
end


save('zm_ts_uv.mat','Results')

