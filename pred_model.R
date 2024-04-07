# This code fits a predictive model from NCVS
library(rms) # for restricted cubic splines
library(ggplot2)

# Prepping the NCVS file for modeling
load(file='./data/ICPSR_38604-V1/ICPSR_38604/DS0003/38604-0003-Data.rda')
ncvs <- get(ls()[1]) # in a specific named dataframe

# ggplot theme
theme_andy <- function(){
  theme_bw() %+replace% theme(
     text = element_text(size = 16),
     panel.grid.major= element_line(linetype = "longdash"),
     panel.grid.minor= element_blank()
) }

# Identifying cases that are domestic abuse
# Thank you to Rachael Powers for help with this!
# how she did it in 
# https://journals.sagepub.com/doi/abs/10.1177/08862605221114304
table(ncvs$V4245)

nV4245 <- as.numeric(ncvs$V4245)
nV4265 <- as.numeric(ncvs$V4265)
nV4266 <- as.numeric(ncvs$V4266)
nV4271 <- as.numeric(ncvs$V4271)
one_off <- (nV4245 == 1) | (nV4245 == 2) | (nV4245 == 7)
mult_off <- (nV4265 == 1) | (nV4266 == 1) | (nV4271 == 1)
dom_vio <- one_off | mult_off
dv <- ncvs[!is.na(dom_vio),]

# aggravated assault, 11 is completed 12 is attempted
nV4529 <- as.numeric(dv$V4529)
assault <- nV4529 %in% c(11,12)
dva <- dv[assault,]

# Reported to police
police_report <- ifelse(as.numeric(dva$V4399) == 1, 1, 0)
police_report[as.numeric(dva$V4399) > 2] <- NA
dva$prep <- police_report

# Female victim (no missing at this point)
female <- ifelse(as.numeric(dva$V3018) == 2, 1, 0)
dva$female <- female

# Age & year
dva$age <- dva$V3014
dva$year <- dva$YEAR

# Race of victim, White | Black | Native American | 
# Asian | Islander combined in older
# Multiple
nV3023 <- as.numeric(dva$V3023)
nV3023[is.na(nV3023)] <- 99
nV3023A <- as.numeric(dva$V3023A)
nV3023A[is.na(nV3023A)] <- -1

white <- (nV3023 == 1) | (nV3023A == 1)
black <- (nV3023 == 2) | (nV3023A == 2)
nat <- (nV3023 == 3) | (nV3023A == 3)
asa_isl <- (nV3023 == 4) | (nV3023A == 4) | (nV3023A == 5)
mult <- (nV3023A > 5)

dva$white <- white*1
dva$black <- black*1
dva$nat <- nat*1
dva$asa_isl <- asa_isl*1
dva$mult <- mult*1

# Hispanic is separate in both NCVS and NIBRS
nV3024 <- as.numeric(dva$V3024)
nV3024[is.na(nV3024)] <- -1
nV3024A <- as.numeric(dva$V3024A)
nV3024A[is.na(nV3024A)] <- -1

hisp <- (nV3024 == 1) | (nV3024A == 1)
dva$hisp <- hisp*1

# US region, for older years not filled in
nV2127B <- as.numeric(dva$V2127B)
nV2127B[is.na(nV2127B)] <- 5
dva$northeast <- 1*(nV2127B == 1)
dva$midwest <- 1*(nV2127B == 2)
dva$south <- 1*(nV2127B == 3)
dva$west <- 1*(nV2127B == 4)
dva$miss_region <- 1*(nV2127B == 5)

# Place size codes
nV2126A <- as.numeric(dva$V2126A)
#nV2126A[is.na(nV2126A) <- -1
nV2126B <- as.numeric(dva$V2126B)
#nV2126B[is.na(nV2126B) <- -1

# note these are the *levels* in R, not the factor labels
pop_under50 <- (nV2126A %in% c(1,2,3,4,5)) | (nV2126B %in% c(1,2,3))
pop_50_250 <- (nV2126A %in% c(6,7)) | (nV2126B %in% c(4,5))
pop_over250 <- (nV2126A %in% c(8,9,10)) | (nV2126B %in% c(6,7,8,9,10))

pop_under50[is.na(pop_under50)] <- 0
pop_50_250[is.na(pop_50_250)] <- 0
pop_over250[is.na(pop_over250)] <- 0

dva$pop_under50 <- pop_under50
dva$pop_50_250 <- pop_50_250
dva$pop_over250 <- pop_over250

# Variables you need for prediction
mvars <- c('prep','year','female','age','white','black','nat','asa_isl','mult','hisp',
           'northeast','midwest','south','west','miss_region','pop_under50','pop_50_250',
           'pop_over250')

dva <- dva[,mvars]

# There ends up being only 6 NA's for police reporting, just drop them
dva <- dva[!is.na(dva$prep),]

# year (spline, 1992-2022, [1999,2007,2015])
# female
# age (spline, 12-88, [25,40,65]
# white [is referent category]
# black
# nat
# asa_isl
# mult
# hisp
# northeast [regions, miss_region is referent]
# midwest
# south
# west
# miss_region
# pop_under50 [reference]
# pop_50_250
# pop_over250

mod <- glm(prep ~ rcs(year,c(1999,2007,2015)) + rcs(age,c(25,40,65)) + 
           female + black + nat + asa_isl + mult + hisp + 
           northeast + midwest + south + west + pop_50_250 + pop_over250,
           data = dva, family = "binomial")

########################
# Lets do a predicted plots of age and year
margin_year <- 1992:2022
margin_prob <- rep(NA,length(margin_year))

i <- 0
for (y in 1992:2022){
    i <- i + 1
    newdat <- dva
    newdat$year <- y
    pred <- predict(mod,newdata=newdat,type="response")
    margin_prob[i] <- mean(pred)
}

# add in the raw data
rep_perc <- aggregate(prep ~ year,data=dva,FUN=mean)
rep_totn <- as.data.frame(table(dva$year))

# observed data are quite noisy, but can see when superimposing where
# overall trend comes from
year_grade <- data.frame(year=margin_year,pred=margin_prob,obs=rep_perc$prep,totn=rep_totn$Freq)

ym <- ggplot(data=year_grade, aes(x=year,y=pred)) + 
      geom_line(size=1.6) +
      scale_x_continuous(breaks=seq(1992,2022,5)) +
      scale_y_continuous(breaks=seq(0.6,0.74,0.02)) + 
      labs(x='Year',y='Probability',title='Reporting Rates for Dom. Viol.',caption="Aggravated Assault from NCVS") +
      theme_andy()

png(file="YearMargins.png",bg="transparent",height=4,width=6,units="in",res=1000)
ym
dev.off()

margin_age <- 12:88
margin_prob <- rep(NA,length(margin_age))

i <- 0
for (a in margin_age){
    i <- i + 1
    newdat <- dva
    newdat$age <- a
    pred <- predict(mod,newdata=newdat,type="response")
    margin_prob[i] <- mean(pred)
}

age_grade <- data.frame(age=margin_age,pred=margin_prob)

am <- ggplot(data=age_grade, aes(x=age,y=pred)) + 
      geom_line(size=1.6) +
      scale_x_continuous(breaks=seq(10,90,5)) +
      scale_y_continuous(breaks=seq(0.53,0.73,0.02)) + 
      labs(x='Age',y='Probability',title='Reporting Rates for Dom. Viol.',caption="Aggravated Assault from NCVS") +
      theme_andy()

png(file="AgeMargins.png",bg="transparent",height=4,width=6,units="in",res=1000)
am
dev.off()

#######################
