import numpy as np
import pylab as plt
from astropy.io import fits
from astropy.nddata import Cutout2D
from astropy.modeling import models, fitting
import astropy
import os
from photutils import CircularAperture, CircularAnnulus, aperture_photometry
from nirc2 import instruments
import scipy, scipy.misc, scipy.ndimage
import math
import pdb

def calc_strehl(file_list, out_file, apersize=0.3, instrument=instruments.default_inst):
    """
    Calculate the Strehl, FWHM, and RMS WFE for each image in a 
    list of files. The output is stored into the specified <out_file>
    text file. The FWHM (and Strehl) is calculated over the specified 
    aperture size using a 2D gaussian fit. The Strehl is estimated by
    using the star specified in the *.coo (one for each *.fits file) 
    file and taking the max pixel flux / wide-aperture flux and normalizing
    by the same on a diffraction-limited image. Note that the diffraction
    limited image comes from an external file. 

    The format of the *.coo file should be:
    xpix  ypix   # everything else

    The diffraction limited images come with the pipeline. For Keck, they are
    all obtained empirically using the NIRC2 camera and filters and they
    are sampled at 0.009952 arcsec / pixel. We will resample them as necessary.
    We will play fast and loose with them and use them for both NIRC2 and OSIRIS. 
    They will be resampled as needed.

    Inputs
    ----------
    file_list : list or array
        The list of the file names.

    out_file : str
        The name of the output text file. 

    aper_size : float (def = 0.3 arcsec)
        The aperture size over which to calculate the Strehl and FWHM. 
    """

    # Setup the output file and format.
    _out = open(out_file, 'w')

    fmt_hdr = '{img:<30s} {strehl:>7s} {rms:>7s} {fwhm:>7s}  {mjd:>10s}\n'
    fmt_dat = '{img:<30s} {strehl:7.3f} {rms:7.1f} {fwhm:7.2f}  {mjd:10.4f}\n'
    
    _out.write(fmt_hdr.format(img='#Filename', strehl='Strehl', rms='RMSwfe', fwhm='FWHM', mjd='MJD'))
    _out.write(fmt_hdr.format(img='#()', strehl='()', rms='(nm)', fwhm='(mas)', mjd='(UT)'))

    # Find the root directory where the calibration files live.
    base_path = os.path.dirname(__file__)
    cal_dir = base_path + '/data/diffrac_lim_img/' + instrument.telescope + '/'

    # We are going to assume that everything in this list
    # has the same camera, filter, plate scale, etc. 
    img0, hdr0 = fits.getdata(file_list[0], header=True)
    filt = instrument.get_filter_name(hdr0)
    scale = instrument.get_plate_scale(hdr0)
    wavelength = instrument.get_central_wavelength(hdr0)

    # Get the diffraction limited image for this filter.
    dl_img_file = cal_dir + filt.lower() + '.fits'
    dl_img, dl_hdr = fits.getdata(dl_img_file, header=True)

    # Get the DL image scale and re-scale it to match the science iamge.
    if 'Keck' in instrument.telescope: 
        scale_dl = 0.009952  # Hard-coded
    else:
        scale_dl = dl_img['PIXSCALE']
    rescale = scale_dl / scale

    if rescale != 1:
        dl_img = scipy.ndimage.zoom(dl_img, rescale, order=3)

    # Pick appropriate radii for extraction.
    # The diffraction limited resolution in pixels.
    dl_res_in_pix = 0.25 * wavelength / (instrument.telescope_diam * scale)
    # radius = int(np.ceil(2.0 * dl_res_in_pix))
    radius = int(np.ceil(apersize / scale))
    if radius < 3:
        radius = 3

    # Perform some wide-aperture photometry on the diffraction-limited image.
    # We will normalize our Strehl by this value. We will do the same on the
    # data later on.
    peak_coords_dl = np.unravel_index(np.argmax(dl_img, axis=None), dl_img.shape)    
    print('Strehl using peak coordinates',peak_coords_dl)
    # Calculate the peak flux ratio
    try:
        dl_peak_flux_ratio = calc_peak_flux_ratio(dl_img, peak_coords_dl, radius)

        # For each image, get the strehl, FWHM, RMS WFE, MJD, etc. and write to an
        # output file. 
        for ii in range(len(file_list)):
            strehl, fwhm, rmswfe = calc_strehl_single(file_list[ii], radius, 
            dl_peak_flux_ratio, instrument=instrument)
            mjd = fits.getval(file_list[ii], instrument.hdr_keys['mjd'])
            dirname, filename = os.path.split(file_list[ii])

            _out.write(fmt_dat.format(img=filename, strehl=strehl, rms=rmswfe, fwhm=fwhm, mjd=mjd))
            
        _out.close()
    except astropy.nddata.PartialOverlapError:
        print("calc_strehl has caught an exception, not calculating Strehl: astropy.nddata.PartialOverlapError")
        for ii in range(len(file_list)):
            _out.write(fmt_dat.format(img=filename, strehl=-1.0, rms=-1.0, fwhm=-1.0, mjd=mjd))
            
        _out.close()
  
    
    return

