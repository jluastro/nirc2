; find the Strehl straight from the command line
; Marcos van Dam
; August 2004
; 2006       - Heavily modified by Seth Hornstein
; 06/01/2006 - root directory changed from/to
;              /s/kefa/jlu/idl/lib/NIRC2/strehl_calc/
;              /net/leto/data/ghezgroup/code/idl/NIRC2/strehl_calc/
;
; 06/01/2006 - Jessica Lu put in path hunting code to determine root
;              directory on the fly instead of hard coded.
;
; 07/10/2006 - Added rounding to urx and ury to handle odd number
;              sized psf images.
;
; 08/18/2006 - Increase the box size if the PSF FWHM isn't converging.
;              (see section involving fwhmastro)
;
; 08/22/2006 - Calculate a (very conservative) minimum believable fwhm
;              (Using a D=13m mirror). If FWHM is below this level,
;              its probably a fitter error. Increase boxsize and try
;              again.
; 06/10/2008 - Changed image parameters to not be hard-coded to
;              1024x1024. This allows sub-arrayed images to be used.
;              -Sylvana Yelda
; 07/18/2013 - when it finds two root directories, just pick the first one. 
;              - T. Do
;@strehl_data_struc_default.pro
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
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
    ctr=(size(strehl.dl_im))(1)/2 ; center of the diffraction-limited image

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

        cntrd,image,xcur,ycur,x,y,radius,silent=strehl.silent

;    display, image
        if (x ne -1 and y ne -1) then begin
            params = []
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
                params = []
                fwhmastro,image,x,y,box*scale,params
            endwhile
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
            ;print, 'Strehl = ' + string(peak) + ' (peak) / ' + string(strehl.starflux) + $
            ;       ' (starflux) / ' + string(strehl.strehlone) + ' (strehlone)'
            ;print, 'peak flux ratio = ' + string(peak/strehl.starflux) + ', dl peak flux ratio = ' + string(strehl.strehlone)
            
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
                           'FWHM = '+string(strehl.fwhm,format='$(f6.2)')+' mas at '+$
                           'xpos = '+string(xcur, format='$(f6.1)')+' '+$
                           'ypos = '+string(ycur, format='$(f6.1)')                           
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
                           'FWHM = '+string(strehl.fwhm,format='$(f6.2)')+' mas at '+$
                           'xpos = '+string(xcur, format='$(f6.1)')+' '+$
                           'ypos = '+string(ycur, format='$(f6.1)')
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
;return, strehl
end

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function cmdstrehl, strehl

    if strehl.output ne 'none' then begin
        if file_test(strehl.output) ne 1 then begin
            openw,u,strehl.output,/get_lun
            printf,u,"#Filename                      Strehl  RMS error(nm)  FWHM (mas)         MJD (UT)"

            free_lun,u
        endif
    endif

;----------
; Find the root directory where the calibration files live.
;----------
    paths = strsplit(!PATH, ':', /extract)
    idx = where(strmatch(paths, '*strehl_calc') EQ 1, cnt)

    if (cnt gt 1) then begin
        print, 'CALC_CMDSTREHL: Found too many root directories, returning first directory: '
        print, paths[idx]
        idx = idx[0]
    endif
    root = paths[idx] + '/'

;find_cmdstrehl, strehl

    im1=strehl.im1
    nim=strehl.nim
    bg1=strehl.bg1
    nbg=strehl.nbg
    path=strehl.path
    list=strehl.list
    autofind=strehl.autofind

    if (list ne 'none') then begin
        if file_test(list) then begin
            readcol,list,format='a',files,/silent
            im1=0
            nim=N_ELEMENTS(files)
        endif else begin
            print, "File '"+strcompress(list)+"' not found. Exiting"
            retall
        endelse
    endif

    strehl.starflux=0.
    bgerrs=0.

    bg=0.

    if nbg gt 0 then begin
        for c1=0,nbg-1 do begin
            imno=c1+bg1
            if imno lt 10 then filename_bg=path+'/n000'+strcompress(imno,/remove_all)+'.fits' 
            if (imno ge 10)*(imno lt 100) then filename_bg=path+'/n00'+strcompress(imno,/remove_all)+'.fits' 
            if (imno ge 100)*(imno lt 1000) then filename_bg=path+'/n0'+strcompress(imno,/remove_all)+'.fits' 
            if (imno ge 1000)*(imno lt 10000) then filename_bg=path+'/n'+strcompress(imno,/remove_all)+'.fits' 
            

            thisbg=readfits(filename_bg,hd,/silent)
            if n_elements(thisbg) eq 1 then begin
                print, filename_bg+' does not exist, background set to 0.'
                bgerrs=1.
            endif else bg=bg+thisbg
        endfor

        bg=bg/nbg
    endif

    if bgerrs eq 1 then begin   ; if there is a background error, treat as if bg does not exist
        bg=0.
        nbg=0.
    endif

; could implement something clever here to verify that the exposure times and fuilters were the same for the background for the images. Also check for images sizes!!!

