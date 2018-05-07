pro nirc2_sky_script, loAngle, hiAngle, tint, coadds, outfile, onlyL=onlyL, step=step
    if (n_params(0) EQ 0) then begin
        print, 'CALLING SEQUENCE:'
        print, '    nirc2_sky_script, loAngle, hiAngle, tint, coadds, outfile [,/onlyL] [,step=#]'
        print, '           loAngle is the lowest ROTPPOSN (K-mirror) angle'
        print, '           hiAngle is the lowest ROTPPOSN (K-mirror) angle'
        print, '           tint is the integration time for Lprime'
        print, '           coadds is the # of coadds for Lprime'
        print, '           outfile is the output file for the NIRC2 script'
        print, '           /onlyL if you dont want M scripts as well'
        print, '           step=# to take a sky every # degrees (default=1)'
        retall
    endif

    ; Write a Keck NIRC2 script which can take a series of 
    ; L' or Ms skies at a range of K-mirror physical angles

    angle = loAngle

    if keyword_set(step) then step=step else step=1
    
    numSteps = abs(floor((hiAngle - loAngle) / step)) + 2
    print, format='(%"Number of steps: %d")', numSteps

    angleArray = findgen(numSteps) * step
    angleArray = angleArray + loAngle - step

    print, 'Overhead for Lp Step:'
    nirc2overhead, tint, coadds, 1, 1, 2, /sub
    print, ''
    print, 'Overhead for Ms Step:'
    nirc2overhead, 0.2, 600, 1, 1, 2, /sub

    openw, _out, outfile, /get_lun
    
    ; Print the header of the script
    printf, _out, '#!/bin/csh -f'
    printf, _out, '#+'
    printf, _out, '#'
    printf, _out, format='(%"# %s")', outfile
    printf, _out, '#'
    printf, _out, '# Takes skies at a range of K-mirror angles.'
    printf, _out, '# One sky is taken every 1 degree.'
    printf, _out, '#'
    printf, _out, '#-'
    printf, _out, ''

    ; Do our initial setup
    printf, _out, 'camera narrow'
    printf, _out, 'sampmode 2'
    printf, _out, 'wait4ao off'

    printf, _out, 'filt Lp'
    printf, _out, format='(%"tint %5.2f")', tint
    printf, _out, format='(%"coadds %3i")', coadds
    printf, _out, 'object lpsky'
    printf, _out, 'shutter open'
    printf, _out, 'echo "Starting Lp skies"'

    for i=0, numSteps-1 do begin
        ; Use to be:
        ;     modify -s dcs rotpdest=### rotmode=stationary
        ; Now uses 'rotate' to wait for angle to be set.
        printf, _out, format='(%"rotate %6.1f stationary")', angleArray[i]
        printf, _out, 'goi'
        printf, _out, ''
    endfor
    printf, _out, 'echo "Finished Lp skies"'

    if not keyword_set(onlyL) then begin
        printf, _out, 'filt Ms'
        printf, _out, 'tint 0.2'
        printf, _out, 'coadds 600'
        printf, _out, 'object mssky'
        printf, _out, 'echo "Starting Ms skies"'

        for i=0, numSteps-1 do begin
            ; Use to be:
            ;     modify -s dcs rotpdest=### rotmode=stationary
            ; Now uses 'rotate' to wait for angle to be set.
            printf, _out, format='(%"rotate %6.1f stationary")', angleArray[i]
            printf, _out, 'goi'
            printf, _out, ''
        endfor
        printf, _out, 'echo "Finished Ms skies"'
    endif

    printf, _out, 'playsound -d'
    printf, _out, 'rotate 0'
    printf, _out, 'wait4ao on'

    close, /all
end
