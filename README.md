# Using Victimization Reporting Rates to Estimate the Dark Figure of Domestic Violence

Authors: Andrew P. Wheeler, PhD, Crime De-Coder LLC, Alex Piquero, University of Miami

[Pre-print](https://www.crimrxiv.com/pub/wed2u5af/release/1), [Council on CJ whitepaper](https://counciloncj.org/toward-a-better-estimate-of-domestic-violence-in-america/)

Work supported by the [Council on Criminal Justice](https://counciloncj.org/).

# Project Set Up

## Data Sources

The original data files used to conduct analysis are not saved in the github repo. They can be found at:

 - [NCVS Concatenated file, 1992-2022](https://www.icpsr.umich.edu/web/ICPSR/studies/38604)
 - [Jacob Kaplan's Concatenated NIBRS Files, 1991-2022](https://www.openicpsr.org/openicpsr/project/118281/version/V9/view)
 - LEOKA data on reported population served estimates for PDs, see the readme in the `./data/PopEstimates` folder for details.

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
    │   ├───NIBRS
    │   │   └───nibrs_1991_2022_victim_segment_rds
    │   │          nibrs_victim_segment_1991.rds
    │   │          nibrs_victim_segment_1992.rds
    │   │          ...
    │   │          nibrs_victim_segment_2021.rds
    │   │          nibrs_victim_segment_2022.rds
    │   │
    │   └───PopEstimates
    │              ORI_Pop.csv

## How to replicate

Once the data and R environment has been set up (it only relies on rms and ggplot2, the rest is base R), run the scripts in this order:

 1) `pred_model.R`
 2) `prep_NIBRS.R`
 3) `ori_graphs.R`

# Researchers

 - Andrew Wheeler, [Crime De-Coder](https://crimede-coder.com/)
 - Alex Piquero, [University of Miami](https://people.miami.edu/profile/d506d27f83929e0a9839caa0309ae881)