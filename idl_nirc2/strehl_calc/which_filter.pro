function which_filter,filter 

filter=strcompress(filter,/remove_all)
filt=''
 
if filter eq 'K+hole' then filt='k'
if filter eq 'J+clear' then filt='j'
if filter eq 'K+clear' then filt='k'
if filter eq 'H+clear' then filt='h'
if filter eq 'Kp+clear' then filt='kprime'
if filter eq 'Ks+clear' then filt='ks'
if filter eq 'PK50_1.5+Kcont' then filt='kcont'
if filter eq 'PK50_1.5+Hcont' then filt='hcont'
if filter eq 'PK50_1.5+FeII' then filt='feii'
if filter eq 'PK50_1.5+Br_gamma' then filt='brgamma'
if filter eq 'PK50_1.5+Jcont' then filt='jcont'
if filter eq 'Lp+clear' then filt='lprime'
if filter eq 'Ms+clear' then filt='ms'
if filter eq 'PK50_1.5+NB2.108' then filt='nb2.108'
if filter eq 'clear+PAH' then filt='pabeta'
if filter eq 'PK50_1.5+He1_B' then filt='heib'

if filt eq '' then begin
   message, /info, 'Cannot determine the filter, assuming K'
   filt='k'
endif

return, filt

end
