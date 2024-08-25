
## THIS FILE CONTAINS CODE SUPPIED BY Evolved Energy Research that has been modified for this repository/paper.

import os
import pandas as pd
import numpy as np
#import numpy_financial as npf
import sklearn.cluster
import scipy.interpolate as interpolate
import fnmatch

base_dir = os.getcwd()
output_directory = base_dir + '\\..\\d0_3results\\sc_formatted'
input_directory  = base_dir + '\\..\\d0_3results\\sc_raw'

final_columns = ['file_name', 'OBJECTID', 'incap', 'CF_wLL', 'NZAu_maj', 'tx_cost_per_kw', 'depth_m', 'sensitivity', 'export', 'bin' , 'LCOE2050']

col_to_keep = ['OIDcom'  , 'm_cf_noloss', 'incap', 'NZAu_maj', 'TXlength_km', 'spurLength_km', 'TXcost_maud2021', 'export', 'bin', 'm_elev' , 'lcoe2050_maud2021_mwh']
col_renamed = ['OBJECTID', 'm_cf_noloss', 'incap', 'NZAu_maj', 'TXlength_km', 'spurLength_km', 'TXcost_maud2021', 'export', 'bin', 'depth_m', 'LCOE2050']

case = ['0' , '1' , '2' , '3']
ver  = 'paperAU'

for caseX in case:
    file_names = list ( filter ( lambda k: ('case' + str( caseX ) ) in k, os.listdir(input_directory) ) )
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
    resource_df.to_csv(os.path.join(output_directory, ver + '_case' + str (caseX) + '.csv'), index=False)

    print ("Finished format_files for case" + caseX )

##combine files
df1 = pd.DataFrame(pd.read_csv(os.path.join(output_directory, ver + '_case' + str (case[0]) + '.csv'), index_col=None))
df1['case'] = case[0]
case = case[1:len(case)]
for caseX in case:
    df2 = pd.DataFrame(pd.read_csv(os.path.join(output_directory, ver + '_case' + str (caseX) + '.csv'), index_col=None))
    df2['case'] = caseX
    df1 = pd.concat([df1,df2])
df1.to_csv(os.path.join(output_directory, ver + '_case' + str (9) + '.csv'), index=False)

def normalize_features(features, feature_weights):
    features = ((features - features.mean()) / features.std()) * feature_weights
    features = features.fillna(0)
    return features

def cluster_days(features_normed, n_clusters):
    cluster = sklearn.cluster.KMeans(n_clusters=n_clusters, random_state=1)
    # cluster = sklearn.cluster.MeanShift() # put it all in one clump
    # cluster = sklearn.cluster.AffinityPropagation() # seems to work pretty well
    # cluster = sklearn.cluster.AgglomerativeClustering(n_clusters=n_clusters, linkage='ward')
    # cluster = sklearn.cluster.AgglomerativeClustering(n_clusters=n_clusters, linkage='complete')  # probably is best
    # cluster = sklearn.cluster.AgglomerativeClustering(n_clusters=n_clusters, linkage='average')
    # cluster = sklearn.cluster.DBSCAN() # only picked 4 clusters
    # cluster = sklearn.cluster.Birch(n_clusters=n_clusters, threshold=.1)
    fit = cluster.fit_predict(features_normed.values)
    return fit + 1

def argsort(seq):
    # http://stackoverflow.com/questions/3382352/equivalent-of-numpy-argsort-in-basic-python/3383106#3383106
    #non-lambda version by Tony Veijalainen
    return [i for (v, i) in sorted((v, i) for (i, v) in enumerate(seq))]

