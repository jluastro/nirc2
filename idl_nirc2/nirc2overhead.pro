;+
; NAME:
;    nirc2overhead
;
;
; PURPOSE:
;    Calculate the total elapsed observing time for a series of
;    exposures. 
;
;
; CALLING SEQUENCE:
;    nirc2overhead, itime, coadds, dithers, frames, reads, [/subarray]
;
;
; INPUTS:
;    itime - Integration time per coadd (seconds)
;    coadds - Number of coadds for a single image
;    dithers - Number of dithers (e.g. bxy9 has 9 dithers)
;    frames - Number of frames to take at each dither position
;             (e.g. bxy5 5 5 n=2 has 2 at each position)
;    reads - Number of reads for a particular sampmode (e.g. sampmode
;            2 has 2 reads, sampmode 3 16 has 16 reads)
;    /subarray - Calculate for a 512x512 subarray instead of the full
;                1024x1024 array.
;
; EXAMPLE:
;    nirc2overhead, 0.181, 60, 9, 2, 2
;
;
; MODIFICATION HISTORY:
;    2005/06/27 -- Written by Jessica Lu. Formula from NIRC2 manual.
;-
pro nirc2overhead, itime, coadds, dithers, frames, reads, subarray=subarray
    if (n_params(0) EQ 0) then begin
        print, 'CALLING SEQUENCE:'
        print, '    nirc2overhead, itime, coadds, dithers, frames, reads, [/subarray]'
        print, '           dithers should be the TOTAL number of dithers'
	print, '               (inculding a home move if there is one.)'
        print, '           frames  should be the TOTAL number of frames taken'
        print, '           /subarray means 512x512 array size'
        retall
    endif


    if (KEYWORD_SET(subarray)) then tread=0.053 else tread=0.181
    ; Calculate the total elapsed observing time for 
    ; a set of exposures
;The NIRC2 manual has the following (wrong) equation
;    t = (6.0*(dithers+1.0))
;    t = t + (12.0*dithers*frames)
;    t = t + (dithers*frames*coadds*(itime + tread*(reads-1)))

;This accurately takes care of the number of dithers and number of frames
    t = (6.0*(dithers))
    t = t + (12.0*frames)
    t = t + (frames*coadds*(itime + tread*(reads-1)))

    tmin = t / 60.0

    t = round(t)
    
    print, format='(%"\tIntegration time: %f")', itime
    print, format='(%"\tNumber of Coadds: %d")', coadds
    print, format='(%"\tNumber of Dithers: %d")', dithers
    print, format='(%"\tFrames at each Dither: %d")', frames
    print, format='(%"\tNumber of Reads: %d")', reads
    print, format='(%"Total elapsed observing time = %5d sec (or %5.1f min)")', $
           t, tmin
end
