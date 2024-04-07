# Domestic Violence Trends

Council on Criminal Justice supported work, examining domestic violence trends over time.

# Project Set Up

# Data Sources

The original data files used to conduct analysis are not saved in the github repo. They can be found at:

 - [NCVS Concatenated file, 1992-2022](https://www.icpsr.umich.edu/web/ICPSR/studies/38604)
 - [Jacob Kaplan's Concatenated NIBRS Files, 1991-2022](https://www.openicpsr.org/openicpsr/project/118281/version/V9/view)

For the NCVS, I downloaded the R data files. For NIBRS, I downloaded the R data files individually into `/data/NIBRS`. After this was done and files were all unzipped, running `tree /f` the data directory looks as follows:

    ├───data
    │   ├───ICPSR_38604-V1
    │   │   └───ICPSR_38604
    │   │       │   38604-descriptioncitation.html
    │   │       │   38604-manifest.txt
    │   │       │   38604-related_literature.txt
    │   │       │   38604-User_guide.pdf
    │   │       │   factor_to_numeric_icpsr.R
    │   │       │   series-95-related_literature.txt
    │   │       │   TermsOfUse.html
    │   │       │
    │   │       ├───DS0001
    │   │       │       38604-0001-Codebook-ICPSR.pdf
    │   │       │       38604-0001-Data.rda
    │   │       │
    │   │       ├───DS0002
    │   │       │       38604-0002-Codebook-ICPSR.pdf
    │   │       │       38604-0002-Data.rda
    │   │       │       38604-0002-Documentation-readme_gzip.txt
    │   │       │
    │   │       └───DS0003
    │   │               38604-0003-Codebook-ICPSR.pdf
    │   │               38604-0003-Data.rda
    │   │
    │   └───NIBRS
    │       ├───nibrs_1991_2022_administrative_segment_rds
    │       │       nibrs_administrative_segment_1991.rds
    │       │       nibrs_administrative_segment_1992.rds
    │       │       ...
    │       │       nibrs_administrative_segment_2021.rds
    │       │       nibrs_administrative_segment_2022.rds
    │       │
    │       ├───nibrs_1991_2022_arrestee_segment_rds
    │       │       nibrs_arrestee_segment_1991.rds
    │       │       nibrs_arrestee_segment_1992.rds
    │       │       ...
    │       │       nibrs_arrestee_segment_2021.rds
    │       │       nibrs_arrestee_segment_2022.rds
    │       │
    │       ├───nibrs_1991_2022_group_b_arrest_report_segment_rds
    │       │       nibrs_group_b_arrest_report_segment_1991.rds
    │       │       nibrs_group_b_arrest_report_segment_1992.rds
    │       │       ...
    │       │       nibrs_group_b_arrest_report_segment_2021.rds
    │       │       nibrs_group_b_arrest_report_segment_2022.rds
    │       │
    │       ├───nibrs_1991_2022_offender_segment_rds
    │       │       nibrs_offender_segment_1991.rds
    │       │       nibrs_offender_segment_1992.rds
    │       │       ...
    │       │       nibrs_offender_segment_2021.rds
    │       │       nibrs_offender_segment_2022.rds
    │       │
    │       ├───nibrs_1991_2022_offense_segment_rds
    │       │       nibrs_offense_segment_1991.rds
    │       │       nibrs_offense_segment_1992.rds
    │       │       ...
    │       │       nibrs_offense_segment_2021.rds
    │       │       nibrs_offense_segment_2022.rds
    │       │
    │       ├───nibrs_1991_2022_property_segment_rds
    │       │       nibrs_property_segment_1991.rds
    │       │       nibrs_property_segment_1992.rds
    │       │       ...
    │       │       nibrs_property_segment_2021.rds
    │       │       nibrs_property_segment_2022.rds
    │       │
    │       ├───nibrs_1991_2022_victim_segment_rds
    │       │       nibrs_victim_segment_1991.rds
    │       │       nibrs_victim_segment_1992.rds
    │       │       ...
    │       │       nibrs_victim_segment_2021.rds
    │       │       nibrs_victim_segment_2022.rds
    │       │
    │       ├───nibrs_1991_2022_window_arrestee_segment_rds
    │       │       nibrs_window_arrestee_segment_1991.rds
    │       │       nibrs_window_arrestee_segment_1992.rds
    │       │       ...
    │       │       nibrs_window_arrestee_segment_2020.rds
    │       │       nibrs_window_arrestee_segment_2021.rds
    │       │
    │       ├───nibrs_1991_2022_window_exceptional_clearance_segment_rds
    │       │       nibrs_window_exceptional_clearance_segment_1991.rds
    │       │       nibrs_window_exceptional_clearance_segment_1992.rds
    │       │       ...
    │       │       nibrs_window_exceptional_clearance_segment_2020.rds
    │       │       nibrs_window_exceptional_clearance_segment_2021.rds
    │       │
    │       └───nibrs_1991_2022_window_recovered_property_segment_rds
    │               nibrs_window_recovered_property_segment_1991.rds
    │               nibrs_window_recovered_property_segment_1992.rds
    │               ...
    │               nibrs_window_recovered_property_segment_2020.rds
    │               nibrs_window_recovered_property_segment_2021.rds


# ToDo

 - Script to make files in easier format to work with
 - Identify demographic variables in NCVS overlap with NIBRS
   - person level: sex, age, race
   - geo: urban/rural, state
   - time: year, month

# Researchers

Andrew Wheeler,
https://crimede-coder.com/

Alex Piquero,
[University of Miami](https://people.miami.edu/profile/d506d27f83929e0a9839caa0309ae881)