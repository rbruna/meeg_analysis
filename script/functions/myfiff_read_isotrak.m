function dig = myfiff_read_isotrak ( filename )


% Defines the FIFF constants.
FIFF = fiff_define_constants;

% Reads the FIFF header.
[ fid,  tree ] = fiff_open ( filename );
isotrak = fiff_dir_tree_find ( tree, FIFF.FIFFB_ISOTRAK );




% FIFF.FIFFV_POINT_CARDINAL = 1
% FIFF.FIFFV_POINT_HPI      = 2
% FIFF.FIFFV_POINT_EEG      = 3
% FIFF.FIFFV_POINT_ECG      = FIFF.FIFFV_POINT_EEG
% FIFF.FIFFV_POINT_EXTRA    = 4





dig=struct('kind',{},'ident',{},'r',{},'coord_frame',{});
coord_frame = FIFF.FIFFV_COORD_HEAD;
if length ( isotrak ) == 1
    p = 0;
    for k = 1: isotrak.nent
        kind = isotrak.dir(k).kind;
        pos  = isotrak.dir(k).pos;
        if kind == FIFF.FIFF_DIG_POINT
            p = p + 1;
            tag = fiff_read_tag(fid,pos);
            dig(p) = tag.data;
        elseif kind == FIFF.FIFF_MNE_COORD_FRAME
            tag = fiff_read_tag(fid,pos);
            coord_frame = tag.data;
        elseif kind == FIFF.FIFF_COORD_TRANS
            tag = fiff_read_tag(fid,pos);
            dig_trans = tag.data;
        end
    end
end
for k = 1:length(dig)
    dig(k).coord_frame = coord_frame;
end

if exist('dig_trans','var')
    if (dig_trans.from ~= coord_frame && dig_trans.to ~= coord_frame)
        clear('dig_trans');
    end
end
