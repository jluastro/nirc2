import numpy as np
import pylab as plt
import os
import collections
from astropy.io import fits

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
        
    

class NIRC2(Instrument):
    def __init__(self):
        # Define
        self.hdr_keys = {}

        self.hdr_keys['filename'] = 'filename'
        self.hdr_keys['object_name'] = 'object'
        self.hdr_keys['itime'] = 'itime'
        self.hdr_keys['coadds'] = 'coadds'
        self.hdr_keys['sampmode'] = 'sampmode'
        self.hdr_keys['nfowler'] = 'multisam'
        self.hdr_keys['camera'] = 'camname'
        self.hdr_keys['shutter'] = 'shrname'

        self.bad_pixel_mask = 'nirc2mask.fits'

        self.distCoef = ''
        self.distXgeoim = module_dir + '/reduce//distortion/nirc2_narrow_xgeoim.fits'
        self.distYgeoim = module_dir + '/reduce//distortion/nirc2_narrow_ygeoim.fits'

        return
    
    def get_filter_name(self, hdr):
        filter1 = hdr['fwiname']
        filter2 = hdr['fwoname']
        filt = filter1
        if (filter1.startswith('PK')):
            filt = filter2

        return filt

    def make_filenames(self, files, rootDir='', prefix='n'):
        file_names = [rootDir + prefix + str(i).zfill(4) + '.fits' for i in files]
        return file_names

    def get_distortion_maps(self, date):
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
        

class OSIRIS(Instrument):
    def __init__(self):
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

        self.bad_pixel_mask = 'osiris_img_mask.fits'

        self.distCoef = ''
        self.distXgeoim = None
        self.distYgeoim = None
        
        return
    
    def get_filter_name(self, hdr):
        return hdr['ifilter']
        
    
    def make_filenames(self, files, rootDir='', prefix=''):
        file_names = [rootDir + prefix + i + '.fits' for i in files]

        return file_names

    def flip_images(self, files, rootDir=''):
        for ff in range(len(files)):
            old_file = files[ff]
            new_file = files[ff].replace('.fits', '_xflip.fits')
            
            hdu_list = fits.open(old_file)

            for hh in range(len(hdu_list)):
                if type(hdu_list[hh]) == fits.ImageHDU:
                    hdu_list[hh].data = hdu_list[hh].data[:, ::-1]

            hdu_list.writeto(new_file, overwrite=True)
            
        return
            
    def get_distortion_maps(self, date):
        distXgeoim = None
        distYgeoim = None

        return distXgeoim, distYgeoim


##################################################
#
#  SET DEFAUL INSTRUMENT FOR MODULE.
#
##################################################
default_inst = NIRC2()

    
