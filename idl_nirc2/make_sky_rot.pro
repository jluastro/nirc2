;+
; NAME:
;     make_sky_rot, inputFits, outputRoot
;
;
; PURPOSE:
;     This program takes a list of raw sky images, determines their K
;     mirror angle and makes 1 sky for every 3 images that are close
;     together in ROTPPOSN
;
; INPUTS:
;     inputFile - a list of raw FITS files be used in creating skies.
;     outputRoot - the base root name for the skies
;
; OUTPUTS:
;     Will create sky fits files.
;
; MODIFICATION HISTORY:
;     Written by Jessica Lu - July 16, 2004
;-

pro make_sky_rot, inputList, outputRoot

    on_error, 2
    
    readcol, inputList, file, angle, format='A,F'
    foo = where(strmatch(file, '*(fits)$') EQ 1, cnt)

    if (cnt EQ 0) then begin
        file = file + ".fits"
    endif

    ; Fix angle so that it is between -180 and 180
    i_fix = where(angle GT 180, cnt)
    if (cnt GT 0) then angle[i_fix] = angle[i_fix] - 360.0

    i_fix = where(angle LT -180, cnt)
    if (cnt GT 0) then angle[i_fix] = angle[i_fix] + 360.0

    idx = sort(angle)

    openw, _log, outputRoot + '.log', /get_lun
    openw, _rot, 'rotpposn.txt', /get_lun

    for i=1, n_elements(idx)-2 do begin
        outputRoot = strcompress( string(outputRoot, angle[idx[i]], $
                                         format='(%"%s%7.1f")'), $
                                  /remove_all)
        outputName = outputRoot + '.fits'

        print, outputName, file[idx[i-1]], file[idx[i]], file[idx[i+1]], $
               format='(%"%s: %s %s %s")'
        printf, _log, format='(%"%s: %s %s %s  %6.1f %6.1f %6.1f")', $
                outputName, file[idx[i-1]], file[idx[i]], file[idx[i+1]], $
                angle[idx[i-1]], angle[idx[i]], angle[idx[i+1]]

        fits_read, file[idx[i-1]], img1, hdr1
        fits_read, file[idx[i]], img2, hdr2
        fits_read, file[idx[i+1]], img3, hdr3
        
        siz = sqrt(n_elements(img1))
        
        bigimg = fltarr(siz, siz, 3)
        bigimg[0,0,0] = img1
        bigimg[0,0,1] = img2
        bigimg[0,0,2] = img3

        medarr, bigimg, sky
        fxaddpar, hdr2, "SKYCOMB", $
                  string( file[idx[i-1]], file[idx[i]], file[idx[i+1]], $
                  format='(%"%s: %s %s %s")')

        fits_write, outputName, sky, hdr2

        printf, _rot, format='(%13s %8.3f)', outputRoot, $
                fxpar(hdr2, 'ROTPPOSN')
    endfor
    
    close, /all
end

        
        



