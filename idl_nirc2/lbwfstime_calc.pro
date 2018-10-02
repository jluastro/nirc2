PRO lbwfstime_calc

alad_vers = 3
samprate  = 200.
x_extent  = 1024.
y_extent  = 1024.
nim       = 1.

;K' Settings
;itime     = 2.8
;coadds    = 10.
;sampmode  = 3.

;L' Settings
itime     = 0.5
coadds    = 60.
sampmode  = 2.

if sampmode gt 2 then nsamp     = 8. else nsamp = 2.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; The total time spent integrating and reading out the detector (not includ
;;   ing the time to transfer data around) should be: 
;;           tread = [tint + (readmin*nreads)]*coadds
;;  where readmin is the minimum integration time for a given array format in CDS
;; If I subtract this from each measured time/frame, assume that there is a 
;;  fixed-length overhead A associated with gathering and writing the 
;;  FITS header data, plus extra overhead per pixel B due to opening the 
;;  file and writing the data, I get: 
;;  A = 3.05 seconds per frame B = 4.65e-6 seconds per pixel
;;
;; The final formula for total time per frame is:
;;   time/frame = (tint + (tmin*samp)*coadd + A + (B * Xsubc*Ysubc)

nirc2Aparm = 3.05
nirc2Bparm = 4.65e-6 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; this is to estimate the readout time per read (not per coadd!)
;; this is an extract from the tmin function
; An overhead is specified in percent.
overhead = 6.001

; Calculation from /kroot/kss/nirc2/alad/keyword/nrpc_svc_proc.c, 3/1/01.
; Aladdin 3 chips have an overscan.

if (alad_vers eq 3) then y_extent =  y_extent + 8

ticks =  5000000/(samprate * 1000)
npause =  ticks - 8

start_time =  240 * (1324 - y_extent)
rows_time =  25 * y_extent * (npause * (8 + x_extent/4) + (864 + 1.25 * x_extent))

MinTime =  start_time + rows_time

; Add overhead, scale from nanonseconds.

MinTime =  (1+overhead/100) * MinTime / 1000000000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


timeperframe =   (itime + (MinTime * nsamp)) * coadds + nirc2Aparm + (nirc2Bparm * x_extent * y_extent) 

;; the total observing time per position
;;  elapsed time on a dither position:
;;  Nim * ((timeperframe)

xx =  Nim * timeperframe 
tditpos=xx
;tditpos = echo "scale=2 ; xx / 1." | bc
print, 'Setting LBWFS parameters'   
print, 'Estimated observing time per dither position: ',  tditpos, ' seconds'

end
