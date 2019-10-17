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
Settings.DataFile = 'zm_ts_uv.mat';

%smooth?
Settings.SmoothSize = 1; %days

%fill small gaps?
Settings.GapFill = 1; %days

%what var?
Settings.VarName = 'u';
Settings.VarTitle = 'zonal wind [m/s]';

%what height?
Settings.HeightLevel = p2h(10); %km

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
if ~isfield(Data,'Settings')
  Data.Settings.DataDir   = [LocalDataDir,'/corwin/ssw_airs/'];
  Data.Settings.LatBand   = [-65,-55];
  Data.Settings.Altitudes = [30,35,40,45,50];
  Data.Settings.Years     = 2002:1:2019;
  Data.Settings.Vars      = {'u','v'};
end

%select var
VarId = find(strcmp(Data.Settings.Vars,Settings.VarName));
Data.Results = squeeze(Data.Results(VarId,:,:,:));
clear VarId

%select height
zidx = closest(Data.Settings.Altitudes,Settings.HeightLevel);
Settings.HeightLevel = Data.Settings.Altitudes(zidx); %to be precise 
Data.Results = squeeze(Data.Results(zidx,:,:));
clear zidx





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(gcf,'color','w')
clf
hold on
xlim([datenum(2002,5,5),datenum(2002,11,25)])

datetick('x','dd/mmm','keeplimits')
set(gca,'tickdir','out','XMinorTick','on','YMinorTick','on')
box on; grid on;

%shade using non-special years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

NormalYears= find(~ismember(Data.Settings.Years,Settings.SpecialYears));
PatchY = NaN(365,7);%see below

TheMean = nanmean(Data.Results(NormalYears,:),1);
TheStd  = nanstd( Data.Results(NormalYears,:),1);

PatchY(:,1) = prctile(Data.Results(NormalYears,:),0);
PatchY(:,2) = prctile(Data.Results(NormalYears,:),5);
PatchY(:,3) = prctile(Data.Results(NormalYears,:),18);
PatchY(:,4) = nanmean(Data.Results(NormalYears,:),1);
PatchY(:,5) = prctile(Data.Results(NormalYears,:),82);
PatchY(:,6) = prctile(Data.Results(NormalYears,:),95);
PatchY(:,7) = prctile(Data.Results(NormalYears,:),100);
PatchY = smoothn(PatchY,[Settings.SmoothSize,1]);

x = 1:1:365;
Good = find(nansum(PatchY,2) ~= 0);
x = x(Good);
y = PatchY(Good,:);
clear PatchY TheMean TheStd NormalYears

%plot the background
patch(datenum(2002,1,[x,reverse(x)]),[y(:,1);reverse(y(:,7))]',[1,1,1].*0.9,'edgecolor','none');
patch(datenum(2002,1,[x,reverse(x)]),[y(:,2);reverse(y(:,6))]',[1,1,1].*0.8,'edgecolor','none');
patch(datenum(2002,1,[x,reverse(x)]),[y(:,3);reverse(y(:,5))]',[1,1,1].*0.6,'edgecolor','none');
plot(datenum(2002,1,x),y(:,4),'color','k','linestyle','-')

%plot special years
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iYear=1:1:numel(Settings.SpecialYears)

  %use special colour
  idx = find(Settings.SpecialYears(iYear) == Settings.SpecialYears);
  Colour = Settings.SpecialColours(idx,:);
  clear idx
  
  %get year of data
  idx = closest(Data.Settings.Years,Settings.SpecialYears(iYear));
  
  %get data
  TheLine = Data.Results(idx,:);
  
  %fill small gaps
  Filled = find(~isnan(TheLine));
  x = 1:1:365; x = x(Filled);
  if numel(Filled) == 0; continue; end
  TheLine = interp1gap(x,TheLine(Filled), ...
                       1:1:365,Settings.GapFill);  
  
  %smooth
  Bad = find(isnan(TheLine));
  TheLine = smooth(TheLine,Settings.SmoothSize);
  TheLine(Bad) = NaN;
  

  
  %plot the line
  plot(datenum(2002,1,1:1:365),TheLine, ...
       'color',Colour,'linewi',1)
  
  %done!  
  drawnow
end

ylabel(['Zonal mean ',Settings.VarTitle])

%add annotations
%%%%%%%%%%%%%%%%%%%%%%%%

text(0.02,0.95,'ERA5','Units','normalized')
text(0.02,0.90,['60S, z=',num2str(Settings.HeightLevel),'km'],'Units','normalized')
for iYear=1:1:numel(Settings.SpecialYears)
  text(0.02,0.90-0.05.*iYear,num2str(Settings.SpecialYears(iYear)), ...
       'Units','normalized', ...
       'color', Settings.SpecialColours(iYear,:), ...
       'fontweight','bold')
end
text(0.02,0.05,'Data supplied by Copernicus and ECMWF', ...
               'fontsize',8,'Units','normalized')
text(0.02,0.02,'Analysed and plotted by Corwin Wright, Univ. Bath', ...
               'fontsize',8,'Units','normalized')             
