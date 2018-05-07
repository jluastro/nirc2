pro calc_cmdstrehl, strehl

;----------
; Find the root directory where the calibration files live.
;----------
paths = strsplit(!PATH, ':', /extract)
idx = where(strmatch(paths, '*strehl_calc') EQ 1, cnt)

if (cnt gt 1) then begin
    print, 'CALC_CMDSTREHL: Found too many root directories, using first one found: '
    print, paths[idx]
    idx = idx[0]
endif
root = paths[idx] + '/'

if strehl.nbg gt 0 then bgval=0.
if strehl.output ne 'none' then openw,u,strehl.output,/get_lun,/append
nosmooth=1.

box=strehl.radius*2+1
ctr=(size(strehl.dl_im))(1)/2; center of the diffraction-limited image

image=strehl.currentim
radius=strehl.radius
photrad=strehl.photrad

If strehl.autofind eq 1 then begin
    ismooth=image
    if nosmooth eq 0 then ismooth=median(image,3)
    maxval = max(ismooth, index)
    sz=size(image)	
    xcur = index mod sz(1)
    ycur = index / sz(2)
    error=0
endif else begin
    ext_start=strpos(strehl.filename_im,'.fits')
    coord_filename=strmid(strehl.filename_im,0,ext_start)+'.coord'  
    openr,v,coord_filename,/get_lun,error=error
    readf,v,xcur,ycur
    free_lun,v
endelse

if ((xcur gt 0 and ycur gt 0 and error eq 0) or $
    strehl.autofind eq 1) then begin

    cntrd,image,xcur,ycur,x,y,radius,/silent
    ;print, x, y, xcur, ycur
;    display, image    
    if (x ne -1 and y ne -1) then begin
        ;params = []
        fwhmastro,image,x,y,box,params
        scale=1
        minfwhm=(0.25*strehl.wavelength*1e6/13)*1000./strehl.plate_scale
        minsig=minfwhm/2.355

        ; Correction, wavelength is just the effective wavelength
        ; of the filter. Real sources could have a shorter effective
        ; wavelength and there is noise in the data. So instead, 
        ; we should allow a 10% wiggle room.
        ; J. R. Lu - 2010 Jan 6
        minsig = 0.9 * minsig

        while (params(2) LT minsig OR $
               params(3) LT minsig OR $
               params(2) GT 100 OR $
               params(3) GT 100) do begin
            scale=scale+0.1
            ;params = []
            fwhmastro,image,x,y,box*scale,params
        endwhile
        print, 'find peak'
        peak=find_peak(image,x,y,box)
        params(1)=peak
        xsig=params(2)
        ysig=params(3)
        xc=params(4)
        yc=params(5)
        rot=params(6)*180./!pi
        
        strehl.fwhm=(xsig+ysig)*2.355/2.*strehl.plate_scale
        starflux=bmacaper(image,photrad,x,y,photrad+20,photrad+30,$
                          maskkcam=0,skyout=apersky,skyval=bgval)
        strehl.starflux=starflux(0) ; 
        
        sky=bgval	 
        params(0)=bgval	
        strehl.strehlim=(peak/strehl.starflux)/strehl.strehlone
        
        if ((x-2*radius+1 ge 0) and $
            (y-2*radius+1 ge 0) and $
            (x+2*radius lt (size(image))[1]) and $
            (y+2*radius lt (size(image))[2])) then begin

            subpop=image(x-2*radius+1:x+2*radius,y-2*radius+1:y+2*radius) 
        endif else begin
            print,'Star too close to the edge of the image, exiting'
;		subimage=fltarr(2*radius+2,2*radius+2)
            strehl.strehlim=0.
            strehl.fwhm=0.
            return
        endelse
;        subpopdl=(rot(strehl.dl_im,-30+strehl.pupil_angle,/interp))(ctr-2*radius:ctr+2*radius,ctr-2*radius+1:ctr+2*radius)
 ; 	subpopdl=strehl.dl_im(ctr-2*radius:ctr+2*radius,ctr-2*radius+1:ctr+2*radius)
        subim=image(x-radius+1:x+radius,y-radius+1:y+radius)
	subim=congrid(subim,radius*16,radius*16,/cubic)
	submax=max(subim)
	npixfwhm=n_elements(where(subim gt 0.5*submax))
	npixfwhm=2*sqrt(npixfwhm/!pi)/8.

	if strehl.strehlim lt 1 then begin
            rms_error = sqrt(-alog(strehl.strehlim)) * $
                        strehl.wavelength/(2*!pi) * 1e9 
        endif else rms_error=0

        if (strehl.strehlim lt 0 or $
            strehl.strehlim gt 1 or $
            strehl.fwhm gt 500 or $
            strehl.fwhm lt minfwhm*strehl.plate_scale) then begin

            strehl.strehlim = -1.0
            strehl.fwhm     = -1.0
            rms_error       = -1.0
        endif

        if (strehl.list eq 'none') then begin
            if ~strehl.silent then begin
                print, 'Image'+strcompress(strehl.imno,/remove_all)+$
                       ' S = '+string(strehl.strehlim,format='$(f6.3)')+$
                       ' RMS err = ' +string(rms_error,format='$(f6.1)')+' nm  '+$
                       'FWHM = '+string(strehl.fwhm,format='$(f6.2)')+' mas'
            endif
            
            if strehl.output ne 'none' then begin
                printf,u,'#Image'+strcompress(strehl.imno,/remove_all), $
                       strehl.strehlim,rms_error,strehl.fwhm,strehl.mjd, $
                       format='(A-30,1X,F6.3,4X,F6.1,9X,F6.2,9X,D11.5)'
            endif
        endif else begin
            if ~strehl.silent then begin
                print, strcompress(strehl.filename_im,/remove_all)+$
                       ' S = '+string(strehl.strehlim,format='$(f6.3)')+$
                       ' RMS err = ' +string(rms_error,format='$(f6.1)')+' nm  '+$
                       'FWHM = '+string(strehl.fwhm,format='$(f6.2)')+' mas'
            endif

            find_slash=strpos(strehl.filename_im,'/',/reverse_search)
            newname=strmid(strehl.filename_im,find_slash+1)
            if strehl.output ne 'none' then begin
                printf,u, strcompress(newname), $
                       strehl.strehlim,rms_error,strehl.fwhm,strehl.mjd,$
                       format='(A-30,1X,F6.3,4X,F6.1,9X,F6.2,9X,D11.5)'
            endif
        endelse
        

        if ~strehl.silent then if max(subim)/strehl.coadds gt 8000 then print,'Saturation warning: over 8000 counts per coadd' 

        if ~strehl.silent then if (x eq -1 or y eq -1) then print,'Centroider error; rerun with bigger aperture.'        
  endif
endif

if strehl.output ne 'none' then free_lun,u
end
