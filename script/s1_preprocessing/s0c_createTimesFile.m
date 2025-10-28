clc
clear 
close all

config.path.in = '../../data/tsss/';   % Path to postTsss files
config.path.out = '../../meta/meg/';
if ~exist (config.path.out, 'dir'), mkdir (config.path.out); end

files = dir(config.path.in);
files = {files.name}';
files(~contains(files, '.fif')) = [];                                  

cont = 1;
for ifile = 1:numel(files)
   
        times(cont).subject   = files{ifile}(1:6); % Modificar según nombre proyecto (cambiará el numero de caracteres del nombre del archivo).
        times(cont).task      = files{ifile}(8);                        % 'EC' y 'EO'. Ver si diferencia '2EC' o '4EC', para concatenar todos ECs.
        times(cont).stage     = 'run1';                                     % run1, misma sesion ( pre-post, o longitudinales, etc).
        times(cont).dataset = files{ifile};
        times(cont).begtime = NaN;  %Modificar dependiendo de la TAREA
        times(cont).endtime = NaN;  %Modificar dependiendo de la TAREA
        cont = cont + 1;
end

save (fullfile(config.path.out, 'times.mat'), 'times')