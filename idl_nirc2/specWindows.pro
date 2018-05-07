;+
; NAME:
;    specWindows, inputFile, Astar, startPixel, stopPixel, windowSize
;
;
; PURPOSE:
;    This program uses the input file to get a spatial projection. A
;    1D spectrum is then extracted from the input file for each
;    window between the start pixel and stop pixel. The spectrum is
;    divided by the A star telluric correction spectrum. 
;
;
; CALLING SEQUENCE:
;    specWindows, inputFile, Astar, starPixel, stopPixel, windowSize
;
;
; INPUTS:
;    inputList -- a file containing a list of 2D spectrum in the first
;                 column and the
;                 output prefix in the 3rd column. For each input
;                 file, a set of 1D spectra will be extracted
;    Astar -- telluric correction A star spectrum
;    startPixel -- the starting pixel in the spatial profile
;                  (0 based) for which to begin the spectral
;                  extraction. 
;    stopPixel -- the stopping pixel in the spatial profile (0 based)
;                 for which to end the spectral extraction
;    windowSize -- the number of pixels over which to extract and
;                  combine spectra.
;
; OUTPUTS:
;    A series of 1D spectra named <outputPrefix>_#.fits
;
;
;-

pro specWindows, input, Astar, startPix, stopPix, windowSize

on_error, 2
!p.color = 0
!p.background = 16777215

; This is for NIRC2 data and assumes certain directions (spatial and
; spectral) 

Astar = readfits(Astar, Ahdr)
readcol, input, names, outPrefix, format="a,a"

numSpectra = floor((stopPix - startPix) / windowSize)

for ii=0, n_elements(names)-1 do begin
    spec2d = readfits(names[ii], hdr)
    
    specLength = n_elements( spec2d[*,0] )
    

    for jj=0, numSpectra do begin
        pix1 = startPix + (jj*windowSize)
        pix2 = pix1 + windowSize - 1

        specLength = n_elements( spec2d[*,0] )

        spec1d = total( spec2d[*, pix1:pix2], 2 ) / windowSize
        spec1d = spec1d / Astar

        filename = outPrefix[ii] + "_" + $
                   strcompress(string(jj),/remove_all) + $
                   ".fits"
        writefits, filename, spec1d, hdr
    endfor
endfor

stop
end
