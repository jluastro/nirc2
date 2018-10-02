pro normim,filename 
; normalize the images
im=readfits(filename)
im=im/total(im)
writefits,filename,im


return
end