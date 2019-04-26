;+
; NAME:
;    cmd_strehl_widget
;
; PURPOSE:
;    Run the strehl widget tool created by Marcos van Dam to calculate
;    strehls from a NIRC2 image as a command line tool. This program
;    really just provides a simple way to set up the variables and
;    pass them to cmdstrehl.
;
; INPUTS:
;   file  - The file number or file containing a list of files that
;           cmdstrehl should be run on.
;           If file is a number, it will be padded with the
;           appropriate amount of 0s to conform to NIRC2's naming scheme.
;           (Both n####.fits and c####.fits are tried.)
;   /list - Indicates that file argument given is a file that contains
;           a list of files to run cmdstrehl on (with or without .fits
;           extension).
;   /autofind - Run on the brightest peak in the image. Without
;               autofind, cmdstrehl looks for a corresponding .coord
;               file for each image file. (DEFAULT = autofind off)
;               Do not run on frames with saturated sources!
;   output - Set output equal to the name of a file you want to
;            contain the output. (must be a string)
;   apersize - The aperture size (in arcsec) to be used for photometry
;              (DEFAULT = 1") 
;   /silent - Suppress output (except for errors) to the screen.
;   /holo  - Run strehl widget on speckle holography PSF
;
;  EXAMPLES:
;   cmd_strehl_widget,139,/auto
;      -Run strehl widget on n0139.fits and autofind the highest peak
;   cmd_strehl_widget,'imlist',/list,output='cmd_strehl_widget.txt',/silent
;      -Run strehl widget (silently) on all files contained in
;      imlist. Look for corresponding *.coord for each file in the
;      list. Put output in file cmd_strehl_widget.txt.
;
; MODIFICATION HISTORY:
;    2006/05/10 - Written by Seth Hornstein
;
;    06/01/2006 - code unification path change
;                 @/home/jlu/work/idl/lib/NIRC2/strehl_calc/strehl_data_struc_default.pro      
;                 modified to
;                 @/u/speckle/code/idl/NIRC2/strehl_calc/strehl_data_struc_default.pro
;    06/01/2006 - code unification path change again
;                 modified to simple file... should look in IDL path to find.
;                 @strehl_data_struc_default
;
;    12/14/2011 - added holo flag, which should be specified if using
;                 speckle holography
;-
PRO cmd_strehl_widget, file, list=list, autofind=autofind, output=output, $
                       apersize=apersize, silent=silent, holo=holo

IF N_PARAMS(0) eq 0 THEN BEGIN
    print,"% CMD_STREHL_WIDGET - Calculate strehl on NIRC2 images from the command line"
    print,"% Usage: cmd_strehl_widget, file [,/LIST] [,/AUTO] [,/SILENT] [,/HOLO]"
    print,"       [,OUTPUT=] [,APERSIZE=] [,GAUSSOBX=]"
    RETALL
ENDIF

;Set up strehl data structure
@strehl_data_struc_default

if KEYWORD_SET(list) then strehl.list = file else strehl.im1=file
if KEYWORD_SET(autofind) then strehl.autofind=1 else strehl.autofind=0 
if KEYWORD_SET(output) then strehl.output = output
if KEYWORD_SET(apersize) then strehl.photon_radius=apersize
if KEYWORD_SET(silent) then strehl.silent = 1
if KEYWORD_SET(holo) then strehl.holo = 1

strehl=cmdstrehl(strehl)

end



