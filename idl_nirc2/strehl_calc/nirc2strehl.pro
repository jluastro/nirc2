;+
; NAME:
; 	NIRC2STREHL
;
; PURPOSE:
;	Compute the Strehl of an image taken with the NIRC2 instrument.
;
; EXPLANATION:
;	Finds the brightest non-saturated star in the field and computes
;	its Strehl ratio, or uses star at given pixel location
;
; CALLING SEQUENCE:
;	result = NIRC2STREHL(image, [HD=, POS=, CAMNAME=, 
;		PMSNAME=, EFFWAVE=, PMRANGL=, /SILENT ])
;
; INPUTS:
;	im = NIRC2 image with at least one point source.
;	  For best results, use reduced (or at least sky-subtracted) images.
;
; OUTPUTS:
;	result = Strehl ratio (floating point number between 0 and 1)
;
; OPTIONAL INPUT KEYWORDS:
;	HD - String array containing the FITS header associated with the
;		image.  If this is included, the keywords CAMNAME, PMSNAME,
;		EFFWAVE, and PMRANGL are not necessary.
;
;       POS - position of star to compute Strehl from.  By default, the
;		strehl of the brightest object is computed.
;
;	The following 4 kewords override the header fields in HD if set:
;
;	CAMNAME - camera name, eg. 'narrow'.
;
;	PMSNAME - pupil stop name, eg. 'largehex'.
;
;	EFFWAVE - effective wavelength of filter in microns.
;
;	PMRANGL - pupil drive's angular position, in degress.
;
;	FILENAME - if specified, will load image and header from this filename.
;
;	/SILENT - Suppress status messages.
;
; EXAMPLE:
;	flist = FINDFILE('/s/sdata904/nirc2eng/*/n????.fits')
;	im = READFITS(flist[0],hd)
;	strehl = NIRC2STREHL(im,hd=hd)
;
; ERROR HANDLING:
;	To be determined.
;
; RESTRICTIONS:
;	No effor is made to distinguish point from extended sources when
;	finding brightest object.  The brightest object had therefore better
;	be a star for the Strehl to be meaningful.
;
; NOTES:
;	None yet.
;
; PROCEDURES USED:
;	Functions:	NIRC2PSF(), NIRC2PUPIL()
;
; MODIFICATION HISTORY:
;-
@bmacaper.pro
@cntrd.pro
@fwhmastro.pro

FUNCTION NIRC2STREHL, im, HD=hd, POS=pos, CAMNAME=camname, PMSNAME=pmsname, $
		EFFWAVE=effwave, PMRANGL=pmrangl, BGVAL=BGVAL, $
		PHOTONRADIUS=PHOTONRADIUS,FILENAME=filename, SILENT=silent

  if KEYWORD_SET(filename) then $
    im = READFITS(filename, hd, silent=silent)
  if KEYWORD_SET(hd) then begin
    if not KEYWORD_SET(camname) then camname = SXPAR(hd, 'CAMNAME')
    if not KEYWORD_SET(pmsname) then pmsname = SXPAR(hd, 'PMSNAME')
    if not KEYWORD_SET(effwave) then effwave = SXPAR(hd, 'EFFWAVE')
    if not KEYWORD_SET(pmrangl) then pmrangl = SXPAR(hd, 'PMRANGL')
  endif else begin
    if not KEYWORD_SET(camname) then camname = 'narrow'
    if not KEYWORD_SET(pmsname) then pmsname = 'largehex'
    if not KEYWORD_SET(effwave) then effwave = 2.12450
    if not KEYWORD_SET(pmrangl) then pmrangl = 0.
  endelse
  if not KEYWORD_SET(photonradius) then photonradius=1.; photometry radius

;;; 1. Find star to nearest pixel.

   if not KEYWORD_SET(pos) then begin   ; find the location of the star
      ismooth=im
      maxval = max(ismooth,index)
      sz=size(im)	
      xcur = index mod sz(1)
      ycur = index / sz(2)
   endif else begin
      xcur=pos(0)
      ycur=pos(1)  	
   endelse
 
;;; 2. Create PSF at same pixel position.
  psf = NIRC2PSF(camname=camname, pmsname=pmsname, $
                 effwave=effwave, pmrangl=pmrangl)

;;; 3. Perform aperture photometry on both star and PSF
  ; calculate the photometry radius in pixels
  if camname eq 'narrow' then begin
	plate_scale=9.94e-3 
	radius=10.
  endif
  if camname eq 'medium' then begin
	plate_scale=9.94e-3*2.
	radius=5.
  endif
  if camname eq 'wide' then begin
	plate_scale=9.94e-3*4.
	radius=3.
  endif

  photrad=fix(photonradius/plate_scale); photon radius in pixels
  box=2.*radius+1.

  starflux=bmacaper(im,photrad,x,y,photrad+20,photrad+30,maskkcam=0,skyout=apersky,/draw,skyval=bgval)
  
  psfflux=bmacaper(psf,photrad,x,y,photrad+20,photrad+30,maskkcam=0,skyout=apersky,/draw,skyval=0.)

;;; 4. Find the peak of both the star and the PSF 

   cntrd,image,xcur,ycur,x,y,radius,/silent
   if (x ne -1 and y ne -1) then begin
        fwhmastro,im,x,y,box,params
        peak=find_peak(im,x,y,box)
        params(1)=peak
        xsig=params(2)
        ysig=params(3)
        xc=params(4)
        yc=params(5)
        fwhm=(xsig+ysig)*2.355/2.*plate_scale
   endif else begin
	if not KEYWORD_SET(silent) then print, 'Cannot find the star'	
	return, 0
   endelse

    x=fix((size(psf))(1)/2.)
    y=fix((size(psf))(2)/2.)
	
    psfpeak=find_peak(psf,x,y,box)
   
    strehl = (peak/starflux)/(psfpeak/psfflux)

   if not KEYWORD_SET(silent) then $ ; print out all the results
      print, ' S = '+string(strehl,format='$(f5.3)')+' RMS err = ' +string(rms_error,format='$(f6.1)')+' nm  '+'FWHM = '+string(fwhm,format='$(f6.2)')+' mas'
   
RETURN,strehl
END

