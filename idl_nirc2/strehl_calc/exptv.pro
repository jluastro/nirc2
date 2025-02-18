	PRO EXPTV,ARRAY,NOSQUARE=NOSQUARE,SMOOTH=SMOOTH,NOBOX=NOBOX,	$
		NOSCALE=NOSCALE,MISSING=MISSING,SIZE=SIZE,DISABLE=DISABLE, $
		NOEXACT=NOEXACT,XALIGN=XALIGN,YALIGN=YALIGN,RELATIVE=RELATIVE,$
		COLOR=COLOR,MAX=MAX,MIN=MIN,TOP=TOP,VELOCITY=VELOCITY, $
		COMBINED=COMBINED,LOWER=LOWER,NORESET=NORESET,ORIGIN=ORIGIN, $
		SCALE=SCALE,DATA=DATA,ADJUST=ADJUST,TRUE=K_TRUE
;+
; Project     : SOHO - CDS
;
; Name        : 
;	EXPTV
; Purpose     : 
;	Uses SCALE_TV and EXPAND_TV to display an image.
; Explanation : 
;	SCALE_TV is called to scale the image, and EXPAND_TV is called to 
;	display the image.  As much of the image display screen as possible is 
;	filled.
;
;	Will plot true color images if the device has enough colors and if
;	ARRAY is a 3D Array with the third dimension color (red, green, blue).
;	(See also the TRUE keyword.)
;
; Use         : 
;	EXPTV, ARRAY
; Inputs      : 
;	ARRAY	 = Two dimensional image array to be displayed, or 3 images in 
;		   an array [Nx,Ny,3] to be displayed as a true color image.
;		   (See also the TRUE keyword.)
; Opt. Inputs : 
;	None.
; Outputs     : 
;	None.
; Opt. Outputs: 
;	None.
; Keywords    : 
;	NOSQUARE = If passed, then pixels are not forced to be square.
;	SMOOTH	 = If passed, then image is expanded with interpolation.
;	NOBOX	 = If passed, then box is not drawn, and no space is reserved
;		   for a border around the image.
;	NOSCALE	 = If passed, then the command TV is used instead of TVSCL to
;		   display the image.
;	MISSING	 = Value flagging missing pixels.  These points are scaled to
;		   zero.  Ignored if NOSCALE is set.
;	SIZE	 = If passed and positive, then used to determine the scale of
;		   the image.  Returned as the value of the image scale.  May
;		   not be compatible with /NOSQUARE.
;	DISABLE  = If set, then TVSELECT not used.
;	NOEXACT  = If set, then exact scaling is not imposed.  Otherwise, the
;		   image scale will be either an integer, or one over an
;		   integer.  Ignored if SIZE is passed with a positive value.
;	XALIGN	 = Alignment within the image display area.  Ranges between 0
;		   (left) to 1 (right).  Default is 0.5 (centered).
;	YALIGN	 = Alignment within the image display area.  Ranges between 0
;		   (bottom) to 1 (top).  Default is 0.5 (centered).
;	RELATIVE = Size of area to be used for displaying the image, relative
;		   to the total size available.  Must be between 0 and 1.
;		   Default is 1.  Passing SIZE explicitly will override this
;		   keyword.
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
;	NORESET	 = If set, then SETIMAGE is not called, and the screen is not
;		   erased.
;	ORIGIN	 = Two-element array containing the coordinate value in
;		   physical units of the center of the first pixel in the
;		   image.  If not passed, then [0,0] is assumed.
;	SCALE	 = Pixel scale in physical units.  Can have either one or two
;		   elements.  If not passed, then 1 is assumed in both
;		   directions.
;	DATA	 = If set, then immediately activate the data coordinates for
;		   the displayed image.
;	ADJUST	 = If set, then adjust the pixel size separately in the two
;		   dimensions, so that the physical scale given by the SCALE
;		   parameter is the same along both axes.  For example, if a
;		   100x100 image is displayed with
;
;			EXPTV, A, SCALE=[2,1], /ADJUST
;
;		   then it will be shown twice as wide as it is high.  Use of
;		   this keyword forces NOEXACT to also be set.  Also, NOSQUARE
;		   is ignored.
;	TRUE	 = If passed, then contains the dimension containing the color
;		   dimension.  For example, if the input array has the
;		   dimensions (3,Nx,Ny), then one would set TRUE=1.  If not
;		   passed, then TRUE=3 is assumed.  Ignored if the image only
;		   has two dimensions.
;
; Calls       : 
;	EXPAND_TV, GET_IM_KEYWORD, SCALE_TV, SETIMAGE, TVERASE
; Common      : 
;	None.
; Restrictions: 
;	ARRAY must be two-dimensional.
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
;	The image display window is erased before the image is displayed, and
;	SETIMAGE is called to reset to the default, unless NORESET is set.
;
;	Messages about the size and position of the displayed image are printed
;	to the terminal screen.  This can be turned off by setting !QUIET to 1.
;
; Category    : 
;	Utilities, Image_display.
; Prev. Hist. : 
;	W.T.T., Oct. 1987.
;	W.T.T., Jan. 1991, added BADPIXEL keyword.
;	W.T.T., Feb. 1991, modified to use common block IMAGE_AREA.
;	W.T.T., Feb. 1991, added SIZE keyword.
;	W.T.T., Nov. 1991, added MAX, MIN, and TOP keywords.
;	W.T.T., Nov. 1991, added INTENSITY, VELOCITY and COMBINED keywords.
;	W.T.T., Feb. 1992, added LOWER keyword.
;	W.T.T., Feb. 1992, added call to SETIMAGE, removed common block, and
;			   added keyword NORESET.
;	William Thompson, August 1992, renamed BADPIXEL to MISSING.
;	William Thompson, September 1992, use COMBINED keyword in place of
;					  INTENSITY.
; Written     : 
;	William Thompson, GSFC, October 1987.
; Modified    : 
;	Version 1, William Thompson, GSFC, 13 May 1993.
;		Incorporated into CDS library.
;	Version 2, William Thompson, GSFC, 2 September 1993.
;		Added ORIGIN, SCALE and DATA keywords.
;	Version 3, William Thompson, GSFC, 25 July 1996
;		Added keywords SCALE and ADJUST
;	Version 4, William Thompson, GSFC, 13 November 2001
;		Added capability for true-color images.
; Version     : 
;	Version 4, 16 November 2001
;-
;
	ON_ERROR,2
	GET_IM_KEYWORD, MISSING, !IMAGE.MISSING
