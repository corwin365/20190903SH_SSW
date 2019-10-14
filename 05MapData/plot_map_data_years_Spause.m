clearvars


% Strato  = load('../06FindStratopause/stratopause_era5.mat');
% Strato  = load('../06FindStratopause/stratopause_era5_plustwoweeks.mat');
Strato  = load('../06FindStratopause/stratopause_mls.mat');
Levels = 42:1:52;

Settings.Years = 2002:1:2019;


% MeanS = repmat(nanmean(Strato.Results,1),18,1,1,1);
% Strato.Results = Strato.Results - MeanS;
% Levels = -4:.5:4;


Strato.Results = -Strato.Results;
Levels = -Levels;
% stop
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
subplot = @(m,n,p) subtightplot(m,n,p,0.03,0.03,0.03);



kount = 0;
for iYear = 1:1:numel(Settings.Years);
  
  
  %prepare panel
  kount = kount + 1;
  subplot(3,ceil(numel(Settings.Years)./3),kount)
  
  %generate axes
  m_proj('stereographic','lat',-90,'long',0,'radius',50);

  %overplot the stratopause height
  ToPlot = squeeze(nanmean(Strato.Results(iYear,:,:,:),2));
  %duplicate end point
  ToPlot(end,:) = ToPlot(1,:);
  
  %plot
  ToPlot(ToPlot < min(Levels)) = min(Levels);
  [c,h] = m_contourf(Strato.Settings.LonScale, ...
    Strato.Settings.LatScale, ...
    ToPlot', ...
    Levels,'edgecolor','none');
  
  clabel(c,h);
  
  
  
        m_coast('color',[1,1,1].*0.5,'linewi',1);
  m_grid('xtick',[],'ytick',[]);
  
  %colour map and bar
  colormap(flipud(cbrewer('div','RdYlBu',24)))
% colormap(cbrewer('seq','YlOrRd',12))
  colorbar
  caxis([min(Levels) max(Levels)])
  
  title(Settings.Years(iYear))
  
  
  
  
  
  %done
  drawnow
  
  
  
end
