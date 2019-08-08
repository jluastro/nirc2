import numpy as np
import pylab as plt
import os
import collections
from astropy.io import fits
import pdb
from astropy.io.fits.hdu.image import _ImageBaseHDU

module_dir = os.path.dirname(__file__)

class Instrument(object):
    def __init__(self):
        # Must define the following parameters as a 

        # Define
        self.hdr_keys = {}

        self.hdr_keys['filename'] = 'filename'
        
        return
    def get_bad_pixel_mask_name(self):
        return self.bad_pixel_mask

    def get_filter_name(self, hdr):
        pass

    def get_filter_name(self, hdr):
        pass

    def get_filter_name(self, hdr):
        pass

    def get_filter_name(self, hdr):
        pass
    
    def make_filenames(self, files, rootDir='', prefix='n'):
        pass
        
    def get_distortion_maps(self, date):
        pass

    def get_gain(self, hdr):
        pass
    
    def get_align_type(self, errors=False):
        pass
    
class NIRC2(Instrument):
    def __init__(self):
        self.name = 'NIRC2'
        
        # Define header keywords
        self.hdr_keys = {}

        self.hdr_keys['filename'] = 'FILENAME'
        self.hdr_keys['object_name'] = 'OBJECT'
        self.hdr_keys['itime'] = 'ITIME'
        self.hdr_keys['coadds'] = 'COADDS'
        self.hdr_keys['sampmode'] = 'SAMPMODE'
        self.hdr_keys['nfowler'] = 'MULTISAM'
        self.hdr_keys['camera'] = 'CAMNAME'
        self.hdr_keys['shutter'] = 'SHRNAME'
        self.hdr_keys['mjd'] = 'MJD-OBS'
        self.hdr_keys['elevation'] = 'EL'

        self.bad_pixel_mask = 'nirc2mask.fits'

        self.distCoef = ''
        self.distXgeoim = module_dir + '/reduce//distortion/nirc2_narrow_xgeoim.fits'
        self.distYgeoim = module_dir + '/reduce//distortion/nirc2_narrow_ygeoim.fits'

        self.telescope = 'Keck'
        self.telescope_diam = 10.5 # telescope diameter in meters

        return
    
    def get_filter_name(self, hdr):
        filter1 = hdr['fwiname']
        filter2 = hdr['fwoname']
        filt = filter1
        if (filter1.startswith('PK')):
            filt = filter2

        return filt

    def get_plate_scale(self, hdr):
        """
        Return the plate scale in arcsec/pixel.
        """
        # Setup NIRC2 plate scales
        # Units are arcsec/pixel
        scales = {"narrow": 0.009952,
                  "medium": 0.019829,
                  "wide": 0.039686}

        scale = scales[hdr['CAMNAME']]
        
        return scale

    def get_position_angle(self, hdr):
        """
        Get the sky PA in degrees East of North. 
        """
        return float(hdr['ROTPOSN']) - float(hdr['INSTANGL'])

    def get_instrument_angle(self, hdr):
        return float(hdr['INSTANGL'])

    def get_central_wavelength(self, hdr):
        """
        Return the central wavelength of the filter for 
        this observation in microns.
        """
        return float(hdr['CENWAVE'])

    def get_gain(self, hdr):
        return hdr['GAIN']
    
    def make_filenames(self, files, rootDir='', prefix='n'):
        file_names = [rootDir + prefix + str(i).zfill(4) + '.fits' for i in files]
        return file_names

    def get_distortion_maps(self, hdr):
        """
        Inputs
        ----------
        date : str
            Date in string format such as '2015-10-02'.
        """
        date = hdr['DATE-OBS']
        
        if (float(date[0:4]) < 2015):
            distXgeoim = module_dir + '/reduce/distortion/nirc2_narrow_xgeoim.fits'
            distYgeoim = module_dir + '/reduce/distortion/nirc2_narrow_ygeoim.fits'
        if (float(date[0:4]) == 2015) & (float(date[5:7]) < 0o5):
            distXgeoim = module_dir + '/reduce/distortion/nirc2_narrow_xgeoim.fits'
            distYgeoim = module_dir + '/reduce/distortion/nirc2_narrow_ygeoim.fits'
        if (float(date[0:4]) == 2015) & (float(date[5:7]) >= 0o5):
            distXgeoim = module_dir + '/reduce/distortion/nirc2_narrow_xgeoim_post20150413.fits'
            distYgeoim = module_dir + '/reduce/distortion/nirc2_narrow_ygeoim_post20150413.fits'
        if (float(date[0:4]) > 2015):
            distXgeoim = module_dir + '/reduce/distortion/nirc2_narrow_xgeoim_post20150413.fits'
            distYgeoim = module_dir + '/reduce/distortion/nirc2_narrow_ygeoim_post20150413.fits'

        return distXgeoim, distYgeoim
        
    def get_align_type(self, hdr, errors=False):
        # Setup NIRC2 plate scales
        # Units are arcsec/pixel
        atypes = {"narrow": 8,
                  "medium": 14,
                  "wide": 12}

        atype = atypes[hdr['CAMNAME']]

        if errors == True:
            atype += 1

        return atype


