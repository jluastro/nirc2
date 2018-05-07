function evalpoly,P,x,y

v = P[0]+P[1]*x+P[2]*y+P[3]*x*x+P[4]*x*y+P[5]*y*y+P[6]*x*x*x+P[7]*x*x*y+ $
  P[8]*x*y*y+P[9]*y*y*y

return, v
end

pro det_warp_narrow
; Removes the optical distortion that is present in the NIRC2
; wide-field camera. A 3-rd order 2-d polynomial is used with
; coefficients determined by Eiichi Egami using the warping mask
; inside NIRC2. It therefore only removes the internal distortion of
; NIRC2 which is believed to be the dominant but not necessarily the
; only distortion in the NIRC2+AO system.

; The distortion tables in the document are in the wrong direction for
; the IDL warping routin. So first we need to create a set of grids
; containing the initial and final x,y values.
P = [-2.72e-1, $
     1.0009,$
     5.08e-3,$
     -5.52e-6,$
     7.7e-7,$
     5.37e-6,$
     -8.6e-9,$
     -8.0e-10, $
     -6.1e-9,$
     -4.4e-09]
Q = [1.68e-1,$
     1.6e-4,$
     1.0008,$
     2.1e-7,$
     -9.93e-6,$
     1.78e-6,$
     -1.6e-9,$
     -2.8e-9, $
     -4.0e-10,$
     -1.2e-8]


;sz = size(in)
; Setup frames that are the correct size.
;out = in
inx = fltarr(1024,1024)
iny = fltarr(1024,1024)
outx = fltarr(1024,1024)
outy = fltarr(1024,1024)
for i = 0, 1023 do begin
    for j = 0, 1023 do begin
        inx[i,j] = float(i-512)
        iny[i,j] = float(j-512)
        outx[i,j] = evalpoly(P,inx[i,j],iny[i,j])+512.0
        outy[i,j] = evalpoly(Q,inx[i,j],iny[i,j])+512.0
    endfor
endfor
inx = inx+512.0
iny = iny+512.0

; Now fit the two grids.

; This is for warp_nirc2_wide.pro
POLYWARP,inx,iny,outx,outy,3,kx,ky

; This is for warp_back_nirc2_wide.pro
;POLYWARP,outx, outy, inx,iny,3,kx,ky

print, kx
print, ky

end

