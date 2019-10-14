clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
subplot = @(m,n,p) subtightplot(m,n,p,0.03,0.03,0.03);
Settings.Year = 2002;

Settings.Altitude = 40; %km

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%get data and rearrange struct to suit my needs
Data = load(['maps_',num2str(Settings.Year),'.mat']);

[~,zidx] = min(abs(Data.Settings.Levels - Settings.Altitude));

Fields = fieldnames(Data.Results);
for iField = 1:1:numel(Fields)
  a = Data.Results.(Fields{iField});
  a = squeeze(a(zidx,:,:,:,1));
  Data.(Fields{iField}) = a;
end; clear Fields iField
Data = rmfield(Data,'Results');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



for iDN = 1:1:numel(Data.Settings.TimeRange)

  %get data
  ToPlot = Data.A;
  ToPlot = ToPlot(:,:,iDN);
  TheDay = Data.Settings.TimeRange(iDN);
    
  %duplicate end point
  ToPlot(end,:) = ToPlot(1,:);
      
  %prepare panel
  subplot(4,8,iDN)
  
  %generate axes
  m_proj('stereographic','lat',-90,'long',0,'radius',50);
    
  %plot data
  ToPlot(ToPlot < 0.6) = 0.6;
  m_contourf(Data.Settings.LonScale, Data.Settings.LatScale, ...
             ToPlot',0.6:0.05:3.0,'edgecolor','none');
  shading flat
    
  m_coast('color','k','linewi',1);
  m_grid('xtick',[],'ytick',[]);
    
  %colour map and bar
  colormap(flipud(cbrewer('div','RdYlBu',24)))
  %       colormap(cbrewer('seq','YlOrRd',12))
  caxis([0.6 3.0])
  
  title(datestr(TheDay))
    
    %done
    drawnow
    
    
    
    
end; clear iDN