class OSIRIS(Instrument):
    def __init__(self):
        self.name = 'OSIRIS'
        
        # Define
        self.hdr_keys = {}

        self.hdr_keys['filename'] = 'datafile'
        self.hdr_keys['object_name'] = 'object'
        self.hdr_keys['itime'] = 'truitime'
        self.hdr_keys['coadds'] = 'coadds'
        self.hdr_keys['sampmode'] = 'sampmode'
        self.hdr_keys['nfowler'] = 'numreads'
        self.hdr_keys['camera'] = 'instr'
        self.hdr_keys['shutter'] = 'ifilter'
        self.hdr_keys['mjd'] = 'MJD-OBS'
        self.hdr_keys['elevation'] = 'EL'

        self.bad_pixel_mask = 'osiris_img_mask.fits'

        self.distCoef = ''
        self.distXgeoim = None
        self.distYgeoim = None

        self.telescope = 'Keck'
        self.telescope_diam = 10.5 # telescope diameter in meters
        
        return
    
    def get_filter_name(self, hdr):
        return hdr['ifilter']
        
    def get_plate_scale(self, hdr):
        """
        Return the plate scale in arcsec/pix.
        """
        scale = 0.00995
        
        return scale
    
    def get_position_angle(self, hdr):
        """
        Get the sky PA in degrees East of North. 
        """
        pa_old = float(hdr['ROTPOSN']) - self.get_instrument_angle(hdr)
        pa_new = pa_old - 180.0
        return pa_new
    
    def get_instrument_angle(self, hdr):
        """
        Get the angle of the instrument w.r.t. to the telescope or 
        AO bench in degrees.
        """
        inst_angle = (hdr['INSTANGL'] - 42.5)
        return inst_angle
    
    def get_central_wavelength(self, hdr):
        """
        Return the central wavelength of the filter for 
        this observation in microns.
        """
        return float(hdr['CENWAVE'])
    
    def get_gain(self, hdr):
        return hdr['DETGAIN']
    
    def make_filenames(self, files, rootDir='', prefix=''):
        file_names = [rootDir + prefix + i + '.fits' for i in files]

        return file_names

    def flip_images(self, files, rootDir=''):
        for ff in range(len(files)):
            old_file = files[ff]
            new_file = files[ff].replace('.fits', '_xflip.fits')
            
            hdu_list = fits.open(old_file)

            for hh in range(len(hdu_list)):
                if isinstance(hdu_list[hh], _ImageBaseHDU):
                    hdu_list[hh].data = hdu_list[hh].data[:, ::-1]

            hdu_list.writeto(new_file, overwrite=True)

            # Add header values. 
            fits.setval(new_file, 'EFFWAVE', value= 2.1245) # from NIRC2
            fits.setval(new_file, 'CENWAVE', value= 2.1245) # from NIRC2
            fits.setval(new_file, 'CAMNAME', value = 'narrow') # from NIRC2
            
        return
            
    def get_distortion_maps(self, hdr):
        distXgeoim = None
        distYgeoim = None

        return distXgeoim, distYgeoim

    def get_align_type(self, hdr, errors=False):
        atype = 14

        if errors == True:
            atype += 1

        return atype
    

##################################################
#
#  SET DEFAULT INSTRUMENT FOR MODULE.
#
##################################################
default_inst = NIRC2()

    
