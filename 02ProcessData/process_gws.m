% % clearvars
% % 
% % %variables to be fed from Balena batch file
% % DATE = datenum(2008,1,127);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ST-process 3D AIRS GW data in the high southern hemisphere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.LatRange  = [-90,-30];
Settings.Date      = DATE; clear DATE

Settings.MinWaveLength =  [100,100,10];
Settings.MaxWaveLength =  [2000,2000,80];

Settings.OutFile = [LocalDataDir,'/corwin/ssw_airs/st_airs_',num2str(Settings.Date),'.mat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create results arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results.A    = single(NaN(240,90,135,14));
Results.k    = Results.A;
Results.l    = Results.A;

Results.Lon  = single(NaN(240,90,135));
Results.Lat  = Results.Lon;
Results.DN   = Results.Lon;

Results.Time = NaN(240,1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analysis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for iGranule=1:1:240;
  
  %attempt to load granule
  [Airs,Spacing,Error] = prep_airs_3d(Settings.Date,iGranule, ...
                                      'DayNightFlag',true, ...
                                      'PreSmooth',[3,3,1]);
  %error check
  if Error ~= 0; continue; end
  clear Error
  
  %check if we're in the right lat range
  latmean = nanmean(Airs.l1_lat(:));
  if latmean > max(Settings.LatRange); continue; end
  if latmean < min(Settings.LatRange); continue; end
  clear latmean
  
  %do GW analysis
  [ST,Airs,Error] = gwanalyse_airs_3d(Airs, ...
                                      'Spacing',       Spacing,                ...
                                      'MinWaveLength', Settings.MinWaveLength, ...
                                      'MaxWaveLength', Settings.MaxWaveLength);
  if Error ~= 0; continue; end
  clear Error
  
  %store
  Results.A(   iGranule,:,:,:) = ST.A;
  Results.k(   iGranule,:,:,:) = ST.k;
  Results.l(   iGranule,:,:,:) = ST.l;
  
  Results.Lat( iGranule,:,:) = Airs.l1_lat;
  Results.Lon( iGranule,:,:) = Airs.l1_lon;
  Results.DN(  iGranule,:,:) = Airs.DayNightFlag;
  
  Results.Time(iGranule) = nanmean(Airs.l1_time(:));
  Results.Z = Airs.ret_z;
  
 
end; clear iGranule

save(Settings.OutFile,'Results')