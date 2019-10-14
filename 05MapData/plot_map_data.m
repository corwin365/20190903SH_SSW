clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


Settings.Altitude = 30; %km
Settings.Vars = {'A'};%,'k','l'};
Settings.TimeRange = [datenum(2003,8,30),datenum(2003,9,30)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%get data and rearrange struct to suit my needs
Data = load('maps_2003.mat');


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

% % %remove small values
% % Bad = find(Data.A < .6);
% % Data.A(Bad) = NaN;
% % Data.k(Bad) = NaN;
% % Data.l(Bad) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


kount = 0;
for iDN = [1,2]
  for iVar=1:1:numel(Settings.Vars)
  
    %get data
    ToPlot = Data.(Settings.Vars{iVar});
    ToPlot = ToPlot(:,:,iDN);
  
    
    %prepare panel
    kount = kount + 1;
    subplot(2,numel(Settings.Vars),kount)
    
    %generate axes
    m_proj('stereographic','lat',-90,'long',0,'radius',50);
    
    
    %plot data
    m_pcolor(Data.Settings.LonScale, Data.Settings.LatScale, ...
             ToPlot');
    shading flat
    
    m_coast('color','k');
    m_grid();
    
    %colour map and bar
    colormap(flipud(cbrewer('div','RdYlBu',64)))
    colorbar
    
    %done
    drawnow
     
    
    
  
  end; clear iVar
end; clear iDN

