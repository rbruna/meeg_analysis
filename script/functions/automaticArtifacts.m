function artifact = automaticArtifacts ( config )
% PREPROCESADO DE DATOS MEG RESTING .FIF  
% version 10 agosto 2012


%   Los registros de entrada son registros de resting state de duraci�n
%   y filtrados con tsss-mc. En el caso de que el filtro sea SSS es
%   necesario verificar si se ha registrado HcPI en la senal raw. De ser
%   asi los datos han de haberse filtrado [1,150] antes de realizar el
%   filtro SSS. Despues ya es posible emplear este script.

%   Todo esto basado en la funcion de Naza 'Preproc_Resting.m', en la que
%   se ha cambiado la parte de rechazo de artefactos debido a
%   incompatibilidades entre las diferentes versiones de Fieltrip.

%   Los datos son segmentados en fragmentos de t_frag'' mediante la funcion
%   trialfun_MCI_rest

%   El proceso consiste en:

%   1-  Se coge el .fif original y se segmenta en fragmentos mediante la
%       funcion trialfun_MCI_rest.
%   2-  Se detecta la posicion en los datos de tres tipos de
%       artefactos: Jump, Muscle y EOG. Esto es personalizable mediante
%       unos umbrales para los valores de la transformada z. Luego los
%       trials que contengan artefactos son descartados.
%   3-  Se realiza un filtrado (pasa banda y band stop), un demean,
%       detrean y correcion por linea base. Todo es personalizable en
%       la seccion de parametros.
%   4-  Se montaa la estructura con los trials finales y se guarda.

%   Los par�metros de entrada son:

%   fif_path:       Ruta completa del fichero fif.
%   path_out:       Ruta completa de los datos preprocesados.
%   preprocesado    Estructura con todos los datos necesarios para el
%                   preprocesado. Se configura en el script RLV

% Checks the data options.
if ~isfield ( config, 'eog'         ), config.eog         = 'EEG061'; end % 'EEGO61'
if ~isfield ( config, 'channel'     ), config.channel     = 'MEGMAG'; end % 'MEG' 'MEGMAG' 'MEGGRAD'
if ~isfield ( config, 'interactive' ), config.interactive = 'no';     end % 'yes' 'no'
if ~isfield ( config, 'artifacts'   ), config.artifacts   = [];       end
if ~isfield ( config, 'fprintoff'   ), config.fprintoff   = 0;        end

if ~isfield ( config.artifacts, 'eog'    ), config.artifacts.eog    = true; end
if ~isfield ( config.artifacts, 'jump'   ), config.artifacts.jump   = true; end
if ~isfield ( config.artifacts, 'muscle' ), config.artifacts.muscle = true; end

% Artifact detection parameters.

% Blink detection parameters.
eog.   remove      = config.lookfor.eog;
eog.   channel     = config.channel.eog;
eog.   interactive = config.interactive;
eog.   cut_zvalue  = 4;        %   Valor por defecto 4
eog.   trlpadding  = -config.padding;      %   Valor por defecto 0.5
eog.   fltpadding  = 0;     %   Valor por defecto 0.1  (Fragmento colaterales a los trials que se incluyen en el filtro)
eog.   artpadding  = 0.1;      %   Valor por defecto 0.1  (fragmento a cada lado del artefacto extra que elimina)

% Jump detection parameters.
jump.  remove      = config.lookfor.jump;
jump.  channel     = config.channel.jump;
jump.  interactive = config.interactive;
jump.  cut_zvalue  = 20;       %   20 en tutorial
jump.  trlpadding  = -config.padding;      %   Valor 0 por defecto.
jump.  fltpadding  = 0;      %   (Fragmento colaterales a los trials que se incluyen en el filtro)
jump.  artpadding  = 0.1;      %   Valor 0 por defecto.

