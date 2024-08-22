
import os
import pandas as pd
#import numpy as np
#import pdb
#import sklearn.cluster

#from RIO import config as cfg
#from RIO.riodb.rio_db_loader import RioDatabase
#from RIO.geomapper import GeoMapper
#from RIO import util
#from RIO.riodb.schema import *
#from RIO.unit_converter import UnitConverter
#from RIO.riodb.blend import Blend
#from RIO.riodb.supply_tech import ExistingFixedGenTech, ExistingThermalGenTech, ExistingHydroGenTech, ExistingConversionTech
#from csvdb.utils import filter_query


base_dir = r'X:\WORK\NZAu_LandUsePaper_MAIN\d0_2code\eer_supplycurves\v5'
output_directory = os.path.join(base_dir, 'formatted')
input_directory = os.path.join(base_dir, 'raw inputs')

final_columns = ['file_name', 'OBJECTID', 'incap', 'CF_wLL', 'NZAu_maj', 'tx_cost_per_kw', 'depth_m', 'sensitivity', 'export', 'bin' , 'LCOE2050']

#PVer = '_pvSupply_v11_noSinkPopFilter_proRated_bulk330_proximityBased_forSC.csv'
# '_pvSupply_v12_noSinkPopFilter_proRated_bulk330_proximityBased_load_4bdpaper_case' + str(case) + '_2021.csv'

col_to_keep = ['OIDcom'  , 'm_cf_noloss', 'incap', 'NZAu_maj', 'TXlength_km', 'spurLength_km', 'TXcost_maud2021', 'export', 'bin', 'm_elev' , 'lcoe2050_maud2021_mwh']
col_renamed = ['OBJECTID', 'm_cf_noloss', 'incap', 'NZAu_maj', 'TXlength_km', 'spurLength_km', 'TXcost_maud2021', 'export', 'bin', 'depth_m', 'LCOE2050']

case = 3

file_names = os.listdir(input_directory)
resource_dfs = []
for file_name in file_names:
    resource_df = pd.read_csv(os.path.join(input_directory, file_name), index_col=None)
    resource_df = resource_df.drop_duplicates()
    if 'm_elev' not in resource_df.columns:
        resource_df['m_elev'] = 0
    resource_df = resource_df[col_to_keep]
    resource_df.columns = col_renamed
    resource_df['file_name'] = file_name
    ### GROSS UP OF SOLAR PV CAPACITY FACTORS
    if file_name.startswith('_pvSupply'):
        print ( "PV CFup implemented")
        resource_df['m_cf_noloss'] *= 1.15
    resource_df['sensitivity'] = '[d]'
    resource_dfs.append(resource_df)

resource_df = pd.concat(resource_dfs)

resource_df['tx_cost_per_kw'] = resource_df['TXcost_maud2021'] / resource_df['incap'] * 1000
resource_df['CF_wLL'] = resource_df['m_cf_noloss'] * (1 - (resource_df['spurLength_km'] * 0.621371 / 100)/100)

resource_df = resource_df[final_columns]
resource_df.to_csv(os.path.join(output_directory, 'renewablesAU_case' + str (case) + '.csv'), index=False)

print ("Finished format_files")