
; creates a widget to find the Strehl

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This part of the script is the event handler for the updatecog widget.
pro strehl_event,event

widget_control,event.id,get_uvalue=ev
widget_control,event.top,get_uvalue=strehl

;; check to see if the images have updated
if strehl.autoimage eq 1 then begin
    files=findfile(strehl.path)
    last_file=files(n_elements(files)-1)
    if last_file ne strehl.last_file then begin
        strehl.last_file=last_file
        strehl.nim=1.           ; one image
        strehl.im1=float(strmid(strehl.last_file,1,4))
        widget_control,event.top,set_uvalue=strehl
        
        widget_control,strehl.optionid[2],get_value=temp
        strehl.bg1=temp(0)
        widget_control,strehl.optionid[3],get_value=temp
        strehl.nbg=temp(0)
        widget_control,strehl.optionid[14],get_value=temp
        strehl.photon_radius=temp(0)
        widget_control,strehl.optionid[4],get_value=temp
        strehl.path=temp(0)
        
        find_strehl,strehl
    endif
endif

;;; this is the time event that is checking for the trigger
;; the timer is set to 0.5 seconds (see below)

if event.id eq strehl.timer_param then begin


    widget_control,event.id,timer=0.5 ; check and update the screen every second
    return

endif

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

widget_control,event.id,get_uvalue=ev

;;;  below we are checking for trigger from the widget
case ev of
;;;;;;;;;;;;;;;;

    'im1_opt' : begin
        widget_control,strehl.optionid[0],get_value=temp
        strehl.im1=temp(0)
    end
    
    'nim_opt' : begin
        widget_control,strehl.optionid[1],get_value=temp
        strehl.nim=temp(0)
    end
    
    'bg1_opt' : begin
        widget_control,strehl.optionid[2],get_value=temp
        strehl.bg1=temp(0)
    end

    'nbg_opt' : begin
        widget_control,strehl.optionid[3],get_value=temp
        strehl.nbg=temp(0)
    end

    'photrad_opt' : begin
        widget_control,strehl.optionid[14],get_value=temp
        strehl.photon_radius=temp(0)
    end

    'path_opt' : begin
        widget_control,strehl.optionid[4],get_value=temp
        strehl.path=temp(0)
        widget_control,strehl.optionid[4],set_value=strehl.path
    end

    'list_opt' : begin
        widget_control,strehl.optionid[17],get_value=temp
        strehl.list=temp(0)
        widget_control,strehl.optionid[17],set_value=strehl.list
    end

    'output_opt' : begin
        widget_control,strehl.optionid[18],get_value=temp
        strehl.output=temp(0)
        widget_control,strehl.optionid[18],set_value=strehl.output
    end

    'autofind' : begin
        widget_control,strehl.optionid[7],get_value=temp
        strehl.autofind=temp(0)
        bstring=['OFF','ON']
        widget_control,strehl.err_text,set_value='Autofind set to '+bstring(strehl.autofind)
    end

    'autoimage' : begin
        widget_control,strehl.optionid[8],get_value=temp
        strehl.autoimage=temp(0)
        bstring=['OFF','ON']
        widget_control,strehl.err_text,set_value='Find the Strehl of the last image automatically set to '+bstring(strehl.autoimage)
    end

    
;;;;;;;;;;;;;;;;
    
;;;;;;;;;;;;;;;;
;; GO!
    'go' : begin
        
        widget_control,strehl.mainwid,set_uvalue=strehl
        
        ;; read all the entries
        if strehl.autoimage eq 0 then begin
            widget_control,strehl.optionid[0],get_value=temp
            strehl.im1=temp(0)
            widget_control,strehl.optionid[1],get_value=temp
            strehl.nim=temp(0)
            strehl.last_file='n'+string(strehl.im1,format='(i4.4)')+'.fits'
        endif
        widget_control,strehl.optionid[2],get_value=temp
        strehl.bg1=temp(0)
        widget_control,strehl.optionid[3],get_value=temp
        strehl.nbg=temp(0)
        widget_control,strehl.optionid[14],get_value=temp
        strehl.photon_radius=temp(0)
        widget_control,strehl.optionid[4],get_value=temp
        strehl.path=temp(0)
        widget_control,strehl.optionid[17],get_value=temp
        strehl.list=temp(0)
        widget_control,strehl.optionid[18],get_value=temp
        strehl.output=temp(0)
        
        find_strehl,strehl
    end
    
