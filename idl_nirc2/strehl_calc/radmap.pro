function radmap,inarray,x0,y0,theta=theta,angle=angle
;function to generate a radius map to match array inarray from center x0,y0
;also generates position angle map in astronomer coordinates (0=up,
;90=left) when theta=some output and /angle are set
;adapted to use the same algorithm as dist_circle oct 2002 because
;that runs a hair faster

sizein=size(inarray)
if n_elements(x0) eq 0 then x0=sizein(1)/2.0 - 0.5
if n_elements(y0) eq 0 then y0=sizein(2)/2.0 - 0.5
xs=sizein(1)
ys=sizein(2)

dists=fltarr(xs,ys)
 x_2 = (findgen(xs) - x0) ^ 2         ;X distances (squared)
 y_2 = (findgen(ys) - y0) ^ 2     ;Y distances (squared)  
 for i = 0L, ys-1 do begin              ;Row loop
      dists[0,i] = sqrt(x_2 + y_2[i])     ;Euclidian distance
 endfor


theta=fltarr(xs,ys)
if keyword_set(angle) then begin
        x=(findgen(xs) - x0)
	y=(findgen(ys) - y0)
	for i=0L, ys-1 do begin              ;Row loop
	  theta[0,i]=atan(y(i),x)
	endfor
 	theta=theta*180/!pi-90
        negs=where(theta lt 0)
	theta(negs)=theta(negs)+360.
endif


;for i=0,xs-1 do begin
;  for j=0,ys-1 do begin
;    dists(i,j)=norm([float(i)-x0,float(j)-y0])
;  endfor
;endfor

return,dists
end
