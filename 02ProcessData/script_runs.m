clearvars


%node runtime for a given instrument, minutes. programme wil select this.
%getting this right allows more parallel jobs to run inside balena group cputime limit
RunTime= 30;
NThreads = 16;
Partition = 'batch-short';

Count = 1;
for iYear=2002
  for iDay=301
    
    
    %generate identifying string
    YY  = sprintf('%02d',iYear-2000);
    DD  = sprintf('%03d',iDay);
    JobName = ['SSW_',YY,'_',DD];
    
    %set time and partition
    Time = num2str(RunTime);
    
    
    %generate call
    Text1 = ['#!/bin/bash\n## Name of the job\n#SBATCH --job-name=',JobName,'\n## Account to charge to\n#SBATCH --account=free\n\n'];
    Text2 = ['\n#SBATCH --time=',Time,':00\n## Number of node required and tasks per node\n'];
    Text3 = ['#SBATCH --nodes=1\n#SBATCH --ntasks-per-node=',num2str(NThreads),'\n\n#SBATCH --output=log.%%j.out\n#SBATCH --error=log.%%j.err\n#SBATCH --partition=',Partition];
    
    
    %Load Matlab environment
    Text4 = ['\n\n\nmodule load matlab'];
    Text5 = ['\nexport TZ="Europe/London"\nmatlab -nodisplay -r "maxNumCompThreads(',num2str(NThreads),');'];
    
    
    %i'm getting a problem with parallel pools not loading
    %I think it might be due to Balena trying too create many at the same time
    %so add a random wait of between 0-30 seconds to each script
    Wait = rand.*30;
    Commands = ['pause(',num2str(Wait),');'];
    
    %finally, set the date and call the processing script
    Commands = [Commands,';DATE = datenum(',num2str(iYear),',1,',num2str(iDay),');process_gws;'];
    
    Text6 = [';exit"'];
    
    fid = fopen(['job',sprintf('%04d',Count),'_wrapper.txt'],'wt');
    fprintf(fid, Text1);
    fprintf(fid, Text2);
    fprintf(fid, Text3);
    fprintf(fid, Text4);
    fprintf(fid, Text5);
    fprintf(fid, Commands);
    fprintf(fid, Text6);
    fclose(fid);
    
    Count = Count+1;
  end
end


%finally, generate a script file to fire the whole lot off
fid = fopen(['fire_jobs.sh'],'wt');
for i=1:1:Count-1;
%    fprintf(fid,['sbatch --dependency singleton job',sprintf('%04d',i),'_wrapper.txt\n']);   
  fprintf(fid,['sbatch job',sprintf('%04d',i),'_wrapper.txt\n']);     
  fprintf(fid,['rm job',sprintf('%04d',i),'_wrapper.txt\n']);    
end
fprintf(fid,['rm fire_jobs.sh\n']); 
fclose(fid);

disp(['Written ',num2str(Count),' files (probably)'])

