; convert the Strehl from one wavelength to another

; the brightest pixel has the following total flux
; pixel = 9.94 mas, 512 by 512 detector used in sim

;J=0.1097 (1.25um), H=0.0647 (1.63), K=0.0355 (2.20), Lp=0.0121, Ms=0.00793 (4.67)

lambda1=2.28; wavelength in microns
lambda2=1.65; wavelength in microns
strehl1=0.5; strehl at lambda1

phase1sq=-alog(strehl1); squared phase
phase2sq=phase1sq*(lambda1/lambda2)^2.
strehl2=exp(-phase2sq)

print, strehl2

end

