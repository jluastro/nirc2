;+
; NAME:
;    nirc2rotpposn, year, month, day, [PA=PA]
;
;
; PURPOSE:
;    This program uses skycalc to collate relevant information on the
;    important times and numbers for observing the galactic center
;    with NIRC2. The output file contains skycalc almanac info as well
;    as a table of hour angle, airmass, elevation, azimuth,
;    parallactic angle, and ROTPPOSN (AO mirror angle) for the
;    galactic center on the night specified.
;
; INPUTS:
;    year - A integer year value (e.g. 2005)
;    month - A integer month value (e.g. 07 or 7)
;    day - A integer day value (e.g. 24). Date should be local to Hawaii.
;
; OPTIONAL INPUTS:
;    PA - desired position angle on the NIRC2 array (0 = N up;
;               default = 190)
;
; OUTPUTS:
;    Output file for nirc2rotpposn, 2005, 7, 24 would be
;    "gc2005_07_24.skycalc".
;
; EXAMPLE:
;    nirc2rotpposn, 2005, 7, 24
;
; MODIFICATION HISTORY:
;    2005/07/22 -- Written by Jessica Lu
;-
pro nirc2rotpposn, year, month, day, PA=PA
    ; Use skycalc to get a table of relevant observable values
    ; for the Galactic Center every half hour.

IF n_params(0) eq 0 THEN BEGIN
    print, "% USAGE: nirc2rotpposn, year, month, day, PA=PA"
    print, "%           HST date (not UT)"
    RETALL
ENDIF

    ra = '17 45 40.0409'
    dec = '-29 00 28.118'
    if keyword_set(PA) then posAng = PA else posAng = 190.0

    hour = findgen(10) + 19
    min = [0, 30]
    
    inputFile = 'nirc2rotpposn_skycalc.txt'

    fmt = '(%"gc%4d_'
    if (month LT 10) then fmt = fmt + '0%1d_' else fmt = fmt + '%2d_'
    if (day LT 10)   then fmt = fmt + '0%1d.' else fmt = fmt + '%2d.'
    fmt = fmt + 'skycalc")'

    outputFile = string(format=fmt, year, month, day)

    openw, _in, inputFile, /get_lun

    printf, _in, 'm'
    printf, _in, format='(%"y %4d %2d %2d")', year, month, day
    printf, _in, format='(%"r %s d %s")', ra, dec
    printf, _in, 'a'

    for h=0, n_elements(hour)-1 do begin
        for m=0, n_elements(min)-1 do begin
            printf, _in, format='(%"t %2d %2d = ")', hour[h], min[m]
        endfor
    endfor
    printf, _in, 'Q'

    close, _in

    cmd = string(format='(%"skycalc < %s > %s.tmp")', inputFile, outputFile)
    spawn, cmd

    ; Now we need to read in this file and reformat it 
    ; and make the table
    numLines = numlines(outputFile + '.tmp')
    openr, _in, outputFile + '.tmp', /get_lun
    openw, _out, outputFile, /get_lun

    nHour = n_elements(hour)
    nMin = n_elements(min)
    nTot = nHour*nMin
    hst = strarr(nTot)
    hourAngle = strarr(nTot)
    airmass = fltarr(nTot)
    elev = fltarr(nTot)
    azimuth = fltarr(nTot)
    parAngle = fltarr(nTot)
    rotpposn = fltarr(nTot)
    
    almanacStart = 0
    almanacStop = 0
    idx = 0
    for i=0, numLines-1 do begin
        tmp = ''
        readf, _in, tmp
        
        fields = strsplit(tmp, ' ', /extract) 
        
        if(fields[0] EQ 'Almanac') then begin
            almanacStart = 1
        endif

        if (almanacStart EQ 1 AND almanacStop EQ 0) then begin
            if (fields[0] EQ 'Type') then begin
                almanacStop = 1
                continue
            endif

            printf, _out, tmp
        endif
            
        if (almanacStart EQ 1 AND almanacStop EQ 1) then begin
            if (fields[0] EQ 'Local') then begin
                hst[idx] = string(format='(%"%2s:%2s")', $
                                  fields[9], fields[10])
            endif
            if (fields[0] EQ 'HA:') then begin
                hourAngle[idx] = string(format='(%"%3s:%2s:%2s")', $
                                        fields[1], fields[2], fields[3])

                if (fields[5] EQ 'BELOW') then begin
;                    break
                     airmass[idx] = float(999)
                 endif else airmass[idx] = float(fields[6])

            endif
            if (fields[0] EQ 'altitude') then begin
                elev[idx] = float(fields[1])
                azimuth[idx] = float(fields[3])
                parAngle[idx] = float(fields[6])
                
                rotpposn[idx] = posAng + 0.7 + elev[idx] - parAngle[idx]

                if (idx EQ 0) then begin
                    fmt = '(%"%5s\t%9s\t%7s\t%5s\t%6s\t%6s\t%8s")'
                    printf, _out, format=fmt, $
                            'HST', 'HourAng', 'Airmass', 'Elev', 'Az', $
                            'parAng', 'ROTPPOSN'
                endif
                fmt = '(%"%5s\t%9s\t%5.3f\t%5.2f\t%6.2f\t%6.1f\t%6.1f\t%6.1f")'
                printf, _out, format=fmt, hst[idx], hourAngle[idx], $
                        airmass[idx], elev[idx], azimuth[idx], $
                        parAngle[idx], rotpposn[idx], rotpposn[idx]-360.0
                
                idx = idx + 1
            endif
        endif
    endfor
    
    close, /all
    spawn, '/usr/bin/rm -f ' + inputFile
    spawn, '/usr/bin/rm -f ' + outputFile+'.tmp'
end
