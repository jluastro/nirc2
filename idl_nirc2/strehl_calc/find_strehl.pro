; procedure to find the strehl of the images
; usage
; find_strehl
; written by Marcos van Dam, Oct 2003
; modified Nov 2003 to allow the flux to be kept constant
; Modified to include a widget Jan 2004
; Modified April 2004 for use by observers
;
; Inputs
;
; strehl structure
;
pro find_strehl,strehl

if strehl.output ne 'none' then begin
    if file_test(strehl.output) ne 1 then begin
        openw,u,strehl.output,/get_lun
        printf,u,"Filename                       Strehl  RMS error(nm)  FWHM (mas)"
        free_lun,u
    endif
endif

;----------
; Find the root directory where the calibration files live.
;----------
paths = strsplit(!PATH, ':', /extract)
idx = where(strmatch(paths, '*strehl_calc') EQ 1, cnt)

if (cnt gt 1) then begin
    print, 'CALC_CMDSTREHL: Found too many root directories: '
    print, paths[idx]
    return
endif
root = paths[idx] + '/'

im1=strehl.im1
nim=strehl.nim
bg1=strehl.bg1
nbg=strehl.nbg
path=strehl.path
list=strehl.list
autofind=strehl.autofind

if (list ne 'none') then begin
    dum=findfile(list,count=count)
    if (count gt 0) then begin
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
            widget_control,strehl.err_text,set_value=filename_bg+' does not exist, background set to 0.'
            bgerrs=1.
        endif else bg=bg+thisbg
    endfor

    bg=bg/nbg
endif

if bgerrs eq 1 then begin ; if there is a background error, treat as if bg does not exist
    bg=0.
    nbg=0.
endif

; could implement something clever here to verify that the exposure times and filters were the same for the background for the images. Also check for images sizes!!!

for c1=0,nim-1 do begin

    if (list eq 'none') then begin
        strehl.imno=c1+im1
        if strehl.imno lt 10 then strehl.filename_im=path+'/n000'+strcompress(strehl.imno,/remove_all)+'.fits'
        if (strehl.imno ge 10)*(strehl.imno lt 100) then strehl.filename_im=path+'/n00'+strcompress(strehl.imno,/remove_all)+'.fits'
        if (strehl.imno ge 100)*(strehl.imno lt 1000) then strehl.filename_im=path+'/n0'+strcompress(strehl.imno,/remove_all)+'.fits'
        if (strehl.imno ge 1000)*(strehl.imno lt 10000) then strehl.filename_im=path+'/n'+strcompress(strehl.imno,/remove_all)+'.fits'
    endif else begin
        strehl.imno=c1
        strehl.filename_im=strcompress(files[c1],/REMOVE)
        ;;strehl.filename_im=path+strcompress(files[c1],/REMOVE)
    endelse

    fitsim=readfits(strehl.filename_im,hd,/silent)
    if n_elements(fitsim) eq 1 then begin
        widget_control,strehl.err_text,set_value=string(strehl.filename_im)+' does not exist, exiting.'
        retall
    endif

;Modified by S. Hornstein to properly extract camera info
    camera = SXPAR(hd, 'CAMNAME')
    strehl.camera=strcompress(camera,/REMOVE_ALL)
    pmsname = SXPAR(hd, 'PMSNAME')
    strehl.wavelength=SXPAR(hd, 'EFFWAVE')*1e-6
    strehl.pupil_angle = 0      ; SXPAR(hd, 'ROTDEST')
    strehl.coadds=sxpar(hd,'COADDS')
    filter=sxpar(hd,'FILTER')
    strehl.filt=which_filter(filter)
    if strehl.filt eq '-1' then begin
        message,/info, 'Cannot read the filter, returning'
        return
    endif
;Modified by S. Hornstein to include root path
    strehl.dl_im=readfits(root+strehl.filt+'.fits',/silent)

    case strehl.camera of
        'narrow': begin
            strehl.photrad=strehl.photon_radius*100.
            strehl.radius=10.
            strehl.plate_scale=9.94
        end

        'medium': begin
            strehl.photrad=strehl.photon_radius*50.
;                strehl.dl_im=rebin(strehl.dl_im,256,256)
            dl_im_temp=rebin(strehl.dl_im,256,256)
            strehl.dl_im=pad_image(dl_im_temp,512)
            strehl.radius=5.
            strehl.plate_scale=9.94*2
        end

        'wide': begin
            strehl.photrad=strehl.photon_radius*25.
;                strehl.dl_im=rebin(strehl.dl_im,128,128)
            dl_im_temp=rebin(strehl.dl_im,128,128)
            strehl.dl_im=pad_image(dl_im_temp,512)
            strehl.radius=3.
            strehl.plate_scale=9.94*4
        end

        '0': begin
            strehl.photrad=strehl.photon_radius*100.
            strehl.radius=10.
            strehl.plate_scale=10.2
            strehl.coadds=1
            strehl.wavelength=2.2135*1e-6
        end
    endcase

                                ; find the maximum using the diffraction-limited image, strehl.dl_im
    box=strehl.radius*2+1
    ctr=(size(strehl.dl_im))(1)/2 ; center of the diffraction-limited image
    dlpeak=find_peak(strehl.dl_im,ctr,ctr,box)

                                ; find the total flux in the image
    refflux=bmacaper(strehl.dl_im,strehl.photrad,ctr,ctr,strehl.photrad+20,strehl.photrad+30,maskkcam=0,skyval=0.)
                                ; find the reference intensity
    strehl.strehlone=dlpeak/refflux(0)

    xs=(size(fitsim))(1)
    ys=(size(fitsim))(2)
    blx=512-xs/2
    bly=512-ys/2
    urx=round(511+xs/2.)
    ury=round(511+ys/2.)

    ; Coordinates into the fits image
    flx = 0 & fly = 0 & frx = xs-1 & fry = ys-1

    ; Do some calcs for over-large images (larger than 1024)
    if (blx lt 0) then begin
        flx = -blx & blx = 0
    endif
    if (bly lt 0) then begin
        fly = -bly & bly = 0
    endif
    if (urx gt 1023) then begin
        frx = flx + 1023 & urx = 1023
    endif
    if (ury gt 1023) then begin
        fry = fly + 1023 & ury = 1023
    endif

    currentim=fix_image(fitsim-bg)
    strehl.currentim=fltarr(1024,1024)
    strehl.currentim[blx:urx,bly:ury]=currentim[flx:frx,fly:fry]
    calc_and_display,strehl
;	sxaddpar,hd,'STREHL',strehl.strehlim
;       writefits,strehl.filename_im,currentim,hd
endfor

return

end















