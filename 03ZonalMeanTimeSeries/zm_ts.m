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
Settings.Vars      = {'A','kh','theta','Mz','Mm','MF','m'};

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
    try
      %find and load file for day
      DayFile = [Settings.DataDir,'/st_airs_',num2str(datenum(Settings.Years(iYear),1,iDay)),'.mat'];
      if ~exist(DayFile,'file'); continue; end
      Data = load(DayFile); Data = Data.Results;
      
      %oops
      if ~isfield(Data,'Z');
        Data.Z = [21,24,27,30,33,36,39,42,45,48,51,54,57,60];
      end
      
      %other vars that aren't in the files
      Data.kh    = quadadd(Data.k,Data.l);
      Data.theta = atan2(Data.l,Data.k);
      
      sz = size(Data.kh);
      Prs = permute(repmat(h2p(Data.Z),1,sz(1),sz(2),sz(3)),[2,3,4,1]);
      Data.Mz = -1000.*cjw_airdensity(Prs,Data.T)./2 .* (9.81/0.02).^2 .* (Data.A./Data.T).^2 .* (Data.k./Data.m);
      Data.Mm = Data.Mz .* (Data.l ./ Data.k);
      Data.MF = quadadd(Data.Mm,Data.Mz);
      
      clear sz Prs
      
      %find data in latitude band
      InLatRange = inrange(Data.Lat,Settings.LatBand);
      
      %loop over levels, extract data, take mean, store
      for iLevel=1:1:numel(Settings.Altitudes)
        idx = closest(Data.Z,Settings.Altitudes(iLevel));
        for iVar=1:1:numel(Settings.Vars)
          
          
          Var = Data.(Settings.Vars{iVar});
          Var = squeeze(Var(:,:,:,idx));
          Var = Var(InLatRange);
          
          if strcmp(Settings.Vars{iVar},'theta') == 1;
            Results(iVar,iLevel,iYear,iDay) = circ_mean(Var(:));
          else
            Results(iVar,iLevel,iYear,iDay) = nanmean(Var(:));
          end
        end
      end
      
    catch;
    end
    end
  textprogressbar('!')
  save('zm_ts.mat','Results','Settings')
end


save('zm_ts.mat','Results','Settings')

