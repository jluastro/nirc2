pro plotgauss,image0,gaussparams,radius
;program to overlay a gaussian measured by gaussfit2d onto a radial plot of
;an image
if n_elements(radius) eq 0 then radius=7

isize=size(image0)

blx=floor(gaussparams(4)-radius-2) > 0
bly=floor(gaussparams(5)-radius-2) > 0 
ulx=blx+2*radius+4 < isize(1)-1
uly=bly+2*radius+4 < isize(2)-1

image=image0(blx:ulx,bly:uly)

radii=radmap(image,gaussparams(4)-blx,gaussparams(5)-bly)
valid=where(radii lt radius)
plot,radii(valid),image(valid),psym=1,yrange=[min(image(valid)<0.0),gaussparams(1)>max(image(valid))]

avsigs=0.5*(gaussparams(2)+gaussparams(3))
rads=findgen(200.)/200.*radius
gaussvals=gaussparams(0)+gaussparams(1)*exp(-(rads/gaussparams(2))^2/2)
oplot,rads,gaussvals




end