def get_capacity_weighted_cf(resource_df, cf_vintage_map=None):
    final_bins = resource_df[['sensitivity', 'bin_number', 'NZAu_maj', 'incap', 'CF_wLL']]

    if cf_vintage_map is not None:
        cf_vintage_map = cf_vintage_map.set_index([col for col in cf_vintage_map if col != 'value'])
        cf_vintage_map = cf_vintage_map.squeeze()
        cf_vintage_map = cf_vintage_map.unstack('vintage')

        x = cf_vintage_map.columns
        y = cf_vintage_map[2019].values
        z = cf_vintage_map.values
        f = interpolate.interp2d(x, y, z, kind='cubic')

        output_vintages = range(2020, 2051)
        for vintage in output_vintages:
            final_bins[vintage] = [f(vintage, val)[0] for val in final_bins['CF_wLL'].values]
            final_bins[vintage] *= final_bins['incap']

    else:
        output_vintages = [2020]
        final_bins[2020] = final_bins['CF_wLL'] * final_bins['incap']

    del final_bins['CF_wLL']
    final_bins = final_bins.groupby(['sensitivity', 'bin_number', 'NZAu_maj']).sum()
    part3 = final_bins.groupby(level=['bin_number']).sum()

    # part 3 is just used to change the bin mapping
    part3[output_vintages[0]] = part3[output_vintages[0]] / part3['incap']
    part3 = part3[[output_vintages[0]]]

    part3 = part3.sort_values(output_vintages[0], ascending=False)
    bin_mapping = dict(zip(part3.index, range(1, len(part3)+1)))

    capacity = final_bins[['incap']]
    cf = final_bins[output_vintages]

    cf[:] = cf.values / capacity.values
    cf = cf[(capacity!=0).values]
    cf.columns.name = 'vintage'
    cf = cf.stack().to_frame()
    cf.columns = ['value']

    return cf.reset_index(), bin_mapping


def get_capacity_weighted_capex(resource_df, capex_vintage_map=None):
    final_bins = resource_df[['sensitivity', 'bin_number', 'NZAu_maj', 'incap', 'depth_m']]

    if capex_vintage_map is not None:
        capex_vintage_map = capex_vintage_map.set_index([col for col in capex_vintage_map if col != 'value'])
        capex_vintage_map = capex_vintage_map.squeeze()
        capex_vintage_map = capex_vintage_map.unstack('vintage')

        x = capex_vintage_map.columns
        y = capex_vintage_map.index.get_level_values('depth')
        z = capex_vintage_map.values
        f = interpolate.interp2d(x, y, z, kind='linear')

        output_vintages = range(2020, 2051)
        for vintage in output_vintages:
            final_bins[vintage] = [f(vintage, val)[0] for val in final_bins['depth_m'].values]
            final_bins[vintage] *= final_bins['incap']

    else:
        pass
        # output_vintages = [2020]
        # final_bins[2020] = final_bins['CF'] * final_bins['capacity']

    del final_bins['depth_m']
    # final_bins = final_bins.groupby(['sensitivity', 'bin_number', 'NZAu_maj']).sum()
    final_bins = final_bins.groupby(['bin_number', 'NZAu_maj']).sum()
    capacity = final_bins[['incap']]
    capex = final_bins[output_vintages]

    capex[:] = capex.values / capacity.values
    capex = capex[(capacity!=0).values]
    capex.columns.name = 'vintage'
    capex = capex.stack().to_frame()
    capex.columns = ['value']

    return capex.reset_index()

def get_capacity_weighted_depth(resource_df):
    final_bins = resource_df[['sensitivity', 'bin_number', 'NZAu_maj', 'incap', 'depth_m']]
    final_bins['depth_m_weighted'] = final_bins['depth_m'] * final_bins['incap']

    final_bins = final_bins[['sensitivity', 'bin_number', 'NZAu_maj', 'incap', 'depth_m_weighted']]
    final_bins = final_bins.groupby(['sensitivity', 'bin_number', 'NZAu_maj']).sum()
    part2 = final_bins.groupby(level=['bin_number', 'NZAu_maj']).sum()

    part2['depth_m'] = part2['depth_m_weighted'] / part2['incap']
    part2 = part2[part2['incap'] != 0]

    depth = part2[['depth_m']]
    return depth.reset_index()


