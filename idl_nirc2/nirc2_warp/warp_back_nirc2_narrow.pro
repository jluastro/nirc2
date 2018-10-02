pro warp_back_nirc2_narrow, in, out
; Removes the optical distortion that is present in the NIRC2
; wide-field camera. A 3-rd order 2-d polynomial is used with
; coefficients determined by Eiichi Egami using the warping mask
; inside NIRC2. It therefore only removes the internal distortion of
; NIRC2 which is believed to be the dominant but not necessarily the
; only distortion in the NIRC2+AO system.


kx=[-0.500319,  -0.00768126,  1.52515e-05, -4.39995e-09, $
     0.997377,  7.83508e-06, -6.09873e-09, -8.19050e-16, $
  8.09910e-06, -7.98696e-10, -3.22839e-15,  2.08676e-18, $
 -8.59993e-09, -8.69517e-16,  2.17405e-18, -1.41122e-21]
ky=[-0.150103,     0.993681,  2.04166e-05, -1.19999e-08, $
   0.00219809, -6.65425e-06, -3.97801e-10, -1.28438e-15, $
  4.10090e-06, -2.79757e-09, -5.09408e-15,  2.96743e-18, $
 -1.59981e-09, -1.52374e-15,  3.19105e-18, -1.85974e-21]

; Setup frames that are the correct size.
out = in

out=POLY_2d(in, kx, ky)

end

