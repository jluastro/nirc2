;+
; NAME:
;     extractSpecBkgrd, inputFile, bkgFile, bk1HalfWidth,
;     bk2HalfWidth, Astar
;
;
; PURPOSE:
;     This program uses the input file to get a spatial
;     projection. These specified lines are then extracted from
;     the input file to create a 1D spectrum where each line is
;     weighted by the flux at that pixel in the spatial profile
;     (essentially waiting by the spatial profile). This works for non
;     ideal profiles.
;
;
; INPUTS:
;     inputFile -- a file where each line contains the following
;                  information (<2D spec file> <starting line> <ending line>).
;     background -- a file where each line contains the following
;                   information (<2D spec file> <bk1 center> <bk2
;                   center>).
;     bk1 -- The number of pixels to include on each side of the bk1
;            center pixel (this is a half width essentially).
;     bk2 -- The number of pixels to include on each side of the bk2
;            center pixel (this is a half width essentially).
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


pro extractSpecBkgrd, inputList, background, bk1_hw, bk2_hw, Astar

on_error,2
!p.color = 0
!p.background = 16777215

; This is for NIRC2 data and assumes certain directions (spatial and
; spectral)

fmt = '(a,a,i,i)'
readcol, inputList, names, outputs, firstLines, lastLines, format=fmt

fmt2 = '(a,i,i)'
readcol, background, bkNames, bk1Centers, bk2Centers, format=fmt2

num = n_elements(names)

aStar = readfits(Astar)

saveBkgAnswer = 'n'
savePlotAnswer = 'n'
writeFitsAnswer = 'y'

READ, "Save background plots to file? (no/yes)", saveBkgAnswer
READ, "Save spectra plots to file? (no/yes)", savePlotAnswer
READ, "Save spectra to FITS file? (no/yes)", writeFitsAnswer

for jj=0, num-1 do begin
    file = names(jj)
    first = firstLines(jj)-1 ; Value comes from splot in IRAF (1-based)
    last = lastLines(jj)-1   ; Value comes from splot in IRAF (1-based)
    outfile = outputs(jj)
    bkc1 = bk1Centers(jj)-1  ; Value comes from splot in IRAF (1-based)
    bkc2 = bk2Centers(jj)-1  ; Value comes from splot in IRAF (1-based)

    print, "Working on file ", file, first, last, outfile, bkc1, bkc2, format='(a,a,i,i,a,i,i)'

    spec2d = readfits(file, hdr)
    specLength = n_elements( spec2d[*,0] )
    numLines = last - first + 1

    ; Make an array for the wavelengths
    x = fltarr(specLength)

    wl0 = fxpar(hdr, "crval1")
    wlDel = fxpar(hdr, "cdelt1")
    wl0Pix = fxpar(hdr, "crpix1")
    for i=1,specLength do begin
        ; Remember that values come from IRAF which is 1-based
        x[i-1] = (wl0 + ((i - wl0Pix) * wlDel)) / (1E4)
    endfor



    ;----------------------------------------
    ;
    ; First extract the background spectra
    ;
    ;----------------------------------------
    bk1 = total( spec2d[*,(bkc1 - bk1_hw):(bkc1 + bk1_hw)], 2) / (2*bk1_hw + 1)
    bk2 = total( spec2d[*,(bkc2 - bk2_hw):(bkc2 + bk2_hw)], 2) / (2*bk2_hw + 1)
    bk2D = fltarr( specLength, numLines )

    for line=first, last do begin
        ; Use formula similar to 2-body gravitation
        relPos1 = line - bkc1
        relPos2 = bkc2 - line

        ; Does the whole wavelength array at once for this line
        bk2D[*, line-first] = ((relPos1 * bk2) + (relPos2 * bk1)) / (relPos1 + relPos2)
    endfor

    !p.multi = [0, 0, 3]
    plot, x, bk1/aStar, title=bkNames(jj) + ": Left Background", /ynozero, xstyle=1
    plot, x, bk2/aStar, title=bkNames(jj) + ": Right Background", /ynozero, xstyle=1
    plot, x, bk2D[*,floor((last-first)/2)]/aStar, $
          title=bkNames(jj) + ": Middle Background", $
          /ynozero, xstyle=1

    answer = 'n'
    READ, "Press return to continue", answer

    if (saveBkgAnswer NE 'no' AND saveBkgAnswer NE 'n') then begin 
        set_plot, 'PS'
        device, filename="plots/bkPlot_" + string(jj, format='(i1)') + ".ps"

        plot, x, bk1/aStar, title=bkNames(jj) + ": Left Background", /ynozero, xstyle=1
        plot, x, bk2/aStar, title=bkNames(jj) + ": Right Background", /ynozero, xstyle=1
        plot, x, bk2D[*,floor((last-first)/2)]/aStar, $
              title=bkNames(jj) + ": Middle Background", $
              /ynozero, xstyle=1

        device, /close_file
        set_plot, 'x'
    endif

    !p.multi = [0, 0, 0]


    ;----------------------------------------
    ;
    ; Now extract the 2D spec into a sub array 
    ; and subtract the background
    ;
    ;----------------------------------------
    spec2D_small = spec2d[*, first:last]
    spec2D_small_withBK = spec2D_small ;save a copy of it for plotting
    spec2D_small = spec2D_small - bk2D


    ;----------------------------------------
    ;
    ; Get the spatial profile and weights
    ;
    ;----------------------------------------
    profile = total( spec2d, 1 )

    weights = profile[first:last] / total( profile[first:last] )


    spec1d = fltarr( specLength )
    spec1d_withBK = fltarr( specLength )

    for wl=0, specLength-1 do begin
        ; Take the weighted average (weights add up to 1)
        spec1d[wl] = total( (spec2d_small[wl, *] * weights) )
        spec1d_withBK[wl] = total( (spec2d_small_withBK[wl, *] * weights) )
    endfor

    !p.multi = [0, 0, 3]
    plot, x, smooth(spec1d_withBK / aStar, 3), $
          title=bkNames(jj) + ": S0-2 Spectrum", $
          /ynozero, $
          xstyle=1
    plot, x, smooth(bk2D[*,floor((last-first)/2)]/aStar, 3), $
          title=bkNames(jj) + ": Sample Background", $
          /ynozero, $
          xstyle=1
    plot, x, smooth(spec1d / aStar, 3), $
          title=bkNames(jj) + ": S0-2 Spectrum - Background", $
          /ynozero, $
          xstyle=1
    

    answer = 'n'
    READ, "Press Return to Continue.", answer

    if (savePlotAnswer NE 'no' AND savePlotAnswer NE 'n') then begin 
        set_plot, 'PS'
        device, filename="plots/plot_" + string(jj, format='(i1)') + ".ps"

        plot, x, smooth(spec1d_withBK / aStar, 3), $
              title=bkNames(jj) + ": S0-2 Spectrum", $
              /ynozero, $
              xstyle=1
        plot, x, smooth(bk2D[*,floor((last-first)/2)]/aStar, 3), $
              title=bkNames(jj) + ": Sample Background", $
              /ynozero, $
              xstyle=1
        plot, x, smooth(spec1d / aStar, 3), $
              title=bkNames(jj) + ": S0-2 Spectrum - Background", $
              /ynozero, $
              xstyle=1

        device, /close_file
        set_plot, 'x'
    endif

    if (writeFitsAnswer NE 'no' AND writeFitsAnswer NE 'n') then begin 
        writefits, outfile, (spec1d/aStar), hdr
    endif
endfor


stop
end
    
        
    