;
;  Check the number of parameters.
;
	IF (N_PARAMS(0) NE 1) THEN BEGIN
		PRINT,'*** EXPTV must be called with one parameter:'
		PRINT,'                     ARRAY'
		RETURN
	ENDIF
;
;  Check the dimensions of ARRAY.
;
	S = SIZE(ARRAY)
	SX = S(1)
	SY = S(2)
	SZ = 0
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
	ENDIF
	ARRAY_TYPE = S(S(0) + 1)
	IF (S(0) NE 2) AND (SZ NE 3) THEN MESSAGE,		$
		'ARRAY must be two-dimensional or an array of three 2D images' 
        IF SZ EQ 3 AND !D.N_COLORS LE 256 THEN MESSAGE,	$
		'This screen cannot show true color images.'
;
;  If using the whole screen, then remove any previous settings.
;
	IF NOT KEYWORD_SET(NORESET) THEN SETIMAGE
;
;  Call SCALE_TV to calculate MX, MY and JX, JY.
;
	SCALE_TV,ARRAY,MX,MY,JX,JY,NOSQUARE=NOSQUARE,SIZE=SIZE,NOBOX=NOBOX, $
		DISABLE=DISABLE,NOEXACT=NOEXACT,XALIGN=XALIGN,YALIGN=YALIGN,$
		RELATIVE=RELATIVE,SCALE=SCALE,ADJUST=ADJUST,TRUE=K_TRUE
;
;  If using the whole screen, then first erase it.
;
	IF NOT KEYWORD_SET(NORESET) THEN TVERASE,DISABLE=DISABLE
;
;  Call EXPAND_TV to expand ARRAY to the proper dimensions and display it on
;  the image display screen.
;
	EXPAND_TV,ARRAY,MX,MY,JX,JY,SMOOTH=SMOOTH,NOBOX=NOBOX,  $
		NOSCALE=NOSCALE,MISSING=MISSING,DISABLE=DISABLE,	$
		COLOR=COLOR,MAX=MAX,MIN=MIN,TOP=TOP,VELOCITY=VELOCITY,	$
		COMBINED=COMBINED,LOWER=LOWER,ORIGIN=ORIGIN,SCALE=SCALE,$
		DATA=DATA,TRUE=K_TRUE
;
	RETURN
	END