;;;;;;;;;;;;;;;;
;; DISMISS
    'dismiss' : begin
        widget_control,event.top,/destroy
        return
    end
    
endcase


widget_control,strehl.mainwid,set_uvalue=strehl

return
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This Routine generates a widget to calculate the Strehl
pro strehl_widget,group=group
if (n_elements(group) eq 0) then group=0
;;
;;; set up strehl structure
;strehl = strehl_data_struc_default()        ;

loadct,0                        ; black and white
imagelib
devicelib

; Load up strehl struct
@strehl_data_struc_default

loadct,0                   ; set the display colors to black and white

; set the widget color
;spawn, 'xrdb ~/.Xdefaults' ; set the colors

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;   BUILDING THE WIDGET
;;;;

strehl.mainwid=widget_base(group_leader=group,column=2, map=1,title='Strehl tool', uvalue=strehl, resource_name='strehl')

;;  Defining the operation mode for the tool
wid1=widget_base(strehl.mainwid,column=1,map=1)
wid2=widget_base(strehl.mainwid,column=1,map=1)

;
;;;  base for displaying the size of the spot
base_params=widget_base(wid1, row=4,map=1,  frame=2, /sensitive,ysize=150)

im1_options=widget_base(base_params, row=1,map=1, /sensitive, /align_right)
im1=widget_label(im1_options, value='FIRST IMAGE :            ')
im1_nb=widget_text(im1_options,uvalue='im1_opt',/editable,xsize=4, value=string(strehl.im1,format='$(i0)'))

nim_options=widget_base(base_params, row=1,map=1, /sensitive,/align_right)
nim=widget_label(nim_options, value='NUMBER OF IMAGES :       ')
nim_nb=widget_text(nim_options,uvalue='nim_opt',/editable,xsize=4, value=string(strehl.nim,format='$(i0)'))

bg1_options=widget_base(base_params,row=1,map=1, /sensitive, /align_right)

bg1=widget_label(bg1_options,      value='FIRST BACKGROUND :       ')
bg1_nb=widget_text (bg1_options,uvalue='bg1_opt',/editable,xsize=4, value=string(strehl.bg1,format='$(i0)'))

nbg_options=widget_base(base_params,row=1,map=1, /sensitive, /align_right)
nbg=widget_label(nbg_options,      value='NUMBER OF BACKGROUNDS :  ')
nbg_nb=widget_text (nbg_options,uvalue='nbg_opt',/editable,xsize=4, value=string(strehl.nbg,format='$(i0)'))


; ~~~~~~~~

;;;  base for displaying the  directories
base_dir=widget_base(wid1, row=3,map=1,  frame=2, /sensitive)

;;;  base for displaying the directory
path_options=widget_base(base_dir, row=1,map=1, /sensitive, /align_right)

path=widget_label(path_options, value='PATH :')
path_nb=widget_text(path_options,uvalue='path_opt',/editable,xsize=31, value=strehl.path)

;;;  base for displaying the list directory

list_options=widget_base(base_dir, row=1,map=1, /sensitive, /align_right)
list=widget_label(list_options, value='LIST FILE :')
list_nb=widget_text(list_options,uvalue='list_opt',/editable,xsize=28, value=strehl.list)

;;;  base for displaying the output file directory

output_options=widget_base(base_dir, row=1,map=1, /sensitive, /align_right)
output=widget_label(output_options, value='OUTPUT FILE :')
output_nb=widget_text(output_options,uvalue='output_opt',/editable,xsize=28, value=strehl.output)

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; Add check boxes on the bottom base
check_options=widget_base(wid1, row=2,map=1, frame=2, /sensitive,resource_name='check_options')

