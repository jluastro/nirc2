function readnirc2,imnum,imheader,disk=disk,path=path,date=date,notcompress=notcompress,gzip=gzip,verbose=verbose,pad1024=pad1024,filter=filter1,silent=silent
; function to read nirc2 images
; and divide them by the number of coadds
; looks for compressed file and then (if it doesn't exist) an uncompressed
;file; set /notcompress to skip straight to uncompressed
; quick version		Bruce Macintosh		nov 2001
; added a /gzip flag feb 2001; removed the /fix since it doesn't do anything.
; pad1024 = pad out to 1024x1024 even if a subarrayed image

        if n_elements(date) eq 0 then date='.'
	if n_elements(disk) eq 0 then disk='.'
	if n_elements(path) eq 0 then path=disk+'/'+date
	if n_elements(notcompress) eq 0 then notcompress=1
	fname='n'+string(imnum,format="(I4.4)")+'.fits.Z'
	if (notcompress eq 1) then fname='n'+string(imnum,format="(I4.4)")+'.fits'
	if keyword_set(gzip) then fname='n'+string(imnum,format="(I4.4)")+'.fits.gz'
        if keyword_set(verbose) then print,path+'/'+fname
;	print,path+'/'+fname
	image=readfits(path+'/'+fname,imheadertemp,/silent)
;	print,n_elements(image),image(0) 
	if n_elements(image) eq 1 and image(0) eq -1 then begin
		if (notcompress eq 1) then fname='n'+string(imnum,format="(I4.4)")+'.fits.Z'
		if (notcompress eq 0) then fname='n'+string(imnum,format="(I4.4)")+'.fits'
                if keyword_set(verbose) then print,path+'/'+fname
		image=readfits(path+'/'+fname,imheadertemp,/silent)
;		print,fname
	endif
	if n_elements(image) ne 1 or image(0) ne -1 then begin
        coadds=sxpar(imheadertemp,'COADDS')
;recover number of coadds
        image=float(image)/float(coadds)
;decoadd
        imheader=imheadertemp
	exptime=sxpar(imheadertemp,'ITIME')
	filter1=sxpar(imheadertemp,'FILTER')
	filter2=sxpar(imheadertemp,'FWONAME')
	aostat=sxpar(imheadertemp,'AODMSTAT')
	obj=sxpar(imheadertemp,'OBJECT')
	avim=avg(image)
	if keyword_set(silent) eq 0 then print,fname,obj,coadds,exptime,filter1,strmid(aostat,0,2),avim,$
	format="(A14,1X,A15,1X,I3,'x',F7.2,' s',2x,A18,' ','AO=',A2,F7.1)"
	endif
	if n_elements(image) ne 1048576 and keyword_set(pad1024) then begin
;subarryed images can be padded into bigger arrays if requested
	  i1024=fltarr(1024,1024)
	  xs=(size(image))(1)
	  ys=(size(image))(2)
	  blx=512-xs/2
	  bly=512-ys/2
	  urx=511+xs/2
	  ury=511+ys/2
	  i1024(blx:urx,bly:ury)=image
	  image=i1024
	endif
return,image
end