def finalize_cap_and_tx(resource_df):
    final_bins = resource_df[['sensitivity', 'bin_number', 'NZAu_maj', 'incap', 'tx_cost_per_kw']]

    final_bins['tx_cost_per_kw_weighted'] = final_bins['tx_cost_per_kw'] * final_bins['incap']

    final_bins = final_bins[['sensitivity', 'bin_number', 'NZAu_maj', 'incap', 'tx_cost_per_kw_weighted']]
    final_bins = final_bins.groupby(['sensitivity', 'bin_number', 'NZAu_maj']).sum()

    part1 = final_bins.groupby(level=['sensitivity', 'bin_number', 'NZAu_maj']).sum()
    part2 = final_bins.groupby(level=['bin_number', 'NZAu_maj']).sum()

    part2['tx_cost_per_kw'] = part2['tx_cost_per_kw_weighted'] / part2['incap']
    part2 = part2[part2['incap']!=0]

    capacity = part1[['incap']]
    tx_cost = part2[['tx_cost_per_kw']]

    return capacity.reset_index(), tx_cost.reset_index()

def remap_bins(df, bin_mapping, rep_col='bin_number'):
    df[rep_col] = [bin_mapping[i] for i in df['bin_number'].values]
    return df

def add_name(df, name_prefix):
    df['name'] = [name_prefix + str(bin_num) for bin_num in df['bin_number'].values]
    return df


base_dir = os.getcwd()
input_directory  = base_dir + '\\..\\d0_3results\\sc_formatted'
output_directory = base_dir + '\\..\\d0_3results\\sc_final'

atb_cf = pd.read_csv(base_dir + '\\..\\d0_1source\\ATB_CAPACITY_FACTORS.csv', index_col=None)
atb_capex = pd.read_csv(base_dir + '\\..\\d0_1source\\ATB_CAPITAL_COSTS2.csv', index_col=None)

case = 9
ver = "paperAU"

formatted_cpa = pd.read_csv(os.path.join(input_directory, ver + '_case' + str (case) + '.csv'), index_col=False)

tx_cost_all = []
capacity_factors_all = []
capacity_all = []
resource_df_all = []
capex_all = []
depth_all = []

# # ### offshore wind
resource_df = formatted_cpa[formatted_cpa['file_name'].str.startswith('_offSupply')].copy()


# # project viability screen
# # y = M*x + b
# x1, y1 = 0, .1
# x2, y2 = 1100, .7
# M = (y2-y1) / (x2-x1)
# b = y1 - M * x1
#
# resource_df = resource_df[resource_df['CF_wLL'] >= resource_df['tx_cost_per_kw']*M + b]
resource_df = resource_df[resource_df['CF_wLL']>=0.35]
resource_df = resource_df[resource_df['tx_cost_per_kw']<2000]

# features
feature_names =         ['CF_wLL', 'tx_cost_per_kw', 'depth_m']
feature_weights = np.array([1,        .7,           0.3])
n_clusters = 5

features = resource_df[feature_names]
features_normed = normalize_features(features, feature_weights)

bins = cluster_days(features_normed, n_clusters)
resource_df['bin_number'] = bins

resource_df['i'] = range(len(resource_df))
cf_vintage_map = atb_cf[(atb_cf['type']=='offshore') & (atb_cf['scenario']=='Moderate')]
capex_vintage_map = atb_capex[(atb_capex['type']=='offshore') & (atb_capex['scenario']=='Moderate')]

capacity_factors, bin_mapping = get_capacity_weighted_cf(resource_df, cf_vintage_map=cf_vintage_map)
capex = get_capacity_weighted_capex(resource_df, capex_vintage_map)
capacity, tx_cost = finalize_cap_and_tx(resource_df)
depth = get_capacity_weighted_depth(resource_df)

capacity = remap_bins(capacity, bin_mapping)
tx_cost = remap_bins(tx_cost, bin_mapping)
capex = remap_bins(capex, bin_mapping)
capacity_factors = remap_bins(capacity_factors, bin_mapping)
depth = remap_bins(depth, bin_mapping)
resource_df = remap_bins(resource_df, bin_mapping)

name = "offshore wind|"
tx_cost = add_name(tx_cost, name)
capex = add_name(capex, name)
depth = add_name(depth, name)
capacity_factors = add_name(capacity_factors, name)
capacity = add_name(capacity, name)

capacity_factors['interpolation_method'] = 'two_tier'
capacity_factors['extrapolation_method'] = 'two_tier'

