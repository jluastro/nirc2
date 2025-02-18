	PRO EXPAND_TV,ARRAY,MX,MY,IX,IY,SMOOTH=SMOOTH,NOBOX=NOBOX,	$
		NOSCALE=NOSCALE,MISSING=MISSING,DISABLE=DISABLE,	$
		COLOR=COLOR,MAX=MAX,MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,	$
		COMBINED=COMBINED,LOWER=LOWER,NOSTORE=NOSTORE,		$
		ORIGIN=ORIGIN,SCALE=SCALE,DATA=DATA,TRUE=K_TRUE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	EXPAND_TV
; Purpose     : 
;	Expands and displays an image.
; Explanation : 
;	This procedure expands an image to the dimensions MX, MY and displays
;	it at position IX, IY on the image display screen.  Called from EXPTV
;	and other routines.
;
;	The scaling parameters MX,MY and IX,IY are stored using STORE_TV_SCALE
;	for later retrieval using GET_TV_SCALE.
;
; Use         : 
;	EXPAND_TV, ARRAY, MX, MY, IX, IY
; Inputs      : 
;	ARRAY	= Image to be displayed.
;	MX, MY	= Dimensions to expand image to.
;	IX, IY	= Position of lower left-hand corner of image.
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	SMOOTH	 = If set, then the image is expanded with bilinear
;		   interpolation.  For most devices, the smoothing is done to
;		   the resolution of the device, but PostScript is handled
;		   differently.  The default smoothing factor for PostScript
;		   output is 10, but other factors can be selected by setting
;		   SMOOTH to the amount of smoothing desired.  Setting SMOOTH=1
;		   is the same as using /SMOOTH, and selects the default value
;		   of 10.  Note that the size of the PostScript file will go as
;		   the square of the amount of smoothing.
;	NOBOX	 = If set, then the box is not drawn around the image.
;	NOSCALE  = If set, then the command TV is used instead of TVSCL to
;		   display the image.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
;	DISABLE  = If set, then TVSELECT not used.
;	COLOR	 = Color used for drawing the box around the image.
;	MAX	 = The maximum value of ARRAY to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the maximum value
;		   of ARRAY.
;	MIN	 = The minimum value of ARRAY to be considered in scaling the
;		   image, as used by BYTSCL.  The default is the minimum value
;		   of ARRAY.
;	TOP	 = The maximum value of the scaled image array, as used by
;		   BYTSCL.  The default is !D.N_COLORS-1.
;	VELOCITY = If set, then the image is scaled using FORM_VEL as a
;		   velocity image.  Can be used in conjunction with COMBINED
;		   keyword.  Ignored if NOSCALE is set.
;	COMBINED = Signals that the image is to be displayed in one of two
;		   combined color tables.  Can be used by itself, or in
;		   conjunction with the VELOCITY or LOWER keywords.
;	LOWER	 = If set, then the image is placed in the lower part of the
;		   color table, rather than the upper.  Used in conjunction
;		   with COMBINED keyword.
;	NOSTORE	 = If set, then information about the position of the plot is
;		   not stored in the TV_SCALE common block.  This is for
;		   special purpose images, such as generated by COLOR_BAR or
;		   PLOT_IMAGE.
;	ORIGIN	 = Two-element array containing the coordinate value in
;		   physical units of the center of the first pixel in the
;		   image.  If not passed, then [0,0] is assumed.  Ignored if
;		   NOSTORE is set.
;	SCALE	 = Pixel scale in physical units.  Can have either one or two
;		   elements.  If not passed, then 1 is assumed in both
;		   directions.  Ignored if NOSTORE is set.
;	DATA	 = If set, then immediately activate the data coordinates for
;		   the displayed image.  Ignored if NOSTORE is set.
;	TRUE	 = If passed, then contains the dimension containing the color
;		   dimension.  For example, if the input array has the
;		   dimensions (3,Nx,Ny), then one would set TRUE=1.  If not
;		   passed, then TRUE=3 is assumed.  Ignored if the image only
;		   has two dimensions.
;
; Calls       : 
;	BSCALE, CONGRDI, GET_IM_KEYWORD, IM_KEYWORD_SET, STORE_TV_SCALE, TRIM,
;	TVSELECT, TVUNSELECT
; Common      : 
;	None.
; Restrictions: 
;	ARRAY must be two-dimensional or an array of three 2-D images (Nx,Ny,3)
;	to be used for true color.  (See also the TRUE keyword.)
;
;	In general, the SERTS image display routines use several non-standard
;	system variables.  These system variables are defined in the procedure
;	IMAGELIB.  It is suggested that the command IMAGELIB be placed in the
;	user's IDL_STARTUP file.
;
;	Some routines also require the SERTS graphics devices software,
;	generally found in a parallel directory at the site where this software
;	was obtained.  Those routines have their own special system variables.
;
; Side effects: 
;	Messages about the size and position of the displayed image are printed
;	to the terminal screen, if the DEBUG environment variable is set.
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Jan. 1990, added BADPIXEL keyword.
;	W.T.T., Feb. 1991, modified to use TVSELECT, TVUNSELECT.
;	W.T.T., Nov. 1991, added MAX, MIN, and TOP keywords.
;	W.T.T., Nov. 1991, added INTENSITY, VELOCITY and COMBINED keywords.
;	W.T.T., Feb. 1992, added LOWER keyword.
;	W.T.T., May  1992, modified to use BSCALE.
;	William Thompson, May 1992, modified to call STORE_TV_SCALE.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;					  INTENSITY.  Also, sped up by using
;					  REBIN when possible.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 2 September 1993.
;		Added ORIGIN, SCALE and DATA keywords.
;	Version 3, William Thompson, GSFC, 10 June 1996
;		Use DPRINT instead of MESSAGE for informational messages.
;	Version 4, William Thompson, GSFC, 4 March 1998
;		Allow SMOOTH to have an effect on PostScript images.
;	Version 5, Terry Kucera, GSFC, 16 October 2001
;		Automatically does a true color display if the third array
;		dimension = 3
;	Version 6, William Thompson, GSFC, 13 November 2001
;		Added keyword TRUE
;	Version 7, William Thompson, GSFC, 18 December 2002
;		Changed !COLOR to !P.COLOR
; Version     : 
;	Version 7, 18 December 2002
;-
;
        ON_ERROR,2
        GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