;dm=fltarr(nim)
;tt=dm
;fr=dm
;ps=dm
;str=dm

    for c1=0,nim-1 do begin
        if (list eq 'none') then begin
            strehl.imno=c1+im1
            if strehl.imno lt 10 then strehl.filename_im=path+'/n000'+strcompress(strehl.imno,/remove_all)+'.fits' 
            if (strehl.imno ge 10)*(strehl.imno lt 100) then strehl.filename_im=path+'/n00'+strcompress(strehl.imno,/remove_all)+'.fits' 
            if (strehl.imno ge 100)*(strehl.imno lt 1000) then strehl.filename_im=path+'/n0'+strcompress(strehl.imno,/remove_all)+'.fits' 
            if (strehl.imno ge 1000)*(strehl.imno lt 10000) then strehl.filename_im=path+'/n'+strcompress(strehl.imno,/remove_all)+'.fits' 
            test=file_test(strehl.filename_im)
            if test eq 0 then begin
                newname=strehl.filename_im
                find_n=strpos(newname,'n',/reverse_search)
                strput,newname,'c',find_n
                strehl.filename_im=newname
            endif
        endif else begin
            strehl.imno=c1
            strehl.filename_im=strcompress(files[c1],/REMOVE)
            if strpos(strehl.filename_im,'.fits') eq -1 then strehl.filename_im=strehl.filename_im+'.fits'
            ;;strehl.filename_im=path+strcompress(files[c1],/REMOVE)
        endelse

        currentim=readfits(strehl.filename_im,hd,/silent)
        if n_elements(currentim) eq 1 then begin
            print,string(strehl.filename_im)+' does not exist, skipping.'
            continue
        endif 
        
;	if c1 eq 0 then begin
        camera = SXPAR(hd, 'CAMNAME')
        strehl.camera=strcompress(camera,/REMOVE_ALL)
        pmsname = SXPAR(hd, 'PMSNAME')
        strehl.wavelength=SXPAR(hd, 'EFFWAVE')*1e-6
        strehl.pupil_angle = 0  ; SXPAR(hd, 'ROTDEST')
        strehl.coadds=sxpar(hd,'COADDS')
        filter=sxpar(hd,'FILTER')
        strehl.mjd=SXPAR(hd, 'MJD-OBS')

        if strehl.holo eq 1 then begin
            filter = 'K+clear'
            strehl.coadds=1
            strehl.wavelength=2.2*1e-6
        endif

        strehl.filt=which_filter(filter)
        
        strehl.dl_im=readfits(root+strehl.filt+'.fits',/silent)

        if strehl.holo eq 0 then begin
            case strehl.camera of
                'narrow': begin
                    strehl.photrad=strehl.photon_radius*100.
                                ; Only set if not already specified
                    if strehl.radius eq -1 then strehl.radius = 10.   
                    strehl.plate_scale=9.94
                end
                
                'medium': begin
                    strehl.photrad=strehl.photon_radius*50.
                    dl_im_temp=rebin(strehl.dl_im,256,256)
                    strehl.dl_im=pad_image(dl_im_temp,512)
                                ; Only set if not already specified
                    if strehl.radius eq -1 then strehl.radius = 5.
                    strehl.plate_scale=9.94*2
                end
                
                'wide': begin
                    strehl.photrad=strehl.photon_radius*25.
                    dl_im_temp=rebin(strehl.dl_im,128,128)
                    strehl.dl_im=pad_image(dl_im_temp,512)
                                ; Only set if not already specified
                    if strehl.radius eq -1 then strehl.radius = 3.
                    strehl.plate_scale=9.94*4
                end
                
                ELSE: begin
                    PRINT,"Can't determine the plate scale, assuming narrow"
                    strehl.photrad=strehl.photon_radius*100.
                    strehl.radius=10.
                    strehl.plate_scale=9.94
                end  
                
            endcase
            
        endif else begin
            strehl.photrad=strehl.photon_radius*50.
            dl_im_temp=rebin(strehl.dl_im,256,256)
            strehl.dl_im=pad_image(dl_im_temp,512)
            strehl.radius=5.
            strehl.plate_scale=20.0
        endelse

        ;; find the maximum using the diffraction-limited image, strehl.dl_im
        box=strehl.radius*2+1
        ctr=(size(strehl.dl_im))(1)/2 ; center of the diffraction-limited image
        dlpeak=find_peak(strehl.dl_im,ctr,ctr,box)
        
        ;; find the total flux in the image
        refflux=bmacaper(strehl.dl_im,strehl.photrad,ctr,ctr,strehl.photrad+20,strehl.photrad+30,maskkcam=0,skyval=0.)
        ;; find the reference intensity
        ;print, 'dlpeak = ' + string(dlpeak)
        ;print, 'refflux = ' + string(refflux)
        strehl.strehlone=dlpeak/refflux(0)
        
;    strehl.wavelength=central_wavelength(strehl.filt)
        
        xs=(size(currentim))(1)
        ys=(size(currentim))(2)
                                ; The changes below were made to account for images taken 
                                ; using subarrays (e.g., 264x264 instead of the full 1024,1024)
                                ;blx=512-xs/2
                                ;bly=512-ys/2
                                ;urx=round(511+xs/2.)
                                ;ury=round(511+ys/2.)
        blx=0
        bly=0
        urx=round(xs-1)
        ury=round(ys-1)
;endif

        currentim=fix_image(currentim-bg)
                                ;strehl.currentim=fltarr(1024,1024)
        strehl.currentim=fltarr(xs,ys)
        strehl.currentim(blx:urx,bly:ury)=currentim	
                                ;STOP
        calc_cmdstrehl,strehl
    endfor

    return, strehl


end