tx_cost['type'] = 'offshore'
capacity_factors['type'] = 'offshore'
capacity['type'] = 'offshore'
resource_df['type'] = 'offshore'
capex['type'] = 'offshore'
depth['type'] = 'offshore'

tx_cost_all.append(tx_cost)
capacity_factors_all.append(capacity_factors)
capacity_all.append(capacity)
capex_all.append(capex)
depth_all.append(depth)
resource_df_all.append(resource_df.copy())

### onshore wind

resource_df = formatted_cpa[formatted_cpa['file_name'].str.startswith('_windSupply')].copy()

# # project viability screen
# # y = M*x + b
# x1, y1 = 0, .28
# x2, y2 = 1000, .4
# M = (y2-y1) / (x2-x1)
# b = y1 - M * x1
#
# resource_df = resource_df[resource_df['CF_wLL'] >= resource_df['tx_cost_per_kw']*M + b]
resource_df = resource_df[resource_df['CF_wLL']>=0.25]
resource_df = resource_df[resource_df['tx_cost_per_kw']<800]

# features
feature_names =         ['CF_wLL', 'tx_cost_per_kw']
feature_weights = np.array([.7,        1,])
n_clusters = 5

features = resource_df[feature_names]
features_normed = normalize_features(features, feature_weights)

bins = cluster_days(features_normed, n_clusters)
resource_df['bin_number'] = bins

resource_df['i'] = range(len(resource_df))
cf_vintage_map = atb_cf[(atb_cf['type']=='onshore') & (atb_cf['scenario']=='Moderate')]

capacity_factors, bin_mapping = get_capacity_weighted_cf(resource_df, cf_vintage_map=cf_vintage_map)
capacity, tx_cost = finalize_cap_and_tx(resource_df)

capacity = remap_bins(capacity, bin_mapping)
tx_cost = remap_bins(tx_cost, bin_mapping)
capacity_factors = remap_bins(capacity_factors, bin_mapping)
resource_df = remap_bins(resource_df, bin_mapping)

name = "onshore wind|"
tx_cost = add_name(tx_cost, name)
capacity_factors = add_name(capacity_factors, name)
capacity = add_name(capacity, name)

capacity_factors['interpolation_method'] = 'three_tier'
capacity_factors['extrapolation_method'] = 'three_tier'

tx_cost['type'] = 'onshore'
capacity_factors['type'] = 'onshore'
capacity['type'] = 'onshore'
resource_df['type'] = 'onshore'

tx_cost_all.append(tx_cost)
capacity_factors_all.append(capacity_factors)
capacity_all.append(capacity)
resource_df_all.append(resource_df.copy())

### solar PV

resource_df = formatted_cpa[formatted_cpa['file_name'].str.startswith('_pvSupply')].copy()
resource_df = resource_df[resource_df['export']==0]

# # project viability screen
# # y = M*x + b
# x1, y1 = 0, .05
# x2, y2 = 300, .25
# M = (y2-y1) / (x2-x1)
# b = y1 - M * x1
#
# resource_df = resource_df[resource_df['CF_wLL'] >= resource_df['tx_cost_per_kw']*M + b]
resource_df = resource_df[resource_df['tx_cost_per_kw']<400]

# features
feature_names =         ['CF_wLL', 'tx_cost_per_kw']
feature_weights = np.array([1.0,        0.6])
n_clusters = 4

features = resource_df[feature_names]
features_normed = normalize_features(features, feature_weights)

bins = cluster_days(features_normed, n_clusters)
resource_df['bin_number'] = bins
resource_df['i'] = range(len(resource_df))

cf_vintage_map = atb_cf[(atb_cf['type']=='solar') & (atb_cf['scenario']=='Moderate')]

capacity_factors, bin_mapping = get_capacity_weighted_cf(resource_df, cf_vintage_map=cf_vintage_map)
capacity, tx_cost = finalize_cap_and_tx(resource_df)

capacity = remap_bins(capacity, bin_mapping)
tx_cost = remap_bins(tx_cost, bin_mapping)
capacity_factors = remap_bins(capacity_factors, bin_mapping)
resource_df = remap_bins(resource_df, bin_mapping)

