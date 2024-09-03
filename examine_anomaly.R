
base_data <- "./data/NIBRS/"
base_vic <- paste0(base_data,"nibrs_1991_2022_victim_segment_rds/nibrs_victim_segment_")


# Check Wichita KS0870300

year <- 2021

nvic2019 <- readRDS(file=paste0(base_vic,"2019",".rds"))
nvic2021 <- readRDS(file=paste0(base_vic,"2021",".rds"))
nvic2022 <- readRDS(file=paste0(base_vic,"2022",".rds"))


# Check Lubbock TX1520200

lub2021 <- nvic2021[nvic2021$ori == 'TX1520200',]
lub2022 <- nvic2022[nvic2022$ori == 'TX1520200',]
table(lub2021$agg_assault_homicide_circumsta1)
table(lub2022$agg_assault_homicide_circumsta1)

# This looks normal

# Check Wichita KS0870300

wich2019 <- nvic2019[nvic2019$ori == 'KS0870300',]
wich2021 <- nvic2021[nvic2021$ori == 'KS0870300',]
wich2022 <- nvic2022[nvic2022$ori == 'KS0870300',]

table(wich2019$agg_assault_homicide_circumsta1)
table(wich2021$agg_assault_homicide_circumsta1)
table(wich2022$agg_assault_homicide_circumsta1)

wich2021$mnths <- substring(wich2021$incident_date,6,7)
table(wich2021$mnths) # only partial reporting

wich2019$mnths <- substring(wich2019$incident_date,6,7)
table(wich2019$mnths) # only partial reporting