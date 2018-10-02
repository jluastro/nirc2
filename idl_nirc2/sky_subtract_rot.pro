pro sky_subtract_rot, gcInputList, skyDirectory, skyInputList
    on_error, 2

    ; Read in the GC input files (filename and rotpposn angle)
    readcol, gcInputList, gcFile, gcAngle, format='A,F'
    gcFileRoot = gcFile


    ; Just matching ROTPPOSN doesn't produce the best results.
    ; Instead, we know the functional form for mapping the GC 
    ; ROTPPOSN to the sky ROTPPOSN (taken in stationary mode)
    fitA = 22.1
    fitB = 0.90
    bestSkyAngle = fitA + (fitB*gcAngle)


    ; Make sure that no .fits is attached
    foo = where(strmatch(gcFile, '*(fits)$') EQ 1, cnt)
    if (cnt GT 0) then begin
        print, gcInputList + " should not have *.fits extensions"
    endif

    ; Add the .fits extension
    gcFile = gcFile + ".fits"

    ; Fix angle so that it is between -180 and 180
    i_fix = where(gcAngle GT 180, cnt)
    if (cnt GT 0) then gcAngle[i_fix] = gcAngle[i_fix] - 360.0

    i_fix = where(gcAngle LT -180, cnt)
    if (cnt GT 0) then gcAngle[i_fix] = gcAngle[i_fix] + 360.0

    ; Fix angle so that it is between -180 and 180
    i_fix = where(bestSkyAngle GT 180, cnt)
    if (cnt GT 0) then bestSkyAngle[i_fix] = bestSkyAngle[i_fix] - 360.0

    i_fix = where(bestSkyAngle LT -180, cnt)
    if (cnt GT 0) then bestSkyAngle[i_fix] = bestSkyAngle[i_fix] + 360.0

    ;
    ; Read in the Sky input files (filename and rotpposn angle)
    ;
    readcol, skyDirectory + skyInputList, skyFile, skyangle, format='A,F'
    foo = where(strmatch(skyFile, '*(fits)$') EQ 1, cnt)

    if (cnt EQ 0) then begin
        skyFile = skyFile + ".fits"
    endif

    ; Fix angle so that it is between -180 and 180
    i_fix = where(skyAngle GT 180, cnt)
    if (cnt GT 0) then skyAngle[i_fix] = skyAngle[i_fix] - 360.0

    i_fix = where(skyAngle LT -180, cnt)
    if (cnt GT 0) then skyAngle[i_fix] = skyAngle[i_fix] + 360.0


    openw, _log, gcInputList+'.log', /get_lun


    ;
    ; Loop through all the GC files and sky subtract
    ;
    for i=0, n_elements(gcFile)-1 do begin
        ; Try to find a sky to subtract at the same rotpposn

        diff = abs(skyAngle - bestSkyAngle[i])
;        diff = abs(skyAngle - gcAngle[i])

        foo = min(diff, skyidx)

        fits_read, gcFile[i], gcImg, gcHdr
        fits_read, skyDirectory + skyFile[skyidx], skyImg, skyHdr
        
        newImg = gcImg - skyImg
        sxaddpar, gcHdr, "SKYSUB", skyDirectory + skyFile[skyidx]

        fits_write, gcFileRoot[i] + "_ss.fits", newImg, gcHdr

        meanSky = mean(skyImg)
        stdSky = stddev(skyImg)

        print, gcFile[i] + " - " + skyFile[skyidx], gcAngle[i]
        printf, _log, format='(%"%s - %s  %6.1f  %6.1f  %7d  %7d")', $
                gcFile[i], skyFile[skyidx], gcAngle[i], $
                skyAngle[skyidx], meanSky, stdSky

    endfor

    close, _log
end
