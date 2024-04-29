# this is for the council analysis, only years
# post 1992 and just the population estimates
# I scraped the data via 
# https://andrewpwheeler.com/2023/07/29/downloading-police-employment-trends-from-the-fbi-data-explorer/

import pandas as pd

dat = pd.read_csv('OfficerInfo.csv')
dat.sort_values(by=['ori','data_year'],ignore_index=True)

# Woodburn in 2011 is messed up, going to
# interpolate between 2010/2012
wood = (dat['ori'] == 'OR0240500') & (dat['data_year'] == 2011)

var_rep = ['population', 'male_officer_ct', 'male_civilian_ct', 'male_total_ct', 
           'female_officer_ct', 'female_civilian_ct', 'female_total_ct', 'officer_ct', 
           'civilian_ct', 'total_pe_ct', 'pe_ct_per_1000']

# can see these are messed up
print(dat.loc[wood,var_rep].T)
dat.loc[wood,var_rep] = None
dat[var_rep] = dat[var_rep].interpolate()
print(dat.loc[wood,var_rep].T)

# setting these to be integers
dat[var_rep[:-1]] = dat[var_rep[:-1]].astype(int)

# only need limited fields
kf = ['ori','agency_name_edit', 'agency_type_name', 'state_abbr', 'data_year', 'population']

dat_75 = dat[dat['data_year'] >= 1975][kf].copy()
dat_75[kf[5:]] = dat_75[kf[5:]].astype(int)
dat_75.rename(columns={'data_year':'year', 'agency_name_edit':'agency', 'agency_type_name':'type'},inplace=True)

# I want to expand out, so each agency has 1975-2022 and interpolate any missing data
mm_ori = dat_75.groupby(['ori','agency','type'],as_index=False)['year'].agg([min,max])

# reshape to wide
def ri(x):
    return list(range(x[0],x[1]+1))

mm_ori['year'] = mm_ori[['min','max']].apply(ri,axis=1)
mm_ori = mm_ori.explode('year')
mm_ori['year'] = mm_ori['year'].astype(int)
mm_ori = mm_ori.merge(dat_75,how='left',on=['ori','agency','type','year'])

# now interpolating population estimates
mm_ori['interp'] =  mm_ori[['ori','population']].groupby('ori').transform(pd.Series.interpolate)
mm_ori['interp'] = mm_ori['interp'].round().astype(int) # this will fail if there are missing data
mm_ori['state_abbr'] = mm_ori['ori'].str[0:2]
mm_ori['imputed'] = mm_ori['population'].isna()*1
mm_ori.to_csv('ImputedORIPop_1975_2022.zip',index=False)

# Making smaller to hopefully fit in github
pivoted = mm_ori.pivot(index=['ori','agency','type'],columns='year',values='interp')
pivoted.reset_index(inplace=True)
ren_years = {y:f'Pop{y}' for y in range(1975,2023)}
pivoted.rename(columns=ren_years,inplace=True)

# only need to keep post 1992
py = [f'Pop{y}' for y in range(1992,2023)]
pivoted = pivoted[['ori','agency','type'] + py].copy()
pivoted[py] = pivoted[py].fillna(0).astype(int)
pivoted.to_csv('ORI_Pop.csv',index=False))



