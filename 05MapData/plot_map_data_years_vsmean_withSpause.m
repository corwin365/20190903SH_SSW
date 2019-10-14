clearvars


Strato  = load('../06FindStratopause/stratopause_mls.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.Altitude = 40; %km
Settings.Vars = {'A'};%,'k','l'};
Settings.TimeOfDay = 1; %1 night, 2 day

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Settings.Years = 2002:1:2018;

for iYear = 1:1:numel(Settings.Years);
  
  
  %get data and rearrange struct to suit my needs
  Data = load(['maps_',num2str(Settings.Years(iYear)),'.mat']);
  Settings.TimeRange = [datenum(Settings.Years(iYear),8,30),datenum(Settings.Years(iYear),9,30)];
  
  Fields = fieldnames(Data.Results);
  for iField = 1:1:numel(Fields)
    Data.(Fields{iField}) = Data.Results.(Fields{iField});
  end; clear Fields iField
  Data = rmfield(Data,'Results');
  
  %convert wavenumber to wavelength
  Data.k = 1./Data.k; Data.k(abs(Data.k) > 2000) = NaN;
  Data.l = 1./Data.l; Data.l(abs(Data.l) > 2000) = NaN;  
  
  %find level, extract time range, and take time-mean over it
  zidx = closest(Data.Settings.Levels,Settings.Altitude);
  tidx = find(Data.Settings.TimeRange >= min(Settings.TimeRange) ...
            & Data.Settings.TimeRange <= max(Settings.TimeRange));
  
  for iVar=1:1:numel(Settings.Vars)
    Field = Data.(Settings.Vars{iVar});
    Field = permute(nanmean(Field(zidx,:,:,tidx,Settings.TimeOfDay ),4),[2,3,5,1,4]);
    Data.(Settings.Vars{iVar}) = Field;
  end; clear iVar zidx tidx Field
  
 
  % %remove small values
  % Bad = find(Data.A < .6);
  % Data.A(Bad) = NaN;
  % Data.k(Bad) = NaN;
  % Data.l(Bad) = NaN;
  
  
  %store
  for iVar=1:1:numel(Settings.Vars)
    Store(iVar,:,:,iYear) = Data.(Settings.Vars{iVar});
  end
  
  
  
  
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% normalise
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

TimeMean = nanmean(Store,4);
for iYear=1:1:numel(Settings.Years)
  Store(:,:,:,iYear) = Store(:,:,:,iYear) ./ TimeMean;
  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
subplot = @(m,n,p) subtightplot(m,n,p,0.03,0.03,0.03);



kount = 0;
for iYear = 1:1:numel(Settings.Years);
    for iVar=1:1:numel(Settings.Vars)
      
      %get data
      ToPlot = squeeze(Store(iVar,:,:,iYear));
      
      %duplicate end point
      ToPlot(end,:) = ToPlot(1,:);
      
      %logerate
      ToPlot = log2(ToPlot);
      
      %smooth
      ToPlot = smoothn(ToPlot,[1,1].*3);
        
      %prepare panel
      kount = kount + 1;
      subplot(3,ceil(numel(Settings.Years)./3),kount)
      
      %generate axes
      m_proj('stereographic','lat',-90,'long',0,'radius',50);
      
% %       %plot data
% %       m_pcolor(Data.Settings.LonScale, Data.Settings.LatScale,ToPlot')
               
               
      ToPlot(ToPlot < -.8) = -.8;
      m_contourf(Data.Settings.LonScale, Data.Settings.LatScale, ...
                 ToPlot',-.8:0.1:.8,'edgecolor','none');
      shading flat
      hold on
      
      %overplot the stratopause height
      [c,h] = m_contour(Strato.Settings.LonScale, ...
                        Strato.Settings.LatScale, ...
                        squeeze(nanmean(Strato.Results(iYear,:,:,:),2))', ...
                        35:3:75,'edgecolor','k','linewi',.5);

       clabel(c,h);
      
      
      
      m_coast('color',[1,1,1].*0.5,'linewi',1);
      m_grid('xtick',[],'ytick',[]);
      
      %colour map and bar
      colormap(flipud(cbrewer('div','RdYlBu',24)))
%       colormap(cbrewer('seq','YlOrRd',12))
      colorbar
      caxis([-1 1].*.8)
      
      title(Settings.Years(iYear))
      
      
      
      
      
      %done
      drawnow
      
      
      
      
    end; clear iVar
end
