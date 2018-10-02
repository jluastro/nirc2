PRO pcirc,x0,y0,r,color,linestyle=linestyle
        theta=findgen(500.0)*2*!pi/500.0
      x=r*cos(theta)+x0
      y=r*sin(theta)+y0
      if (n_elements(color) eq 0) then clr=!P.COLOR else clr=color
      oplot,x,y,color=clr,linestyle=linestyle
;     print,x,y
end
