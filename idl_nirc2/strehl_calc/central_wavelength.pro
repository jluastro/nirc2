function central_wavelength, filt

	if filt eq 'hcont' then lambda=1.5804e-6;
	if filt eq 'kcont' then lambda=2.2706e-6	
	if filt eq 'j' then lambda = 1.248e-6;
	if filt eq 'h' then lambda = 1.633e-6;
	if filt eq 'k' then lambda = 2.196e-6;
	if filt eq 'ks' then lambda = 2.146e-6; 
	if filt eq 'kprime' then lambda = 2.124e-6;
	if filt eq 'feii' then lambda = 1.6455e-6;
	if filt eq 'brgamma' then lambda = 2.1686e-6;
	if filt eq 'lprime' then lambda = 3.776e-6;
	if filt eq 'ms' then lambda = 4.670e-6;
	if filt eq 'nb2.108' then lambda = 2.108e-6;
	if filt eq 'jcont' then lambda = 1.2132e-6;
	if filt eq 'pabeta' then lambda = 1.2903e-6;
	if filt eq 'heib'then lambda = 2.0563e-6
	if filt eq 'co' then lambda = 2.2782e-6;

return, lambda

end
