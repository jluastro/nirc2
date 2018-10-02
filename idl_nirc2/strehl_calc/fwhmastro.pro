pro fwhmastro,image,xc,yc,boxsize,outpars,outim
;procedure to estimate the fwhm of an object located roughly at xc,yc in
;a box of size boxsize
;uses gauss2dfit and returns outpars in gauss2dfits
;format, which is 
;outpars(0)=constant term
;outpars(1)=scale factor (peak value)
;outpars(2)=gaussian x width
;outpars(3)=gaussian y width
;outpars(4)=center x location
;outpars(5)=center y location
;outpars(6)=rotation of the ellipse from the x-axis
;           in degrees (not radians as in gauss2dfit)

boxhalf=boxsize/2
blx=floor(xc-boxhalf)
bly=floor(yc-boxhalf)
subim=image[blx:blx+boxsize,bly:bly+boxsize]
fitim=gauss2dfit(subim,outpars, /tilt)
;print,outpars
outpars[4]=outpars[4]+blx
outpars[5]=outpars[5]+bly
outpars[6]=outpars[6]*180./!pi
outim=fitim
return
end
