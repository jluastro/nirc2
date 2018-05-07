function bmacaper,image,apers,xc,yc,insky,outsky,skyout=skyout,maskkcam=maskkcam,crad=crad,avsky=avsky,skyval=skyval,draw=draw,clip=clip
;bmac quick aperture photometry program
;originally intend for keck data
;Input: 
;apers: array of aperture radii
;xc,yc : approximate x and y centroid of star
;/maskkcam: mask out kcam bad quadrant
;crad: centroid radius (0 = no centroiding, default=6)
;/avsky: calculate an average sky in the annulus rather than a median
;/draw: draw a circle showing the apertures on an image (which must have
; been displayed in a way that sets up a data coordinate system, e.g. 
; exptv) 
;output: 
;skyval: output sky value
;clip (output): 1=aperture was clipped

	if n_elements(insky) eq 0 then insky=max(apers)+10
	if n_elements(outsky) eq 0 then outsky = insky + 10
	if n_elements(crad) eq 0 then crad = (apers(0)/2.)>6
	if crad eq 0 then begin
		x=xc
		y=yc
	endif else begin
		cents=cent0(image,xc,yc,crad/2.)
		x=cents(0)
		y=cents(1)
	endelse

	sizein=size(image)
	xs=sizein(1)
	ys=sizein(2)
	
	rmap=radmap(image,x,y)

	if keyword_set(maskkcam) then rmap(128:255,0:127)=1e6

	napers=n_elements(apers)
	flux=fltarr(napers)

	if n_elements(skyval) ne 0 then skyval=skyval else begin
		skypix=where (rmap ge insky and rmap le outsky)	
		if keyword_set(avsky) then skyval=avg(image(skypix)) else skyval=median(image(skypix))
	endelse

	if keyword_set(draw) then begin
		pcirc,x,y,insky;,0.75*!D.N_COLORS-1
		pcirc,x,y,outsky;,0.75*!D.N_COLORS-1
	endif

	for i=0,napers-1 do  begin
		valid=where(rmap le apers(i))
		flux(i)=total(image(valid))-skyval*n_elements(valid)
		if (apers(i) gt x or apers(i) gt xs-x or apers(i) gt y or apers(i) gt ys-y) then begin 
			print,'Warning: clipped aperture rad=',apers(i)
			clip=1
		endif else clip=0

		if keyword_set(draw) then pcirc,x,y,apers(i);,!D.N_COLORS-1
	endfor
	skyout=skyval
return,flux
end








