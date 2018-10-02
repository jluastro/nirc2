; 08/18/2006 - Increase the box size if the PSF FWHM isn't converging.
;              (see section involving fwhmastro)
;
; 08/22/2006 - Calculate a (very conservative) minimum believable fwhm
;              (Using a D=13m mirror). If FWHM is below this level,
;              its probably a fitter error. Incresae boxsize and try
;              again.

pro calc_and_display,strehl

if strehl.nbg gt 0 then bgval=0.

if strehl.output ne 'none' then openw,u,strehl.output,/get_lun,/append

nosmooth=1.

box=strehl.radius*2+1
ctr=(size(strehl.dl_im))(1)/2; center of the diffraction-limited image

image=strehl.currentim
radius=strehl.radius
photrad=strehl.photrad

subpop=fltarr(2*radius+2,2*radius+2)

; display the image
imav=avg(image)
imsig=sigma(image)
min=imav-5*imsig
max=imav+5*imsig
wset,strehl.tvid(0)
exptv,image,/nobox,min=min,max=max,/data

if strehl.autofind eq 0 then begin
    widget_control,strehl.err_text,set_value='left button for star, right button to exit'
    tvpos,xcur,ycur
endif else begin
    ismooth=image
    if nosmooth eq 0 then ismooth=median(image,3)
    maxval = max(ismooth, index)
    sz=size(image)
    xcur = index mod sz(1)
    ycur = index / sz(1)
endelse

if !err eq 1 or strehl.autofind eq 1 then begin

    cntrd,image,xcur,ycur,x,y,radius,/silent
    if (x ne -1 and y ne -1) then begin
        fwhmastro,image,x,y,box,params
        scale=1
       ;;Use Diameter=13 to calculate the lowest
        ;;believeable fwhm (to allow slop in fitter)
        minfwhm=(0.25*strehl.wavelength*1e6/13)*1000./strehl.plate_scale
        minsig=minfwhm/2.355
        while (params(2) LT minsig OR $
               params(3) LT minsig OR $
               params(2) GT 100 OR $
               params(3) GT 100) do begin
            scale=scale+0.5
            fwhmastro,image,x,y,box*scale,params
        endwhile
        peak=find_peak(image,x,y,box)
        params(1)=peak
        xsig=params(2)
        ysig=params(3)
        xc=params(4)
        yc=params(5)
        rotn=params(6)*180./!pi

	strehl.fwhm=(xsig+ysig)*2.355/2.*strehl.plate_scale

        starflux=bmacaper(image,photrad,x,y,photrad+20,photrad+30,maskkcam=0,skyout=apersky,/draw,skyval=bgval)
        strehl.starflux=starflux(0) ;

        sky=bgval
        params(0)=bgval
        strehl.strehlim=(peak/strehl.starflux)/strehl.strehlone

	if (x-2*radius+1 ge 0) and (y-2*radius+1 ge 0) and (x+2*radius lt (size(image))(1)) and (y+2*radius lt (size(image))(2)) then $
	subpop=image(x-2*radius+1:x+2*radius,y-2*radius+1:y+2*radius) else begin
            widget_control,strehl.err_text,set_value='Star too close to the edge of the image, exiting'
	    strehl.strehlim=0.
            strehl.fwhm=0.
           widget_control,strehl.optionid[15],set_value=(string(strehl.strehlim,format='$(f5.3)'))
           widget_control,strehl.optionid[16],set_value=(string(strehl.fwhm,format='$(f6.2)'))
       	   return
	endelse

	subpopdl=(rot(strehl.dl_im,-30+strehl.pupil_angle,/interp))(ctr-2*radius:ctr+2*radius,ctr-2*radius+1:ctr+2*radius)
        subim=image(x-radius+1:x+radius,y-radius+1:y+radius)
	subim=congrid(subim,radius*16,radius*16,/cubic)
	submax=max(subim)
	npixfwhm=n_elements(where(subim gt 0.5*submax))
	npixfwhm=2*sqrt(npixfwhm/!pi)/8.

	if strehl.strehlim lt 1 then rms_error=sqrt(-alog(strehl.strehlim))*strehl.wavelength/(2*!pi)*1e9 else rms_error=0
        
        if strehl.strehlim lt 0 or strehl.fwhm gt 500 or strehl.fwhm lt minfwhm*strehl.plate_scale then begin
            strehl.strehlim = -1.0
            strehl.fwhm     = -1.0
            rms_error       = -1.0
        endif

	if (strehl.list eq 'none') then begin
		widget_control,strehl.err_text,set_value='Image '+strcompress(strehl.imno,/remove_all)+' S = '+string(strehl.strehlim,format='$(f5.3)')+' RMS err = ' +string(rms_error,format='$(f6.1)')+' nm'
		print, 'Image'+strcompress(strehl.imno,/remove_all)+' S = '+string(strehl.strehlim,format='$(f5.3)')+' RMS err = ' +string(rms_error,format='$(f6.1)')+' nm  '+'FWHM = '+string(strehl.fwhm,format='$(f6.2)')+' mas'
                if strehl.output ne 'none' then printf,u,'#Image'+strcompress(strehl.imno,/remove_all), strehl.strehlim,rms_error,strehl.fwhm,format='(A-30,2X,F5.3,4X,F6.1,9X,F6.2)'

	endif else begin
		widget_control,strehl.err_text,set_value=strcompress(strehl.filename_im,/remove_all)+' S = '+string(strehl.strehlim,format='$(f5.3)')+' RMS err = ' +string(rms_error,format='$(f6.1)')+' nm'
		print, strcompress(strehl.filename_im,/remove_all)+' S = '+string(strehl.strehlim,format='$(f5.3)')+' RMS err = ' +string(rms_error,format='$(f6.1)')+' nm  '+'FWHM = '+string(strehl.fwhm,format='$(f6.2)')+' mas'
                if strehl.output ne 'none' then printf,u, "#"+strcompress(strehl.filename_im,/remove_all), strehl.strehlim,rms_error,strehl.fwhm,format='(A-30,2X,F5.3,4X,F6.1,9X,F6.2)'
	endelse

	widget_control,strehl.optionid[15],set_value=(string(strehl.strehlim,format='$(f5.3)'))

	widget_control,strehl.optionid[16],set_value=(string(strehl.fwhm,format='$(f6.2)'))

	wset,strehl.tvid(1)
	tvscl,congrid((subpopdl>0)^(1./3.),128,128)
	wset,strehl.tvid(2)
	tvscl,congrid((subpop>0)^(1./3.),128,128)

        if max(subim)/strehl.coadds gt 8000 then widget_control,strehl.err_text,set_value='Saturation warning: over 8000 counts per coadd'

        if (x eq -1 or y eq -1) then widget_control,strehl.err_text,set_value='Centroider error; rerun with bigger aperture.'
  endif
endif

if strehl.output ne 'none' then free_lun,u

end


