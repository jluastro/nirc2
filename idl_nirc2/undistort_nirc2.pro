;+
; NAME: undistort_nirc2
;
; PURPOSE: Undistort series of NIRC2 images using nirc2warp
;
; CALLING SEQUENCE:
; 
; cent_shift,basename,firstim,lastim
;
; INPUTS:
;
; basename => preffix without numbers or .fits
;
; firstim => number of first image (without zero)
;
; lastim => number of last image (without zero) - numbers MUST be
;                                                sequential and of the
;                                                form 0###
;
; OUTPUTS:
; 
; Undistorted images with called 'basename'.ud.####.fits
;
;-


pro undistort_nirc2,basename,firstim,lastim

numims = (lastim-firstim) + 1; number of images we're looking at


WHILE (firstim le lastim) DO BEGIN  

filename=basename+string(firstim,format="(I4.4)")+'.fits';
filenameout = basename+'ud.'+string(firstim,format="(I4.4)")+'.fits'

image=readfits(filename,header);

im_out = NIRC2WARP(image,hd=header, camera=narrow)

writefits,filenameout,im_out,header

firstim=firstim+1

ENDWHILE

end