bstring=['OFF','ON']
core2_base=widget_base (check_options,row=1, map=1)
core2_label=widget_label(core2_base,value='AUTOFIND         ')
autofind_check=cw_bgroup(core2_base,/row,/exclusive,uvalue='autofind',bstring)

widget_control,autofind_check,set_value=1

core2_base=widget_base (check_options,row=1, map=1)
core2_label=widget_label(core2_base,value='AUTO UPDATE IMAGE')
autoimage_check=cw_bgroup(core2_base,/row,/exclusive,uvalue='autoimage',bstring)
widget_control,autoimage_check,set_value=0

;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; ~~~~~~~~

;;;  base for displaying the photometry radius
photrad_options=widget_base(wid1, row=1,map=1,frame=2, /sensitive)
photrad=widget_label(photrad_options, value='PHOTOMETRY RADIUS : ')
photrad_nb=widget_text(photrad_options,uvalue='photrad_opt',/editable,xsize=5, value=string(strehl.photon_radius,format='$(f5.3)'))
photradunits=widget_label(photrad_options, value=' arcsec')

;;;  base for displaying the Strehl
strout_options=widget_base(wid1, row=1,map=1,frame=2,resource_name='estimate')
strout=widget_label(strout_options, value=  'STREHL : ')
strout_nb=widget_text(strout_options,uvalue='strout_opt',xsize=5, value=string(strehl.strehlim,format='$(f5.3)'),resource_name='string')
fwhmout=widget_label(strout_options, value=  'FWHM : ')
fwhmout_nb=widget_text(strout_options,uvalue='fwhmout_opt',xsize=6, value=string(strehl.fwhm,format='$(f6.2)'))
fwhmunits=widget_label(strout_options, value=  ' mas')

; insert the tv display

tv_base=widget_base(wid2,column=1,map=1,frame=2)
tv=widget_draw(tv_base,retain=2,xsize=256,ysize=256)

tv_base2=widget_base(wid2,column=2,map=1,frame=2)
tv2=widget_draw(tv_base2,retain=2,xsize=128,ysize=128)
tv3=widget_draw(tv_base2,retain=2,xsize=128,ysize=128)


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

; Add buttons on the bottom base
bottom_options=widget_base(wid2, row=1,map=1, frame=2, /sensitive,resource_name='bottom_options')
Go_butt=widget_button(bottom_options,value='       GO!       ', uvalue='go', /align_center,resource_name='go')
dismiss=widget_button(bottom_options,value='      DISMISS     ',uvalue='dismiss', /align_right, resource_name='dismiss')

; Make a large error text window.

strehl.err_text = widget_text(wid1,ysize=2,/wrap)
;
; Realize the widget.
widget_control,strehl.mainwid,/realize

widget_control,tv,get_value=temp	&	strehl.tvid(0)=temp(0)
widget_control,tv2,get_value=temp	&	strehl.tvid(1)=temp(0)
widget_control,tv3,get_value=temp	&	strehl.tvid(2)=temp(0)

wset, strehl.tvid(0)
tvscl, randomn(0,256,256)

; Pack some of the id's into the strehl array.
;;    in optionid array, we record the widget ids
strehl.optionid[0]=im1_nb
strehl.optionid[1]=nim_nb
strehl.optionid[2]=bg1_nb
strehl.optionid[3]=nbg_nb
strehl.optionid[4]=path_nb
strehl.optionid[5]=go_butt
strehl.optionid[6]=dismiss
strehl.optionid[7]=autofind_check
strehl.optionid[8]=autoimage_check
strehl.optionid[14]=photrad_nb
strehl.optionid[15]=strout_nb
strehl.optionid[16]=fwhmout_nb
strehl.optionid[17]=list_nb
strehl.optionid[18]=output_nb

;; timer for widget update
strehl.timer_param = strehl.mainwid
widget_control,strehl.timer_param, timer=2.0

; Start the x manager.
widget_control,strehl.mainwid,set_uvalue=strehl
xmanager,'strehl',strehl.mainwid,/no_block

END






















