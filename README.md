This package provides a reduction pipepline for images from the
NIRC2 instrument on the Keck II telescope at the W. M. Keck
Observatory.

### Dependencies

The NIRC2 reduction pipeline depends on IRAF and must be run
in a python 2.7 environment. We recommend Astroconda with IRAF
install.

Unfortunately, there are some legacy IDL functions needed by the
pipeline (strehl calculator). You will need to add the
<nirc2_dir>/idl_nirc2 directory to your IDL path.

### POST INSTALL NOTES


IRAF doesn't like long filenames. Be sure to modify

`nirc2/data/directory_aliases.txt`

to add your own aliases. You will notice this is an
issue during the nirc2.reduce.combine() process with
error messages stating that temp files don't exist.



