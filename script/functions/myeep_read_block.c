#include <string.h>
#include <math.h>
#include "mex.h"
#include "matrix.h"
#include <stdint.h>
#include "c3n_raweep.h"


void mexFunction ( int nlhs, mxArray * plhs [], int nrhs, const mxArray * prhs [] ) {
    
    mxUint8 *byte;
    mxInt32 *data;
    mxUint64 nchan, nsamp, *ooff;
    mxInt64 off = 0;
    
    mwSize dims;
    const mwSize *size;
    mwSize bsize;
    
    
    /* Checks the inputs. */
    if ( nrhs < 3 || nrhs > 4 ) mexErrMsgTxt ( "Invalid number of arguments." );
    if ( !mxIsInt8 ( prhs [0] ) && !mxIsUint8 ( prhs [0] ) ) mexErrMsgTxt ( "This function only accepts byte data as input." );
    
    /* Gets the data size. */
    dims   = mxGetNumberOfDimensions ( prhs [0] );
    size   = mxGetDimensions ( prhs [0] );
    bsize  = size [0] * size [1];
    /*if ( dims != 1 ) mexErrMsgTxt ( "This function requires a vector as input." );*/
    
    /* Gets the input variables. */
    byte   = mxGetData ( prhs [0] );
    nsamp  = mxGetScalar ( prhs [1] );
    nchan  = mxGetScalar ( prhs [2] );
    if ( nrhs > 3 )
        off   = mxGetScalar ( prhs [3] );
    
    
    /* Creates the output variables. */
    plhs [0] = mxCreateNumericMatrix ( nsamp, nchan, mxINT32_CLASS, false );
    plhs [1] = mxCreateNumericMatrix ( 1, 1, mxUINT64_CLASS, false );
    data   = mxGetData ( plhs [0] );
    ooff   = mxGetData ( plhs [1] );
    
    
    /* Reads the data block. */
    off    = read_block ( data, byte, off, nsamp, nchan );
    
    /* Handles the errors, if any. */
    if ( off < 1 ) {
        if ( off == -1 )
            mexErrMsgTxt ( "Invalid compression method." );
        
        if ( off == -2 )
            mexErrMsgTxt ( "The compression method for the first channel cannot be inter-channel residuals (method 3/11)." );
    }
    
    
    /* Returns the current offset as an output. */
    ooff [0] = off;
}
