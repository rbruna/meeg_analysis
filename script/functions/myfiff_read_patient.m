function info = myfiff_read_patient ( filename )


% Defines the FIFF constants.
FIFF = fiff_define_constants;

% Reads the FIFF header.
[ fid,  tree ] = fiff_open ( filename );
pattree = fiff_dir_tree_find ( tree, FIFF.FIFFB_SUBJECT );

if isempty ( pattree )
    pattree (1).dir.kind = nan;
end

% Reads the patient information.
if any ( [ pattree.dir.kind ] == 400 )
    tag = fiff_read_tag ( fid, pattree.dir ( [ pattree.dir.kind ] == 400 ).pos );
    info.id   = tag.data;
else
    info.id   = [];
end
if any ( [ pattree.dir.kind ] == 401 )
    tag = fiff_read_tag ( fid, pattree.dir ( [ pattree.dir.kind ] == 401 ).pos );
    info.fname = tag.data;
else
    info.fname = [];
end
if any ( [ pattree.dir.kind ] == 402 )
    tag = fiff_read_tag ( fid, pattree.dir ( [ pattree.dir.kind ] == 402 ).pos );
    info.mname = tag.data;
else
    info.mname = [];
end
if any ( [ pattree.dir.kind ] == 403 )
    tag = fiff_read_tag ( fid, pattree.dir ( [ pattree.dir.kind ] == 403 ).pos );
    info.lname = tag.data;
else
    info.lname = [];
end
if any ( [ pattree.dir.kind ] == 404 )
    tag = fiff_read_tag ( fid, pattree.dir ( [ pattree.dir.kind ] == 404 ).pos );
    info.bday = tag.data;
else
    info.bday = [];
end
if any ( [ pattree.dir.kind ] == 405 )
    tag = fiff_read_tag ( fid, pattree.dir ( [ pattree.dir.kind ] == 405 ).pos );
    info.sex = tag.data;
else
    info.sex = [];
end
