function resliced = my_volumereslice ( cfg, mri )
% Based on FiedTrip functions:
% * ft_volumereslice by Robert Oostenveld & Jan-Mathijs Schoffelen
% * scale by Robert Oostenveld
% * translate by Robert Oostenveld

% FT_VOLUMERESLICE interpolates and reslices a volume along the
% principal axes of the coordinate system according to a specified
% resolution.
%
% Use as
%   mri = ft_volumereslice(cfg, mri)
% where the input mri should be a single anatomical or functional MRI
% volume that was for example read with FT_READ_MRI.
%
% The configuration structure can contain
%   cfg.resolution = number, in physical units
%   cfg.xrange     = [min max], in physical units
%   cfg.yrange     = [min max], in physical units
%   cfg.zrange     = [min max], in physical units
% or alternatively with
%   cfg.dim        = [nx ny nz], size of the volume in each direction
%
% If the input mri has a coordsys-field, the centre of the volume will be
% shifted (with respect to the origin of the coordinate system), for the
% brain to fit nicely in the box.
%
% To facilitate data-handling and distributed computing you can use
%   cfg.inputfile   =  ...
%   cfg.outputfile  =  ...
% If you specify one of these (or both) the input data will be read from a *.mat
% file on disk and/or the output data will be written to a *.mat file. These mat
% files should contain only a single variable, corresponding with the
% input/output structure.
%
% See also FT_VOLUMEDOWNSAMPLE, FT_SOURCEINTERPOLATE

% Undocumented local options:
%   cfg.downsample

% Copyright (C) 2010-2013, Robert Oostenveld & Jan-Mathijs Schoffelen
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id: ft_volumereslice.m 9858 2014-09-27 10:01:45Z roboos $

% check if the input data is valid for this function and ensure that the structures correctly describes a volume
if isfield(mri, 'inside')
  mri = ft_checkdata( mri, 'datatype', 'volume', 'feedback', 'no', 'hasunit', 'yes', 'inside', 'logical' );
else
  mri = ft_checkdata( mri, 'datatype', 'volume', 'feedback', 'no', 'hasunit', 'yes' );
end

% Checks that the mri only has rotation over the edges.
if any ( any ( abs ( mri.transform ( 1: 3, 1: 3 ) ) < 1e-6 & abs ( mri.transform ( 1: 3, 1: 3 ) ) ~= 0 ) )
    warning ( 'Discarding negligible rotations in the transformation matrix.' );
    rotation = mri.transform ( 1: 3, 1: 3 );
    rotation ( abs ( rotation ) < 1e-6 ) = 0;
    mri.transform ( 1: 3, 1: 3 ) = rotation;