;  Check the number of parameters.
;
	IF (N_PARAMS(0) NE 5) THEN BEGIN
		PRINT,'*** EXPAND_TV must be called with five parameters:'
		PRINT,'             ARRAY, MX, MY, IX, IY'
		RETURN
	ENDIF
;
;  Check the dimensions of the final image.
;
	IF (MX LE 0) OR (MY LE 0) THEN BEGIN
		PRINT,'*** Unable to expand array, routine EXPAND_TV.'
		RETURN
	ENDIF
;
;  Check the dimensions of ARRAY.
;
	S = SIZE(ARRAY)
	ARRAY_TYPE = S(S(0) + 1)
	IF S(0) EQ 3 THEN BEGIN
	    IF N_ELEMENTS(K_TRUE) EQ 1 THEN TRUE=K_TRUE ELSE TRUE=3
	    CASE TRUE OF
		1:  BEGIN
		    SX = S(2)
		    SY = S(3)
		    SZ = S(1)
		    END
		2:  BEGIN
		    SX = S(1)
		    SY = S(3)
		    SZ = S(2)
		    END
		ELSE: BEGIN
		    TRUE = 3
		    SX = S(1)
		    SY = S(2)
		    SZ = S(3)
		    END
	    ENDCASE
	ENDIF ELSE BEGIN
	    SX = S(1)
	    SY = S(2)
	    SZ = 1
	    TRUE=0
	ENDELSE
	IF (S(0) NE 2) AND (SZ NE 3) THEN MESSAGE,		$
		'ARRAY must be two-dimensional or an array of three 2D images'
;
;  Select the image display device or window.
;
	TVSELECT, DISABLE=DISABLE
;
;  If the image display device is a Tektronix terminal, recalculate the image
;  display parameters to reflect the fact that the IDL device coordinates are
;  not true device coordinates.
;
	MMX = MX  &  MMY = MY
	IIX = IX  &  IIY = IY
	IF !D.NAME EQ 'TEK' THEN BEGIN
		IIX = FIX(  IX           / 4. )
		MMX = FIX( (IX + MX - 1) / 4. )           - IIX + 1
		IIY = FIX(  IY           * 768. / 3277. )
		MMY = FIX( (IY + MY - 1) * 768. / 3277. ) - IIY + 1
	ENDIF
