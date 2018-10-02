;+
; NAME:
;     extractSpec, inputFile, Astar 
;
;
; PURPOSE:
;     This program uses the input file to get a spatial
;     projection. These specified apertures are then extracted from
;     the input file to create a 1D spectrum where each line is
;     weighted by the flux at that pixel in the spatial profile
;     (essentially waiting by the spatial profile). This works for non
;     ideal profiles.
;
;
; INPUTS:
;     inputFile: a file where each line contains the following
;     information (<2D spec file> <starting line> <ending line>).
;
;
; OUTPUTS:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
;-


pro extractSpec, inputList

on_error,2
!p.color = 0
!p.background = 16777215

; This is for NIRC2 data and assumes certain directions (spatial and
; spectral)

fmt = '(a,a,i,i)'
readcol, inputList, names, outputs, leftLines, rightLines, format=fmt

num = n_elements(names)

for jj=0, num-1 do begin
    file = names(jj)
    left = leftLines(jj)-1   ; Value comes from splot in IDL (1-based)
    right = rightLines(jj)-1 ; Value comes from splot in IDL (1-based)
    outfile = outputs(jj)

    spec2d = readfits(file, hdr)

    profile = total( spec2d, 1 )

    weights = profile[left:right] / total( profile[left:right] )

    specLength = n_elements( spec2d[*,0] )
    print, "specLength = ", specLength

    spec1d = fltarr( specLength )
    print, n_elements(spec1d)
    numLines = right - left + 1
    print, "numLines = " , numLines

    for wl=0, specLength-1 do begin
        ; Take the weighted average (weights add up to 1)
        spec1d[wl] = total( (spec2d[wl, left:right] * weights) )
    endfor

    plot, spec1d

    writefits, outfile, spec1d, hdr
endfor


stop
end
    
        
    
