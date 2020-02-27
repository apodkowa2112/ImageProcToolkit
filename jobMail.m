function jobMail(subject,msg)
% JOBMAIL Send an email at end of job
% function jobMail(subject,msg)

   email = 'tpodkow2@illinois.edu';
   if ~exist('subject','var')
      subject = 'Matlab Job Done';
   end
   if ~exist('msg','var')
      msg = 'Job ended at ';
      msg = [msg datestr(now)];
   end

   cmd = sprintf('echo ''%s'' | mail -s ''%s'' %s',msg, subject, email);
   system(cmd);

end
