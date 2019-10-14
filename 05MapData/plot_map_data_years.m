clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
subplot = @(m,n,p) subtightplot(m,n,p,0.03,0.03,0.03);


Settings.Years = 2002:1:2018;
kount = 0;
for iYear = 1:1:numel(Settings.Years);

  Settings.Altitude = 40; %km
  Settings.Vars = {'A'};%,'k','l'};
  Settings.TimeRange = [datenum(Settings.Years(iYear),8,30),datenum(Settings.Years(iYear),9,30)];
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% load and prep data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
  %get data and rearrange struct to suit my needs
  Data = load(['maps_',num2str(Settings.Years(iYear)),'.mat']);
  
  
  Fields = fieldnames(Data.Results);
  for iField = 1:1:numel(Fields)
    Data.(Fields{iField}) = Data.Results.(Fields{iField});
  end; clear Fields iField
  Data = rmfield(Data,'Results');
  
  %find level, extract time range, and take time-median over it
  zidx = closest(Data.Settings.Levels,Settings.Altitude);
  tidx = find(Data.Settings.TimeRange >= min(Settings.TimeRange) ...
    & Data.Settings.TimeRange <= max(Settings.TimeRange));
  
  for iVar=1:1:numel(Settings.Vars)
    Field = Data.(Settings.Vars{iVar});
    Field = permute(nanmean(Field(zidx,:,:,tidx,:),4),[2,3,5,1,4]);
    Data.(Settings.Vars{iVar}) = Field;
  end; clear iVar zidx tidx Field
  
  %convert wavenumber to wavelength
  Data.k = 1./Data.k; Data.k(abs(Data.k) > 2000) = NaN;
  Data.l = 1./Data.l; Data.l(abs(Data.l) > 2000) = NaN;
  
  % %remove small values
  % Bad = find(Data.A < .6);
  % Data.A(Bad) = NaN;
  % Data.k(Bad) = NaN;
  % Data.l(Bad) = NaN;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  

  for iDN = 1;%1;%[1,2]
    for iVar=1:1:numel(Settings.Vars)
      
      %get data
      ToPlot = Data.(Settings.Vars{iVar});
      ToPlot = ToPlot(:,:,iDN);
      
      %duplicate end point
      ToPlot(end,:) = ToPlot(1,:);
      
% %       %smooth
% %       ToPlot = smoothn(ToPlot,[1,1].*3);
        
      %prepare panel
      kount = kount + 1;
      subplot(3,ceil(numel(Settings.Years)./3),kount)
      
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
      colorbar
      caxis([0.6 3.0])
      
      title(Settings.Years(iYear))
      
      %done
      drawnow
      
      
      
      
    end; clear iVar
  end; clear iDN
end
