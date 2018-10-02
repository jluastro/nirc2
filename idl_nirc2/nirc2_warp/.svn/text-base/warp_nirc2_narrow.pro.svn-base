pro warp_nirc2_narrow, in, out
; Removes the optical distortion that is present in the NIRC2
; wide-field camera. A 3-rd order 2-d polynomial is used with
; coefficients determined by Eiichi Egami using the warping mask
; inside NIRC2. It therefore only removes the internal distortion of
; NIRC2 which is believed to be the dominant but not necessarily the
; only distortion in the NIRC2+AO system.

kx=[ 0.505819,   0.00762910, -1.51447e-05,  4.35532e-09, $
      1.00264, -7.85801e-06,  6.21095e-09, -6.62645e-14, $
 -8.24474e-06,  1.20162e-09, -6.62047e-13,  1.95634e-16, $
  8.76976e-09, -3.01802e-13,  2.78581e-16, -8.99969e-21]
ky=[ 0.153391,      1.00625, -2.02036e-05,  1.18320e-08, $
  -0.00222593,  6.83582e-06, -3.98600e-11,  3.03811e-13, $
 -4.10841e-06,  3.01651e-09, -4.71330e-13,  1.86863e-16, $
  1.54030e-09,  7.69799e-14,  7.66486e-17,  1.25724e-20]

; Setup frames that are the correct size.
out = in

out=POLY_2d(in, kx, ky, 1, missing=0)

end

