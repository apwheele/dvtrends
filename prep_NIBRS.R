# prepping the NIBRS data
library(rms) # for restricted cubic splines

# Region states
northeast <- c("CT","ME","MA","NH","RI","VT","NJ","NY","PA")
midwest <- c("IL","IN","MI","OH","WI","IA","KS","MN","MO","NE","SD","ND")
south <- c("KY","TN","MS","AL","WV","MD","DC","DE","VA","NC","SC","GA","FL","TX","OK","AR","LA")
west <- c("WA","OR","CA","MT","ID","WY","NV","UT","CO","AZ","NM","AK","HI")


base_data <- "./data/NIBRS/"
base_off <- paste0(base_data,"nibrs_1991_2022_offense_segment_rds/nibrs_offense_segment_")
base_vic <- paste0(base_data,"nibrs_1991_2022_victim_segment_rds/nibrs_victim_segment_")
base_admin <- paste0(base_data,"nibrs_1991_2022_administrative_segment_rds/nibrs_administrative_segment_")
base_arrest <- paste0(base_data,"nibrs_1991_2022_arrestee_segment_rds/nibrs_arrestee_segment_")
base_groupb <- paste0(base_data,"nibrs_1991_2022_group_b_arrest_report_segment_rds/nibrs_group_b_arrest_report_segment_")
dvstr <- "domestic violence (historically called lovers triangle/quarrel)"

# get the population data
ori_pop <- read.csv("./data/PopEstimates/ORI_Pop.csv")
rownames(ori_pop) <- ori_pop$ori

# get the model data, dva and mod
load("./data/model.RData")

# this function preps the NIBRS data files to be the same
# format as the 

prep_nibrs <- function(year){
    # read in data
    nvic <- readRDS(file=paste0(base_vic,year,".rds"))
    nvic$year <- year # not sure why any missing here
    # I only need the DV aggravated assault cases
    dvc <- rowSums(nvic[,c("agg_assault_homicide_circumsta1","agg_assault_homicide_circumsta2")] == dvstr, na.rm=TRUE)
    nvic <- nvic[dvc > 0,]
    # now for the same variables as NCVS
    # Female dummy
    nvic$female <- (nvic$sex_of_victim == "female")*1
    # Age, only older than 12
    age <- as.numeric(nvic$age_of_victim)
    age <- ifelse(nvic$age_of_victim == "7-364 days old",0,age)
    #age[is.na(age)] <- mean(age,na.rm=TRUE) # mean imputation of those missing
    nvic$age <- age
    nvic <- nvic[nvic$age > 12,]
    # White
    nvic$white <- (nvic$race_of_victim == "white")*1
    # Black
    nvic$black <- (nvic$race_of_victim == "black")*1
    # Native
    nvic$nat <- (nvic$race_of_victim == "american indian/alaskan native")*1
    # asian/islander
    nvic$asa_isl <- ( (nvic$race_of_victim == "asian") | (nvic$race_of_victim == "asian") )*1
    # imputing unknown to multi
    nvic$mult <- (nvic$race_of_victim == "unknown")*1
    # Hispanic (this imputes missing to non-hispanic)
    nvic$hisp <- (nvic$ethnicity_of_victim == "hispanic origin")*1
    nvic$hisp[is.na(nvic$hisp)] = 0
    # Regions, Northeast
    nvic$northeast <- (nvic$state_abb %in% tolower(northeast))*1
    # midwest
    nvic$midwest <- (nvic$state_abb %in% tolower(midwest))*1
    # south
    nvic$south <- (nvic$state_abb %in% tolower(south))*1
    # west
    nvic$west <- (nvic$state_abb %in% tolower(west))*1
    # miss_region, always filled in for this data
    nvic$miss_region <- 0
    # Population bands, merging in data from LEOKA, filling in missing with 0
    ypop = paste0('Pop',year)
    nvic$pop <- ori_pop[nvic$ori,c(ypop)]
    nvic$pop[is.na(nvic$pop)] <- 0
    # I want to do this in a second step imputing with the full data
    # Pop under 50k
    nvic$pop_under50 <- ifelse(nvic$pop < 50000,1,0)
    # 50-250k
    nvic$pop_50_250 <- ifelse( (nvic$pop >= 50000) & (nvic$pop < 250000),1,0)
    # over 250k
    nvic$pop_over250 <- ifelse(nvic$pop >= 250000,1,0)
    # imputing age according to linear regression of other factors
    agemod <- lm(age ~ female + black + nat + asa_isl + mult + hisp + state_abb + pop,data=nvic)
    pred_age <- predict(agemod,newdata=nvic)
    mis_age <- is.na(nvic$age)
    nvic$age[mis_age] <- pred_age[mis_age]
    # keep variables
    mvars <- c('year','female','age','white','black','nat','asa_isl','mult','hisp',
           'northeast','midwest','south','west','miss_region','pop_under50','pop_50_250','pop_over250')
    keep_var <- c("ori","state_abb","incident_date","unique_incident_id",mvars)
    # only returning those data I want
    mis_dat = is.na(nvic$ori)
    return(nvic[!mis_dat,keep_var])
}


# getting all the data
years <- 1992:2022
res <- vector(mode="list",length=length(years))
for (i in 1:length(years)) {
    y <- years[i]
    print(paste0('Getting year ',y,' ',Sys.time()))
    res[[i]] <- prep_nibrs(y)
}


nvic_data <- do.call("rbind",res)
print(dim(nvic_data))

# now apply the predictions
pred_vic <- predict(mod,newdata=nvic_data,type="response",se.fit=TRUE)
nvic_data$prob <- pred_vic$fit
nvic_data$se <- pred_vic$se.fit
nvic_data$weight <- 1/nvic_data$prob
nvic_data$tot <- 1

# saving the full fitted file and aggregate data
save(nvic_data,file="./data/fitData.RData")

write.csv(nvic_data,"./data/fitData.csv")

# aggregating to ori/year
agg_data <- aggregate(cbind(weight,tot) ~ ori + year,FUN=sum,data=nvic_data)



# saving the full fitted file and aggregate data
save(agg_data,file="./data/aggData.RData")
write.csv(nvic_data,"./data/aggData.csv")
