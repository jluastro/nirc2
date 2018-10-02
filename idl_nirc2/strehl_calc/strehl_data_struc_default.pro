
 strehl={  	$
         mainwid:               1l,   $ ; id of main widget
         tvid:                  [0l,0l,0l],   $
         err_text:    'void string',     $
         timer_param:                   0l,   $
         optionid:      lonarr(20),    $ ; some ids
         im1:                   1l,   $ ; first image
         nim:                   1l,   $ ; number of images
         bg1:                   2l,   $ ; first background
         nbg:                   0l,   $ ; number of backgrounds
         imno:                   0l,   $ ; the current image number
         filename_im:           '',    $ ; filename of the image
         path:                  './',    $ ; path to directory
         list:                  'none',  $ ; list of files
         output:                'none',  $ ; output list
         silent:                     0,  $ ; silent flag
         autofind:                1,    $ ; autofind ON
         holo:                0,    $ ; speckle holography False
         autoimage:               0,    $ ; autoimage set to OFF
         wavelength:            1.58e-6, $ ; central wavelength
         pupil_angle:                0., $ ; the angle of the pupil
         filt:                   'hcont', $ ; filter name
         mjd:                   0d0, $ ; Modified Julian Date
         coadds:                  1B, $ ; number of coadds in image
         currentim:             fltarr(1024,1024), $ ; current image
         photon_radius:                1., $ ;radius over which photometry is taken in arcsec
         photrad:                     100.,$ ; radius in pixels
         radius:                       -1., $ ; radius in pixels used to do the gaussian fit
         starflux:                     0., $ ;measured flux from previous images
         camera:                  'narrow', $ ;
         strehlim:       0., $  ; strehl output
         fwhm:           0., $  ;
         plate_scale:   9.94, $ ; plate scale of nirc2
         dl_im:         fltarr(512,512), $ ; diffraction limited image
         strehlone:                    1.,$ the reference strehl
         last_file: strarr(1)                   $ ; last image file
 }