;
;  If the image display device is a PostScript printer, then don't resize the
;  image, but calculate the scaling factors XSIZE and YSIZE.  If either of the
;  dimensions is odd, then modify the parameters by either multiplying by two
;  (small images) or adding one (large images).
;
	XSIZE = MX
	YSIZE = MY
	IF !D.NAME EQ 'PS' THEN BEGIN
	    IF IM_KEYWORD_SET(SMOOTH,!IMAGE.SMOOTH) THEN BEGIN
		IF N_ELEMENTS(SMOOTH) EQ 1 THEN NSMOOTH = SMOOTH ELSE	$
			NSMOOTH = !IMAGE.SMOOTH
		IF NSMOOTH LE 1 THEN NSMOOTH = 10
		MMX = NSMOOTH * SX
		MMY = NSMOOTH * SY
	    END ELSE BEGIN
		MMX = SX
		MMY = SY
	    ENDELSE
	    IF (MMX MOD 2) NE 0 THEN $
		    IF MMX LE 100 THEN MMX = 2*MMX ELSE MMX = MMX + 1
	    IF (MMY MOD 2) NE 0 THEN $
		    IF MMY LE 100 THEN MMY = 2*MMY ELSE MMY = MMY + 1
	ENDIF
;
;  Expand the image.
;

	IF (MMX NE SX) OR (MMY NE SY) THEN BEGIN
	    IF IM_KEYWORD_SET(SMOOTH,!IMAGE.SMOOTH) THEN BEGIN
		IF SZ EQ 1 THEN B = CONGRDI(ARRAY,MMX,MMY) ELSE BEGIN
		    CASE TRUE OF
			1:  BEGIN
			    B= FLTARR(SZ,MMX,MMY)
			    FOR I=0,SZ-1 DO B(I,*,*) =	$
				    CONGRDI(REFORM(ARRAY(I,*,*)),MMX,MMY)
			    END
			2:  BEGIN
			    B= FLTARR(MMX,SZ,MMY)
			    FOR I=0,SZ-1 DO B(*,I,*) =	$
				    CONGRDI(REFORM(ARRAY(*,I,*)),MMX,MMY)
			    END
			ELSE:  BEGIN
			    B= FLTARR(MMX,MMY,SZ)
			    FOR I=0,SZ-1 DO B(*,*,I) =	$
				    CONGRDI(ARRAY(*,*,I),MMX,MMY)
			    END
		    ENDCASE
		ENDELSE
	    END ELSE BEGIN
	        CASE TRUE OF
		    1:  BEGIN
			M1 = SZ
			M2 = MMX
			M3 = MMY
			END
		    2:  BEGIN
			M1 = MMX
			M2 = SZ
			M3 = MMY
			END
		    ELSE:  BEGIN
			M1 = MMX
			M2 = MMY
			M3 = SZ
			END
		ENDCASE
		IF (FIX(MMX/SX)*SX EQ MMX) AND (FIX(MMY/SY)*SY EQ MMY)	$
			THEN B = REBIN(ARRAY,M1,M2,M3,/SAMPLE)	$
			ELSE B = CONGRID(ARRAY,M1,M2,M3)
		ENDELSE
	END ELSE B = ARRAY
	DPRINT, 'Array was expanded to ' + TRIM(MX) + ' x ' + TRIM(MY) + '.'
;
;  Scale the image.
;
	BSCALE,B,NOSCALE=NOSCALE,MISSING=MISSING,MAX=MAX,MIN=MIN,TOP=TOP, $
		VELOCITY=VELOCITY,COMBINED=COMBINED,LOWER=LOWER
;
;  Display the image.
;
	TV,B,IIX,IIY,XSIZE=XSIZE,YSIZE=YSIZE,/DEVICE,TRUE=TRUE
	DPRINT, 'Image displayed at (' + TRIM(IX) + ',' + TRIM(IY) + ').'
;
;  Draw a box around the image.
;
	IF NOT IM_KEYWORD_SET(NOBOX,!IMAGE.NOBOX) THEN BEGIN
		X = [ IX-1, IX+MX, IX+MX, IX-1 , IX-1 ]
		Y = [ IY-1, IY-1 , IY+MY, IY+MY, IY-1 ]
		IF N_ELEMENTS(COLOR) NE 1 THEN COLOR = !P.COLOR
		PLOTS,X,Y,/DEVICE,COLOR=COLOR
	ENDIF
;
;  Store the information about the image for later retrieval.
;
	IF NOT KEYWORD_SET(NOSTORE) THEN	$
		STORE_TV_SCALE, SX, SY, MX, MY, IX, IY, ORIGIN=ORIGIN,	$
			SCALE=SCALE, /DISABLE
;
;  Return to the previous device or window.
;
	TVUNSELECT, DISABLE=DISABLE
;
;  If the DATA keyword was passed, then activate the coordinates of the
;  displayed image.
;
	IF KEYWORD_SET(DATA) AND (NOT KEYWORD_SET(NOSTORE)) THEN	$
		SETIMAGE, /CURRENT, /DATA, DISABLE=DISABLE
;
	RETURN
	END

