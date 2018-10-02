;+
; NAME:
;    nirc2limits
;
;
; PURPOSE:
;    Calculate the limiting magnitude for narrow camera galactic
;    center observations. Assumes readnoise limited which is valid for
;    K' integrations shorter than ~15 seconds. Assumes comparable
;    Strehls to the 2004 LGS K' images.
;
;
; CALLING SEQUENCE:
;    nirc2limits, itime, coadds, nfowler, snr, frames, filter
;
;
; INPUTS:
;    itime - Integration time per coadd in seconds (def=1)
;    coadds - Number of coadds for a single image (def=1)
;    nfowler - Number of reads for a particular sampmode (e.g. sampmode
;            2 has 1 fowler sample, sampmode 3 16 has 16 fowler
;            samples)
;           (def=2)
;    snr - the limiting signal-to-noise ratio. Usually around 2 or 3
;          for previous LGS K' images.
;    frames - Total number of frames taken which will be averaged
;             together to produce a combo map. (def=1)
;    filter - Either H, Kp, or Lp
;
; EXAMPLE:
;    nirc2limits, 0.181, 60, 2, 2, 1, 'Kp'
;
;
; MODIFICATION HISTORY:
;    2005/06/29 -- Written by Jessica Lu. Formula from NIRC2 manual.
;    2005/07/29 -- Added Lp and H numbers - A. Ghez
;-
pro nirc2limits, itime, coadds, nfowler, snr, frames, filter
    if (n_params(0) EQ 0) then begin
        print, 'CALLING SEQUENCE:'
        print, '    nirc2limits, itime, coadds, nfowler, snr, frames, filter'
        retall
    endif
    
    filter = strlowcase(filter)

    r0 = 17.0 * 4.0             ; in electrons & value from 04 June
    if filter EQ 'lp' then begin
	m0 = 14.73
	c0 = 120
	t0 = 0.25
	skyrate = 20000. * 4. ; in electrons
	snr0 = 4.0
    endif
    if filter EQ 'kp' then begin
        m0 = 15.77
    	c0 = 50.0
    	t0 = 0.1814
        ; Sky Rate taken from K' sky in 2004 July LGS run
        skyRate = 9.1 * 4.0     ; in electrons
	snr0 = 5.0
    endif
    if filter EQ 'h' then begin
	; measurements from Antonin on 05 July 28 LGS-ENG
	r0 = 4.5 * 4.0 	; sampmode 3 16
        m0 = 14.37
	c0 = 6.0
	t0 = 10.0
        skyRate = 8.1 * 4.0
	snr0 = 28.0
    endif

    
    ; Read noise determined from 2005 July 24 darks.
    ; RMS Readnoise per fowler sample
    R = 18.0 * 4.0              ; in electrons
    ; For sampmode 2 (nfowler=1) we get extra noise somehow
    if (nfowler EQ 1) then R = 24.0*4.0

    ; Read noise limit calculations
    tmp = snr / snr0
    tmp = tmp * sqrt(c0) / sqrt(coadds)
    tmp = tmp * t0 / itime
    tmp = tmp * (R / sqrt(nfowler)) / r0
    tmp = tmp / sqrt(frames)

    mag = m0 - (2.5 * alog10(tmp))

    ; Include background photon noise
    noise0 = (skyRate*t0*c0) + (c0*r0*r0)
    noise1a = (skyRate*itime*coadds)
    noise1b = (coadds*R*R/(sqrt(nfowler)*sqrt(nfowler)))
    noise1 = noise1a + noise1b
    tmp0 = snr / snr0
    tmp0 = tmp0 * (c0*t0) / (coadds*itime)
    tmp0 = tmp0 * sqrt(noise1) / sqrt(noise0)
    tmp0 = tmp0 / sqrt(frames)

    mag_new = m0 - (2.5*alog10(tmp0))
    
    print, format='(%"\tFilter: %s")', filter
    print, format='(%"\tIntegration time: %f")', itime
    print, format='(%"\tNumber of Coadds: %d")', coadds
    print, format='(%"\tNumber of nfowler: %d")', nfowler
    print, format='(%"\tSignal-to-Noise: %d")', snr
    print, format='(%"\tFrames to be Meaned: %d")', frames
    print, format='(%"\tRead noise = %8.2f electrons")', sqrt(noise1b)
    print, format='(%"\tBackground noise = %8.2f electrons")', sqrt(noise1a)
    print, format='(%"Limiting magnitude = %6.2f")', $
           mag
    print, format='(%"Limiting magnitude (with background) = %6.2f")', $
           mag_new
end
