; This file is used to remove the bad pixels in the LBWFS.
; Marcos van Dam
; It is modified from image_fix, written by O. Lai and D.S. Acton
;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This function replaces bad pixels with an average of the neighbors. pixmap is a
; 2-D array the same size as the image, with 1's where bad pixels exist. Written
; by O. Lai.
	function deadpixcor,image,pixmap
	bmap=pixmap
	gmap=1-bmap
;
; Replace the bad pixels in the image with zeros.
	im=float(image*gmap)
;
; The bad pixel map "bmap" is updated as the pixels are corrected. Continue as long
; as there are bad pixels indicated in "bmap."
	while (total(bmap) ne 0) do begin
	  temp1=shift(gmap,1,0)+shift(gmap,-1,0)+shift(gmap,0,-1)+shift(gmap,0,1)
	  temp2=shift(im,1,0)+shift(im,-1,0)+shift(im,0,-1)+shift(im,0,1)
	  dpix=(temp1 ne 0)*bmap*temp2/(temp1+1e-15)
	  bmap=temp1 eq 0
	  gmap=1-bmap
	  im=im+dpix
	endwhile
	return,im
	end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This subroutine does preprocessing of images.
	function fix_image,foc
	focn=float(foc)
;
; Generate dead pixel maps. This part written by O. Lai.
	kernel=replicate(1,3,3)
	apod=focn*0.+1.
	apod(0:1,0:1)=0
	apod=shift(apod,-1,-1)
	focn=focn*apod
	foc1=abs(focn) gt 3.*robust_sigma(focn)
	deadfoc=foc1-dilate(erode(foc1,kernel),kernel)
	focn=deadpixcor(focn,deadfoc)
	
	return, focn
	end

