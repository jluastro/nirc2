; find the diffraction-limited PSF for all the wave-lengths


aperture_pts=256;
dl=0.56
pix_per_sub=6.;
central_obsc=2.65; diameter of the central obscuration
obscuration_pixels=round(central_obsc/dl*pix_per_sub)
wavefront=fltarr(aperture_pts,aperture_pts)

N_pixels=256;
D=11.2;
lambda_image=2.1245e-6;
image_pixel_extent=0.00994/2.; half the size and then rebin

pupil=float(keckap(aperture_pts,du=dl/pix_per_sub)*(1-zernike(aperture_pts,obscuration_pixels,1)))

img=scienceimage(pupil,wavefront,N_pixels,D,lambda_image,image_pixel_extent)

; down sample by 2

image=rebin(img,512,512)
image=image/total(image); normalize to 1

;;writefits,'ms.fits',image

end























