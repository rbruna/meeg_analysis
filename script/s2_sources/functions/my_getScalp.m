function scalp = my_getScalp ( mri )

% Extracts the scalp voxels as probabilities.
scalp         = mri.anatomy;

% Smooths the anatomy and selects the bigger continuous element.
scalp         = volumesmooth    ( scalp, 5 );
scalp         = volumethreshold ( scalp, 0.1 );

% Fills holes in the anatomy in all three dimensions.
scalp1        = volumefillholes ( scalp, 1 );
scalp2        = volumefillholes ( scalp, 2 );
scalp3        = volumefillholes ( scalp, 3 );
scalp         = scalp1 | scalp2 | scalp3;



function [output] = volumesmooth(input, fwhm)

% VOLUMESMOOTH is a helper function for segmentations
%
% See also VOLUMETHRESHOLD, VOLUMEFILLHOLES

% Private function from FieldTrip 20200130.

% check for any version of SPM
if ~ft_hastoolbox('spm')
  % add SPM8 to the path
  ft_hastoolbox('spm8', 1);
end

% don't touch the input, make a deep copy
output = input+0;
% the mex files underneath the spm function will change the input variable
spm_smooth(output, output, fwhm);


function [output] = volumethreshold(input, thresh)

% VOLUMETHRESHOLD is a helper function for segmentations. It applies a
% relative threshold and subsequently looks for the largest connected part,
% thereby removing small blobs such as vitamine E capsules.
%
% See also VOLUMEFILLHOLES, VOLUMESMOOTH

% Private function from FieldTrip 20200130.

% check for SPM8 or later, add to the path if not present
ft_hastoolbox('spm8up', 1);

% mask by taking the negative of the segmentation, thus ensuring
% that no holes are within the compartment and do a two-pass
% approach to eliminate potential vitamin E capsules etc.

if ~islogical(input)
  output = double(input>(thresh*max(input(:))));
else
  % there is no reason to apply a threshold, but spm_bwlabel still needs a
  % double input for clustering
  output = double(input);
end

% cluster the connected tissue
[cluster, n] = spm_bwlabel(output, 6);

if n>1
  % it pays off to sort the cluster assignment if there are many clusters
  tmp = cluster(:);                       % convert to a vector
  tmp = tmp(tmp>0);                       % remove the zeros
  tmp = sort(tmp, 'ascend');              % sort according to cluster number
  m   = zeros(1,n);
  for k=1:n
    m(k) = sum(tmp==k);       % determine the voxel count for each cluster
    tmp  = tmp(m(k)+1:end);   % remove the last cluster that was counted
  end
  % select the tissue that has the most voxels belonging to it
  [m, i] = max(m);
  output = (cluster==i);
else
  % the output only contains a single cluster
  output = (cluster==1);
end


function [output] = volumefillholes(input, along)

% VOLUMEFILLHOLES is a helper function for segmentations
%
% See also VOLUMETHRESHOLD, VOLUMESMOOTH

% Private function from FieldTrip 20200130.

% check for any version of SPM
if ~ft_hastoolbox('spm')
  % add SPM8 to the path
  ft_hastoolbox('spm8', 1);
end

if nargin<2
  inflate = false(size(input)+2);                   % grow the edges along each dimension
  inflate(2:end-1, 2:end-1, 2:end-1) = (input~=0);  % insert the original volume
  [lab, num] = spm_bwlabel(double(~inflate), 18);   % note that 18 is consistent with imfill, 26 is not
  if num>1
    inflate(lab~=lab(1)) = true;
    output  = inflate(2:end-1, 2:end-1, 2:end-1);   % trim the edges
  else
    output = input;
  end
  
else
  output = input;
  dim    = size(input);
  switch along
    case 1
      for i=1:dim(1)
        slice=squeeze(input(i,:,:));
        im = imfill(slice,8,'holes');
        output(i,:,:) = im;
      end
      
    case 2
      for i=1:dim(2)
        slice=squeeze(input(:,i,:));
        im = imfill(slice,8,'holes');
        output(:,i,:) = im;
      end
      
    case 3
      for i=1:dim(3)
        slice=squeeze(input(:,:,i));
        im = imfill(slice,8,'holes');
        output(:,:,i) = im;
      end
      
    otherwise
      error('invalid dimension along which to slice the volume');
  end % switch
end % if nargin