% Muscular activity detection parameters.
muscle.remove      = config.lookfor.muscle;
muscle.channel     = config.channel.muscle;
muscle.interactive = config.interactive;
muscle.cut_zvalue  = 6;        %   8--> Naza antes || 4--> tutorial
muscle.trlpadding  = -config.padding;      %   Valor por defecto 0.1
muscle.fltpadding  = 0;      %   Valor por defecto 0.1
muscle.artpadding  = 0.1;      %   Valor por defecto 0.1

% Filtering parameters.
% opciones.bpf   = 'yes';        %   Se realiza un filtrado pasa banda a los trials ya limpios.
% opciones.fmin  = 1;            %   Frecuencia de corte inferior filtro pasa banda final.
% opciones.fmax  = 45;           %   Frecuencia de corte superior filtro pasa banda final.
% opciones.bsf   = 'no';         %   Se realiza un filtrado para eliminar componentes de la l�nea de tensi�n
% opciones.place = 'EU';         %   Zona donde se haya la MEG que ha generado el fif:
%                                %   ('EU' --> Europe (50 Hz))   Se filtra 50, 100 y 150 Hz.
%                                %   ('USA' --> USA (60 Hz))  Se filtra 60, 120 y 180 Hz.
% 
% opciones.demean  = 'yes';      %   Realiza un demean.
% opciones.detrend = 'yes';      %   Realiza un detrend.


% Trial definition for the artifact selection.
cfg = [];
cfg.begtime      = config.begtime;  %   Tiempo inicial del periodo de Resting
cfg.endtime      = config.endtime;  %   Tiempo final del periodo de resting
cfg.segment      = config.segment;  %   Fija la duracion de cada trial
cfg.padding      = config.padding;  %   Tiempo de padeo al inicio y el final del registro
cfg.addpadd      = config.addpadd;  %   Añade el padding como parte del trial.
cfg.equal        = config.equal;
cfg.trialfun     = config.trialfun; %   Usamos la funcion personalizada
cfg.dataset      = config.dataset;
cfg.precision    = 'single';
cfg.continuous   = 'yes';
cfg.feedback     = 'no';

% Gets the file header, if not provided.
if ~isfield ( config, 'header' )
    cfg.header = ft_read_header ( config.dataset );
else
    cfg.header = config.header;
end

% Defines the trial segmentation function.
trialfun  = str2func ( config.trialfun );

% Loads the MEG data at once and then segments it in trials.
% wholedata = ft_preprocessing ( cfg );
wholedata = my_read_data ( cfg );
% cfg       = ft_definetrial   ( cfg );
cfg.trl   = trialfun ( cfg );
trialdata = ft_redefinetrial ( cfg, wholedata );

% Initializes the artifact defintion.
artifact  = zeros ( 0, 2 );


% ARTIFACT REJECTION

% EOG ARTIFACTS

cfg = [];
cfg.continuous = 'yes';
cfg.feedback   = 'no';

% Channel selection, cutoff and padding.
cfg.artfctdef.zvalue.channel       = eog.channel;
cfg.artfctdef.zvalue.cutoff        = eog.cut_zvalue;
cfg.artfctdef.zvalue.trlpadding    = eog.trlpadding;
cfg.artfctdef.zvalue.artpadding    = eog.artpadding;
cfg.artfctdef.zvalue.fltpadding    = eog.fltpadding;

% % Algorithmic parameters.
% cfg.artfctdef.zvalue.bpfilter      = 'yes';
% cfg.artfctdef.zvalue.bpfilttype    = 'but';
% cfg.artfctdef.zvalue.bpfreq        = [ 1 15 ];
% cfg.artfctdef.zvalue.bpfreq        = [ 0 15 ];
% cfg.artfctdef.zvalue.bpfiltord     = 4;
% cfg.artfctdef.zvalue.hilbert       = 'yes';

% Algorithmic parameters.
cfg.artfctdef.zvalue.bpfilter      = 'yes';
cfg.artfctdef.zvalue.bpfilttype    = 'fir';
cfg.artfctdef.zvalue.bpfreq        = [ 5 15 ];
cfg.artfctdef.zvalue.bpfiltord     = 400;
cfg.artfctdef.zvalue.hilbert       = 'yes';

