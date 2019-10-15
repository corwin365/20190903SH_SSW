clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot zonal mean time series of GW properties from AIRS 
%
%Corwin Wright, c.wright@bath.ac.uk, 14/OCT/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%where is the data?
Settings.DataFile = 'zm_ts.mat';

%smooth?
Settings.SmoothSize = 7; %days

%what var?
Settings.VarName = 'A';

%what height?
Settings.HeightLevel = 40; %km

%years to highlight. years and colours must correspond
Settings.SpecialYears   = [2002,2019];
Settings.SpecialColours = [1,0,0;
                           0,0,1];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
Data = load(Settings.DataFile);

%temporary
Data.Settings.DataDir   = [LocalDataDir,'/corwin/ssw_airs/'];
Data.Settings.LatBand   = [-65,-55];
Data.Settings.Altitudes = [30,35,40,45,50];
Data.Settings.Years     = 2002:1:2019;
Data.Settings.Vars      = {'A','kh','theta'};

%select var
VarId = find(strcmp(Data.Settings.Vars,Settings.VarName));
Data.Results = squeeze(Data.Results(VarId,:,:,:));
clear VarId

%select height
zidx = closest(Data.Settings.Altitudes,Settings.HeightLevel);
Data.Results = squeeze(Data.Results(zidx,:,:));
clear zidx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
hold on
xlim(datenum(2002,1,[120 305]))
datetick('x','dd/mmm','keeplimits')


for iYear=1:1:numel(Data.Settings.Years)
  
  %choose colour
  if ismember(Data.Settings.Years(iYear),Settings.SpecialYears)
    %use special colour
    idx = closest(Settings.SpecialYears,Data.Settings.Years(iYear));
    Colour = Settings.SpecialColours(idx,:);
    clear idx    
  else
    %default to grey
    Colour = [1,1,1].*0.6;
  end
  
  %get data and smooth
  TheLine = Data.Results(iYear,:);
  Bad = find(isnan(TheLine));
  TheLine = smooth(TheLine,Settings.SmoothSize);
  TheLine(Bad) = NaN;
  
  %fill small gaps
  
  
  %plot the line
  plot(datenum(2002,1,1:1:365),TheLine, ...
       'color',Colour,'linewi',2)
  
  %done!  
  drawnow
end