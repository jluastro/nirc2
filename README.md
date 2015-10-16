This package provides a reduction pipepline for images from the
NIRC2 instrument on the Keck II telescope at the W. M. Keck
Observatory.


### POST INSTALL NOTES

IRAF doesn't like long filenames. Be sure to modify

`nirc2/data/directory_aliases.txt`

to add your own aliases. You will notice this is an
issue during the nirc2.reduce.combine() process with
error messages stating that temp files don't exist.



