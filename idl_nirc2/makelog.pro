pro makelog, list

on_error,2

;this is for NIRC2 data
fmt='a'
readcol, list, f=fmt,names
outname = strmid(list, 0, strpos(list, ".", /reverse_search))

num = n_elements(names)
openw, 1, outname + '.log'

;loop and go through headers to extract info
fmt2 = '(a9,1x,a18,4x,a8,3x,a8,3x,f6.2,a3,i4,5x,'
fmt2 = fmt2 + 'i1,3x,a3,i2,5x,f4.2,4x,i4,4x,a20)'
fmt1 = '(a9,1x,a18,4x,a8,3x,a8,3x,a6,a3,a6,3x,'
fmt1 = fmt1 + 'a4,a3,a6,1x,a7,1x,a4,4x,a20)'

printf,1,"File","Object","Camera","Filter","ITime"," x ","Coadd",$
       "Samp"," x ","Multi","Airmass","Size","Comment", format=fmt1

for jj=0, num-1 do begin
        hdr = headfits(names(jj), /silent)

        objnum = names[jj]
        obname = strcompress(fxpar(hdr, 'OBJECT'), /remove_all)

        cam = strcompress(fxpar(hdr, 'CAMNAME'), /remove_all)
        filt = strcompress(fxpar(hdr, 'FILTER'), /remove_all)

        itime = fxpar(hdr, 'ITIME')
        coadd = fix(fxpar(hdr, 'COADDS'))
        sampmode = fix(fxpar(hdr, 'SAMPMODE'))
        multisam = fix(fxpar(hdr, 'MULTISAM'))

        cmt = fxpar(hdr, 'COMMENT')
        cmtStart = strpos(cmt, "'")+1
        cmtStop = strpos(cmt, "'", /reverse_search)
        comment = strmid(cmt, cmtStart, cmtStop-cmtStart)
        comment = strcompress( comment )
        
        size = fix(fxpar(hdr, 'NAXIS1'))
        airmass = fxpar(hdr, 'AIRMASS')

        printf,1,objnum,obname,cam,filt,itime," x ",coadd,$
               sampmode," x ",multisam,airmass,size,comment,$
               format=fmt2

endfor
close,1

stop
end