def calc_strehl_single(img_file, radius, dl_peak_flux_ratio, instrument=instruments.default_inst):
    # Read in the image and header.
    img, hdr = fits.getdata(img_file, header=True)
    wavelength = instrument.get_central_wavelength(hdr) # microns
    scale = instrument.get_plate_scale(hdr)

    # Read in the coordinate file to get the position of the Strehl source. 
    coo_file = img_file.replace('.fits', '.coo')
    _coo = open(coo_file, 'r')
    coo_tmp = _coo.readline().split()
    coords = np.array([float(coo_tmp[0]), float(coo_tmp[1])])
    coords -= 1  # Coordinate were 1 based; but python is 0 based.

    # Calculate the FWHM using a 2D gaussian fit. We will just average the two.
    # To make this fit more robust, we will change our boxsize around, slowly
    # shrinking it until we get a reasonable value.

    # First estimate the DL FWHM in pixels. Use this to set the boxsize for
    # the FWHM estimation... note that this is NOT the aperture size specified
    # above which is only used for estimating the Strehl.
    dl_res_in_pix = 0.25 * wavelength / (instrument.telescope_diam * scale)
    fwhm_min = 0.9 * dl_res_in_pix
    fwhm_max = 100
    fwhm = 0.0
    fwhm_boxsize = int(np.ceil((4 * dl_res_in_pix)))
    if fwhm_boxsize < 3:
        fwhm_boxsize = 3
    box_scale = 1.0
    iters = 0

    # Steadily increase the boxsize until we get a reasonable FWHM estimate.
    while (fwhm < fwhm_min) or (fwhm > fwhm_max):
        box_scale += iters * 0.1
        iters += 1
        g2d = fit_gaussian2d(img, coords, fwhm_boxsize*box_scale)
        stddev = (g2d.x_stddev_0.value + g2d.y_stddev_0.value) / 2.0
        fwhm = 2.355 * stddev

        # Update the coordinates if they are reasonable. 
        if ((np.abs(g2d.x_mean_0.value - coords[0]) < fwhm_boxsize) and
            (np.abs(g2d.y_mean_0.value - coords[1]) < fwhm_boxsize)):
            
            coords = np.array([g2d.x_mean_0.value, g2d.y_mean_0.value])


    # Convert to milli-arcseconds
    fwhm *= scale * 1e3  # in milli-arseconds

    # Calculate the peak flux ratio
    peak_flux_ratio = calc_peak_flux_ratio(img, coords, radius)

    # Normalize by the same from the DL image to get the Strehl.
    strehl = peak_flux_ratio / dl_peak_flux_ratio

    # Convert the Strehl to a RMS WFE using the Marechal approximation.
    rms_wfe = np.sqrt( -1.0 * np.log(strehl)) * wavelength * 1.0e3 / (2. * math.pi)
    
    # Check final values and fail gracefully.
    if ((strehl < 0) or (strehl > 1) or
        (fwhm > 500) or (fwhm < (fwhm_min * scale * 1e3))):
        
        strehl = -1.0
        fwhm = -1.0
        rms_wfe = -1.0

    
    return strehl, fwhm, rms_wfe

