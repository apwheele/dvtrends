# robustness check
# checking out correlation between weighted models

library(rms)

fitdata <- readRDS(file="./data/fitData.rds")
load(file="./data/modelW.RData")

p2 <- predict(modw,newdata=fitdata,type="response",se.fit=TRUE)
fitdata$p2 <- p2$fit
cor(fitdata[,c("prob","p2")]) # 96%

fitdata$w2 <- 1/fitdata$p2

yearstats <- aggregate(cbind(weight,w2) ~ year,data=fitdata,FUN=sum)
yearstats$pdif <- (yearstats$weight - yearstats$w2)/yearstats$weight
write.csv(yearstats,"./data/yearWeightCheck.csv",row.names=FALSE) # max 2% apart