end
if ~all ( ( sum ( ( mri.transform ( 1: 3, 1: 3 ) ~= 0 ) ) == 1 ) & ( sum ( ( mri.transform ( 1: 3, 1: 3 )' ~= 0 ) ) == 1 ) )
    error ( 'This function requires data to be aligned with the axes of the volume.' );
end

% The function does not resample the data.
if isfield ( cfg, 'resolution' )
    error ( 'This function does not allow resolution changing. Use ''ft_volumereslice'' instead.' );
end
if isfield ( cfg, 'downsample' )
    error ( 'This function does not allow downsampling. Use ''ft_volumereslice'' instead.' );
end
if isfield ( cfg, 'xrange' )
    error ( 'This function does not allow to define ranges. Use ''ft_volumereslice'' instead.' );
end
if isfield ( cfg, 'yrange' )
    error ( 'This function does not allow to define ranges. Use ''ft_volumereslice'' instead.' );
end
if isfield ( cfg, 'zrange' )
    error ( 'This function does not allow to define ranges. Use ''ft_volumereslice'' instead.' );
end

% Sets the defaults.
cfg.xstart     = ft_getopt ( cfg, 'xstart', [] );
cfg.ystart     = ft_getopt ( cfg, 'ystart', [] );
cfg.zstart     = ft_getopt ( cfg, 'zstart', [] );
cfg.dim        = ft_getopt ( cfg, 'dim',    [ 256 256 256 ] );


% Extracts the MRI resolution of each dimension.
cfg.resolution = abs ( sum ( mri.transform ( 1: 3, 1: 3 ), 2 ) );


% Sets the origin in the center of the image.
xshift = 0;
yshift = 0;
zshift = 0;

% Shifts the origin for the different coordinate systems.
if isfield ( mri, 'coordsys' )
    switch mri.coordsys
        case { 'ctf' '4d' 'bti' }
            xshift = 30 / cfg.resolution (1);
            yshift = 0;
            zshift = 40 / cfg.resolution (3);
            
        case { 'itab' 'neuromag' }
            xshift = 0;
            yshift = 30 / cfg.resolution (2);
            zshift = 40 / cfg.resolution (3);
            
        case { 'myneuromag' }
            xshift = 0;
            yshift = 0;
            zshift = 40 / cfg.resolution (3);
            
        otherwise
            xshift = 0;
            yshift = 0;
            zshift = 15 / cfg.resolution (3);
    end
end


% Sets the minimum position for each axis.
if isempty(cfg.xstart)
    cfg.xstart = -( cfg.dim (1) / 2 - 0.5 ) * cfg.resolution (1) + xshift;
end
if isempty(cfg.ystart)
    cfg.ystart = -( cfg.dim (2) / 2 - 0.5 ) * cfg.resolution (2) + yshift;
end
if isempty(cfg.zstart)
    cfg.zstart = -( cfg.dim (3) / 2 - 0.5 ) * cfg.resolution (3) + zshift;
end

% Makes sure that the image starts in a complete pixel.
cfg.xstart = cfg.xstart + rem ( cfg.xstart, cfg.resolution (1) );
cfg.ystart = cfg.ystart + rem ( cfg.ystart, cfg.resolution (2) );
cfg.zstart = cfg.zstart + rem ( cfg.zstart, cfg.resolution (3) );

% % Computes the new grid.
% xgrid = cfg.xstart + ( 0: cfg.dim (1) - 1 ) * cfg.resolution (1);
% ygrid = cfg.ystart + ( 0: cfg.dim (2) - 1 ) * cfg.resolution (2);
% zgrid = cfg.zstart + ( 0: cfg.dim (3) - 1 ) * cfg.resolution (3);


% % fprintf ( 1, 'Reslicing image from [%d %d %d] to [%d %d %d].\n', mri.dim, resliced.dim );
% 
% % Creates a dummy MRI with the required dimensions.
% resliced           = mri;
% resliced.dim       = cfg.dim;
% resliced.anatomy   = zeros ( resliced.dim, 'uint16' );
% 
% % Creates the new transformation matrix.
% resliced.transform = translate  ( [ cfg.xstart cfg.ystart cfg.zstart ] ) * scale ( cfg.resolution ) * translate ( [ -1 -1 -1 ] );
% 
% % Transforms the original MRI to fit the required dimensions.
% tmpcfg = [];
% tmpcfg.parameter    = 'anatomy';
% tmpcfg.interpmethod = 'nearest';
% resliced            = ft_sourceinterpolate ( tmpcfg, mri, resliced );
% resliced.anatomy ( ~isfinite ( resliced.anatomy ) ) = 0;



% Modifies the volume to achieve an identity-like rotation matrix.
[ order, ~ ] = find ( mri.transform ( 1: 3, 1: 3 ) );
% mri.transform ( :, 1: 3 ) = mri.transform ( :, order );
% mri.anatomy  = permute ( mri.anatomy, order );
% mri.dim      = mri.dim ( order );
mri.transform ( :, order ) = mri.transform ( :, 1: 3 );
mri.anatomy  = ipermute ( mri.anatomy, order );
mri.dim  ( order )     = mri.dim;

% Mirrors the dimensions where the rotation is 180 degrees.
mirror       = find ( any ( mri.transform ( 1: 3, 1: 3 ) < 0 ) );
for dim = 1: numel ( mirror )
    
    mri.anatomy  = flipdim ( mri.anatomy, mirror ( dim ) );
    
    % Gets the new scaling and traslation.
    newscale = -mri.transform ( mirror ( dim ), mirror ( dim ) );
    newtrans = mri.transform ( mirror ( dim ), 4 ) - ( mri.dim ( mirror ( dim ) ) + 1 ) * newscale;
    mri.transform ( mirror ( dim ), mirror ( dim ) ) = newscale;
    mri.transform ( mirror ( dim ), 4 ) = newtrans;
    
end
% cfg.xstart = -cfg.xstart;


% Creates a dummy MRI with the required dimensions.
resliced           = mri;
resliced.dim       = cfg.dim;

% Creates the new transformation matrix.
resliced.transform = translate  ( [ cfg.xstart cfg.ystart cfg.zstart ] ) * scale ( cfg.resolution ) * translate ( [ -1 -1 -1 ] );

% Gets the three-dimensional shiftings.
shifts             = ( mri.transform ( 1: 3, 4 ) - resliced.transform ( 1: 3, 4 ) ) ./ cfg.resolution;
shifts             = round ( shifts );

% Copies the MRI matrix to the output and shifts it.
resliced.anatomy   = zeros ( max ( cfg.dim (:), mri.dim (:) )' + abs ( shifts (:) )' );
resliced.anatomy ( 1: mri.dim (1), 1: mri.dim (2), 1: mri.dim (3) ) = mri.anatomy;
resliced.anatomy   = circshift ( resliced.anatomy, shifts );

% Keeps only the usefull data.
resliced.anatomy   = resliced.anatomy ( 1: cfg.dim (1), 1: cfg.dim (2), 1: cfg.dim (3) );



function H = scale ( f )

H = diag ( cat ( 1, f (:), 1 ) );


function H = translate ( f )

H = eye (4);
H ( 1: 3, 4 ) = f;
