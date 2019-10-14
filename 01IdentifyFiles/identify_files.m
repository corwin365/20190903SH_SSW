clear all
warning off

OutPath = '/home/f/cw785/scratch/Data/AIRS/3d_airs/';

for Day=datenum(2004,6,1):1:datenum(2018,12,31)

  %only upload if we're in May, June,July, August, September,October
  [~,m,~] = datevec(Day);
  if m<5 | m > 10
    disp([datestr(Day),' is out-of-season; skipping'])
    continue
  end
  

  %ok, main loop.
  DayMade = 0;
  
  
  textprogressbar(['Uploading ', datestr(Day),'   '])
  for iGranule=1:1:240;
  textprogressbar(iGranule./240.*100)
    
    %load granule and get geolocation
    [Airs,~,Error] = prep_airs_3d(Day,iGranule,'LoadOnly',true);
    
    %check if load was successful
    if Error ~=0; continue; end
    
    %identify mean latitude of granule
    latmean = nanmean(Airs.l1_lat(:));
    
    %if the mean latitude is poleward of 30S, then work out how to upload it
    if latmean > -30; continue; end
    
    dn = date2doy(Day);
    [y,~,~] = datevec(Day);
    
    
    %if it's the first file to go up this day, create the path
    if DayMade == 0;
      Command = ['ssh cw785@balena ''mkdir ',OutPath,'/',sprintf('%04d',y),''''];
      [~, ~] = system(Command)
      Command = ['ssh cw785@balena ''mkdir ',OutPath,'/',sprintf('%04d',y),'/',sprintf('%03d',dn),''''];
      [~, ~] = system(Command) 
      DayMade = 1;
    end    
    
    %now, generate the SCP command for the file
    InFile = Airs.Source;
    OutFile = [OutPath, ...
               sprintf('%04d',y),'/',  ...
               sprintf('%03d',dn),'/', ...
               'airs_', ...
               sprintf('%04d',y),'_',  ...
               sprintf('%03d',dn),'_', ...
               sprintf('%03d',iGranule),'.nc'];
    
    Command = ['scp ',InFile,' balena:',OutFile];
    [~, ~] = system(Command)
    
    
    
  end
  textprogressbar('!')
end