name = "large-scale solar pv|"
tx_cost = add_name(tx_cost, name)
capacity_factors = add_name(capacity_factors, name)
capacity = add_name(capacity, name)

capacity_factors['interpolation_method'] = 'three_tier'
capacity_factors['extrapolation_method'] = 'three_tier'

tx_cost['type'] = 'solar'
capacity_factors['type'] = 'solar'
capacity['type'] = 'solar'
resource_df['type'] = 'solar'

tx_cost_all.append(tx_cost)
capacity_factors_all.append(capacity_factors)
capacity_all.append(capacity)
resource_df_all.append(resource_df.copy())



### solar PV for export

resource_df = formatted_cpa[formatted_cpa['file_name'].str.startswith('_pvSupply')].copy()
resource_df = resource_df[resource_df['export']==1]

# # project viability screen
# # y = M*x + b
# x1, y1 = 0, .05
# x2, y2 = 300, .25
# M = (y2-y1) / (x2-x1)
# b = y1 - M * x1
#
# resource_df = resource_df[resource_df['CF_wLL'] >= resource_df['tx_cost_per_kw']*M + b]
resource_df = resource_df[resource_df['tx_cost_per_kw']<400]

# features
feature_names =         ['CF_wLL', 'tx_cost_per_kw' , 'LCOE2050']
feature_weights = np.array([0.2,        0.8,          0.9])
n_clusters = 3

features = resource_df[feature_names]
features_normed = normalize_features(features, feature_weights)

bins = cluster_days(features_normed, n_clusters)
resource_df['bin_number'] = bins
resource_df['i'] = range(len(resource_df))

cf_vintage_map = atb_cf[(atb_cf['type']=='solar') & (atb_cf['scenario']=='Moderate')]

capacity_factors, bin_mapping = get_capacity_weighted_cf(resource_df, cf_vintage_map=cf_vintage_map)
for _bin in bin_mapping:
    bin_mapping[_bin] = bin_mapping[_bin]+4
capacity, tx_cost = finalize_cap_and_tx(resource_df)

capacity = remap_bins(capacity, bin_mapping)
tx_cost = remap_bins(tx_cost, bin_mapping)
capacity_factors = remap_bins(capacity_factors, bin_mapping)
resource_df = remap_bins(resource_df, bin_mapping)

name = "large-scale solar pv|"
tx_cost = add_name(tx_cost, name)
capacity_factors = add_name(capacity_factors, name)
capacity = add_name(capacity, name)

capacity_factors['interpolation_method'] = 'three_tier'
capacity_factors['extrapolation_method'] = 'three_tier'

tx_cost['type'] = 'solar'
capacity_factors['type'] = 'solar'
capacity['type'] = 'solar'
resource_df['type'] = 'solar'

tx_cost_all.append(tx_cost)
capacity_factors_all.append(capacity_factors)
capacity_all.append(capacity)
resource_df_all.append(resource_df.copy())


capacity_all = pd.concat(capacity_all)
tx_cost_all = pd.concat(tx_cost_all)
capacity_factors_all = pd.concat(capacity_factors_all)
capex_all = pd.concat(capex_all)
depth_all = pd.concat(depth_all)
resource_df_all = pd.concat(resource_df_all)

capacity_all.to_csv(os.path.join(output_directory, 'capacity_constraints_' + ver + 'case' + str(case) + '.csv'), index=False)
tx_cost_all.to_csv(os.path.join(output_directory, 'tx_cost_' + ver + 'case' + str(case) + '.csv'), index=False)
capex_all.to_csv(os.path.join(output_directory, 'capex_cost_' + ver + 'case' + str(case) + '.csv'), index=False)
depth_all.to_csv(os.path.join(output_directory, 'osw_depth_' + ver + 'case' + str(case) + '.csv'), index=False)
capacity_factors_all.to_csv(os.path.join(output_directory, 'capacity_factors_' + ver + 'case' + str(case) + '.csv'), index=False)
resource_df_all.to_csv(os.path.join(output_directory, 'binned_resource_df_' + ver + 'case' + str(case) + '.csv'), index=False)

print ( "Finished binning resource")