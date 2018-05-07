function cent0,im,xcest,ycest,fwhm
;centroid front-end

psize=n_elements(im)
if n_elements(xcest) eq 0 then xcest=psize(0)/2.0
if n_elements(ycest) eq 0 then ycest=psize(0)/2.0

cntrd,im,xcest,ycest,xc,yc,fwhm
return,[xc,yc]
end
