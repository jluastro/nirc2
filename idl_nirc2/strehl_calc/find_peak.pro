function find_peak,image,xc,yc,boxsize,oversamp=oversamp
;procedure to estimate the peak of an object located roughly at xc,yc in
;a box of size boxsize

if not keyword_set(oversamp) then oversamp=8; set the oversampling factor

i=complex(0,1)
boxsize=2*ceil(boxsize/2.)

ext=boxsize*oversamp

boxhalf=boxsize/2
blx=floor(xc-boxhalf)
bly=floor(yc-boxhalf)
subim=image(blx:blx+boxsize-1,bly:bly+boxsize-1)

fftim1=fft(subim,-1); take the FT
shfftim1=shift(fftim1,-boxhalf,-boxhalf); shift 

; need to deconvolve by dividing by a sinc
fftsinc=fltarr(ext)
fftsinc(0:oversamp-1)=1.

; divide by a sinc to deconvolve and undo the effect of pixelation
if 1 then begin
	sinc=boxsize*fft(fftsinc,-1)*exp(i*(shift(indgen(ext)-ext/2.,ext/2.))/(ext)*!pi*(oversamp-1))
	sinc=float(sinc); should be real, remove numerical errors
	sinc=shift(sinc,ext/2)
	sinc=sinc(ext/2.-boxsize/2.:ext/2.+boxsize/2.-1)
	sinc2d=sinc#sinc

	shfftim1=shfftim1/sinc2d;  deconvolve
endif

zpshfftim1=dcomplexarr(oversamp*boxsize,oversamp*boxsize)
zpshfftim1(0:boxsize-1,0:boxsize-1)=shfftim1

zpfftim1=shift(zpshfftim1,-boxhalf,-boxhalf)
subimupsamp=float(fft(zpfftim1,1))

peak=max(subimupsamp)

return, peak
end