def calc_peak_flux_ratio(img, coords, radius):
    """
    img : 2D numpy array
        The image on which to calculate the flux ratio of the peak to a 
        wide-aperture.

    coords : list or numpy array, length = 2
        The x and y position of the source.

    radius : int
        The radius, in pixels, of the wide-aperture. 

    """
    # Make a cutout of the image around the specified coordinates.
    boxsize = (radius * 2) + 1
    img_cut = Cutout2D(img, coords, boxsize, mode='strict')

    # Determine the peak flux in this window.
    peak_coords_cutout = np.unravel_index(np.argmax(img_cut.data, axis=None), img_cut.data.shape)
    peak_coords = img_cut.to_original_position(peak_coords_cutout)
    peak_flux = img[peak_coords[::-1]]
    
    # Calculate the Strehl by first finding the peak-pixel flux / wide-aperture flux.
    # Then normalize by the same thing from the reference DL image. 
    aper = CircularAperture(coords, r=radius)
    aper_out = aperture_photometry(img, aper)
    aper_sum = aper_out['aperture_sum'][0]

    sky_rad_inn = radius + 20
    sky_rad_out = radius + 30
    sky_aper = CircularAnnulus(coords, sky_rad_inn, sky_rad_out)
    sky_aper_out = aperture_photometry(img, sky_aper)
    sky_aper_sum = sky_aper_out['aperture_sum'][0]

    # Calculate the peak pixel flux / wide-aperture flux
    peak_flux_ratio = peak_flux / (aper_sum - sky_aper_sum)
    
    return peak_flux_ratio

def fit_gaussian2d(img, coords, boxsize, plot=False):
    """
    Calculate the FWHM of an objected located at the pixel
    coordinates in the image. The FWHM will be estimated 
    from a cutout with the specified boxsize.

    img : ndarray, 2D
        The image where a star is located for calculating a FWHM.
    coords : len=2 ndarray
        The [x, y] pixel position of the star in the image. 
    boxsize : int
        The size of the box (on the side), in pixels.
    """
    cutout_obj = Cutout2D(img, coords, boxsize, mode='strict')
    cutout = cutout_obj.data
    x1d = np.arange(0, cutout.shape[0])
    y1d = np.arange(0, cutout.shape[1])
    x2d, y2d = np.meshgrid(x1d, y1d)
    
    # Setup our model with some initial guess
    g2d_init = models.Gaussian2D(x_mean = boxsize/2.0,
                                 y_mean = boxsize/2.0,
                                 x_stddev=2,
                                 y_stddev=2,
                                 amplitude=cutout.max())
    g2d_init += models.Const2D(amplitude=0.0)

    fit_g = fitting.LevMarLSQFitter()
    g2d = fit_g(g2d_init, x2d, y2d, cutout)

    if plot:
        mod_img = g2d(x2d, y2d)
        plt.figure(1, figsize=(15,5))
        plt.clf()
        plt.subplots_adjust(left=0.05, wspace=0.3)
        plt.subplot(1, 3, 1)
        plt.imshow(cutout, vmin=mod_img.min(), vmax=mod_img.max())
        plt.colorbar()
        plt.title("Original")
        
        plt.subplot(1, 3, 2)
        plt.imshow(mod_img, vmin=mod_img.min(), vmax=mod_img.max())
        plt.colorbar()
        plt.title("Model")
        
        plt.subplot(1, 3, 3)
        plt.imshow(cutout - mod_img)
        plt.colorbar()
        plt.title("Orig - Mod")

        
    # Adjust Gaussian parameters to the original coordinates.
    cutout_pos = np.array([g2d.x_mean_0.value, g2d.y_mean_0.value])
    origin_pos = cutout_obj.to_original_position(cutout_pos)
    g2d.x_mean_0 = origin_pos[0]
    g2d.y_mean_0 = origin_pos[1]
    
    return g2d
    