% Interactive artifact rejection.
cfg.artfctdef.zvalue.interactive   = eog.interactive;

if eog.   remove && ~isempty ( ft_channelselection ( cfg.artfctdef.zvalue.channel, trialdata.label ) )
    fprintf ( 1, '%s', repmat ( '  ', config.fprintoff, 1 ) );
    fprintf ( 1, '  Searching for blinks... ' );
    cfg             = ft_artifact_zvalue ( cfg, trialdata );
    drawnow
    artifact.eog    = cfg.artfctdef.zvalue;
else
    artifact.eog    = struct ( 'artifact', zeros ( 0, 2 )  );
end

% JUMP ARTIFACTS
cfg = [];
cfg.continuous = 'yes';
cfg.feedback   = 'no';

% Channel selection, cutoff and padding.
cfg.artfctdef.zvalue.channel    = jump.channel;
cfg.artfctdef.zvalue.cutoff     = jump.cut_zvalue;
cfg.artfctdef.zvalue.trlpadding = jump.trlpadding;
cfg.artfctdef.zvalue.fltpadding = jump.fltpadding;
cfg.artfctdef.zvalue.artpadding = jump.artpadding;

% Algorithmic parameters.
cfg.artfctdef.zvalue.cumulative    = 'yes';
cfg.artfctdef.zvalue.medianfilter  = 'yes';
cfg.artfctdef.zvalue.medianfiltord = 9;
cfg.artfctdef.zvalue.absdiff       = 'yes';

% Interactive artifact rejection.
cfg.artfctdef.zvalue.interactive   = jump.interactive;

if jump.  remove && ~isempty ( ft_channelselection ( cfg.artfctdef.zvalue.channel, trialdata.label ) )
    fprintf ( 1, '%s', repmat ( '  ', config.fprintoff, 1 ) );
    fprintf ( 1, '  Searching for jumps... ' );
    cfg             = ft_artifact_zvalue ( cfg, trialdata );
    drawnow
    artifact.jump   = cfg.artfctdef.zvalue;
else
    artifact.jump   = struct ( 'artifact', zeros ( 0, 2 ) );
end

% MUSCLE ARTIFACTS

cfg = [];
cfg.continuous = 'yes';
cfg.feedback   = 'no';

% Channel selection, cutoff and padding.
cfg.artfctdef.zvalue.channel       = muscle.channel;
cfg.artfctdef.zvalue.cutoff        = muscle.cut_zvalue;
cfg.artfctdef.zvalue.trlpadding    = muscle.trlpadding;
cfg.artfctdef.zvalue.fltpadding    = muscle.fltpadding;
cfg.artfctdef.zvalue.artpadding    = muscle.artpadding;

% Algorithmic parameters.
cfg.artfctdef.zvalue.bpfilter      = 'yes';
cfg.artfctdef.zvalue.bpfreq        = [ 110 140 ];   %   Realiza un filtro y despues realiza una transformada H.
cfg.artfctdef.zvalue.bpfiltord     = 5;             %   Valor por defecto 8
cfg.artfctdef.zvalue.bpfilttype    = 'but';
cfg.artfctdef.zvalue.hilbert       = 'yes';
cfg.artfctdef.zvalue.boxcar        = 0.2;           %   Promedio de la amplitud de la transformada H.

% Interactive artifact rejection.
cfg.artfctdef.zvalue.interactive   = muscle.interactive;

if muscle.remove && ~isempty ( ft_channelselection ( cfg.artfctdef.zvalue.channel, trialdata.label ) )
    fprintf ( 1, '%s', repmat ( '  ', config.fprintoff, 1 ) );
    fprintf ( 1, '  Searching for muscular artifacts... ' );
    cfg             = ft_artifact_zvalue ( cfg, trialdata );
    drawnow
    artifact.muscle = cfg.artfctdef.zvalue;
else
    artifact.muscle = struct ( 'artifact', zeros ( 0, 2 )  );
end
