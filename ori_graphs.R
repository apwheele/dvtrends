# This illustrates creating graphs of different ORIs
library(ggplot2)
library(stringr)

vic <- readRDS(file="./data/fitData.rds")
ori_pop <- read.csv("./data/PopEstimates/ORI_Pop.csv")

# if you want to see agencies with the most reports
# can do
#vori <- as.data.frame(table(vic$ori))
#vori <- vori[order(-vori$Freq),]

# seeing if any particular agency has lower probabilites
# so upweight will be more
#ap <- aggregate(cbind(prob,tot) ~ ori,data=vic,FUN=sum)
#ap$prob <- ap$prob/ap$tot
#ap <- ap[order(ap$prob),]
#head(ap[ap$tot > 100,],30)



# ggplot theme
theme_andy <- function(){
  theme_bw() %+replace% theme(
     text = element_text(size = 16),
     panel.grid.major= element_line(linetype = "longdash"),
     panel.grid.minor= element_blank()
) }

# setting the max upweight to 50
clip_probs <- function(x){
    xn <- ifelse(x > 1,1,x)
    xn <- ifelse(x < 0.02,0.02,xn)
    return(xn)
}

prep_ori <- function(ori,n_sims=1000,ci_probs=c(0.01,0.99)){
    # Slicing out ORI I want
    ori_vic <- vic[vic$ori == ori,]
    ori_name <- ori_pop[ori_pop$ori == ori,]
    n_rows <- nrow(ori_vic)
    v_names <- rep(NA,n_sims)
    # Generating simulated errors
    for (i in 1:n_sims){
        vn <- paste0('s',i)
        v_names[i] <- vn
        samp_prob <- clip_probs(rnorm(n_rows,ori_vic$prob,ori_vic$se))
        ori_vic[,vn] <- 1/samp_prob
    }
    # aggregating weights and observed, getting errors
    agg_ori <- aggregate(. ~ year,data=ori_vic[,c("year","tot","weight",v_names)],FUN=sum)
    agg_ori$add_weight <- agg_ori$weight - agg_ori$tot
    quants <- as.data.frame(t(apply(agg_ori[,v_names],1,quantile,probs=ci_probs)))
    names(quants) <- c("Low","High")
    agg_ori$Low <- quants$Low
    agg_ori$High <- quants$High
    # getting population per year
    agg_pop <- aggregate(pop ~ year,data=ori_vic,FUN=max)
    agg_ori$pop <- agg_pop$pop
    # Calculating rates per 100k
    agg_ori$TotRate <- (agg_ori$tot/agg_ori$pop)*100000
    agg_ori$WeightRate <- (agg_ori$weight/agg_ori$pop)*100000
    agg_ori$AddRate <- agg_ori$WeightRate - agg_ori$TotRate
    agg_ori$LowRate <- (agg_ori$Low/agg_ori$pop)*100000
    agg_ori$HighRate <- (agg_ori$High/agg_ori$pop)*100000
    agg_ori$agency <- ori_name$agency[1]
    agg_ori$type <- ori_name$type[1]
    agg_ori <- agg_ori[,c("year","agency","type","pop","tot","weight",
                          "add_weight","Low","High","TotRate","WeightRate",
                           "AddRate","LowRate","HighRate")]
    return(agg_ori)
}

count_graph <- function(data,file_name,title=data$agency[1],height=5,width=10,res=1000) {
    # Added count graph
    tall1 <- data[,c("year","tot")]
    tall1$group <- "Reported"
    tall2 <- data[,c("year","add_weight")]
    names(tall2) <- c("year","tot")
    tall2$group <- "Underreported"
    tall <- rbind(tall1,tall2)
    tall$group <- factor(tall$group,c("Underreported","Reported"))
    p <- ggplot(tall,aes(x=year,y=tot,fill=group)) +
         geom_bar(position="stack",stat="identity",color="black") +
         scale_fill_manual(values = c("#66bac9","#8893ca"), name="") + 
         labs(x='Year',y='Counts',title=title,
              caption='Aggravated Domestic Assault Estimates') +
         theme_andy()
    png(file=file_name,bg="transparent",height=height,width=width,units="in",res=1000)
    print(p)
    dev.off()
    return(p)
}

# orig "#dd1c77","#f1eef6"
# new 66bac9

# Rates with errors over time
rate_graph <- function(data,file_name,title=data$agency[1],height=5,width=8,res=1000) {
    p <- ggplot(data,aes(x=year,y=WeightRate,ymin=LowRate,ymax=HighRate)) +
         geom_ribbon(fill="#66bac9",alpha=0.9) + 
         expand_limits(y=0) +
         labs(x='Year',y='Rate per 100,000',title=title,
              caption='Aggravated Domestic Assault Estimates') +
         theme_andy()
    png(file=file_name,bg="transparent",height=height,width=width,units="in",res=1000)
    print(p)
    dev.off()
    return(p)
}


memphis <- prep_ori("TNMPD0000")
p <- count_graph(memphis,"./paper/MemphisCount.png","Memphis")
p <- rate_graph(memphis,"./paper/MemphisRate.png","Memphis")

detroit <- prep_ori("MI8234900")
p <- count_graph(detroit,"./paper/DetroitCount.png","Detroit")
p <- rate_graph(detroit,"./paper/DetroitRate.png","Detroit")

denver <- prep_ori("CODPD0000")
p <- count_graph(denver,"./paper/DenverCount.png","Denver")
p <- rate_graph(denver,"./paper/DenverRate.png","Denver")

honolulu <- prep_ori("HI0020000")
p <- count_graph(honolulu,"./paper/HonoluluCount.png","Honolulu")
p <- rate_graph(honolulu,"./paper/HonoluluRate.png","Honolulu")

beaufort <- prep_ori("SC0070000")
p <- count_graph(beaufort ,"./paper/BeaufortCount.png","Beaufort County")
p <- rate_graph(beaufort ,"./paper/BeaufortRate.png","Beaufort County")

saltlake <- prep_ori("UT0180300")
p <- count_graph(saltlake,"./paper/SaltLakeCount.png","Salt Lake")
p <- rate_graph(saltlake,"./paper/SaltLakeRate.png","Salt Lake")

lubbock <- prep_ori("TX1520200")
p <- count_graph(lubbock,"./paper/LubbockCount.png","Lubbock")
p <- rate_graph(lubbock,"./paper/LubbockRate.png","Lubbock")


# Make a graph, 20 largest cities
# original + up for 2022
up2022 <- aggregate(cbind(weight,tot) ~ ori,data=vic[vic$year == 2022,],FUN=sum)
up2022 <- up2022[order(up2022$weight),]
rownames(ori_pop) <- ori_pop$ori
up2022$agency <- ori_pop[up2022$ori,c("agency")]
up2022 <- up2022[,c("ori","agency","weight","tot")]
write.csv(up2022,"up2022.csv",row.names=FALSE)
up2022 <- tail(up2022,20)
up2022$agency <- gsub("POLICE DEPARTMENT","",up2022$agency)
up2022$agency <- gsub("PD","",up2022$agency)
up2022$agency <- gsub("POLICE ADMIN","",up2022$agency)
up2022$agency <- gsub("METROPOLITAN","",up2022$agency)
up2022$agency <- str_squish(up2022$agency)
up2022$agency <- factor(up2022$agency,levels=up2022$agency)

p <- ggplot(up2022) +
     geom_segment(aes(x=tot,xend=weight,y=agency,yend=agency)) + 
     geom_point(aes(x=tot,y=agency,fill="Reported"),pch=21,color="black",size=5.5) +
     geom_point(aes(x=weight,y=agency,fill="Underreported"),pch=21,color="black",size=5.5) +
     scale_fill_manual(values = c("#8893ca","#66bac9"), name="") +
     labs(x='Domestic Violence Counts',y="",title="Top 20 Cities with Most Domestic Violence",
          caption='Aggravated Assault Estimates') +
     theme_andy() +
     theme(axis.text.x = element_text(size=12))

png(file="./paper/TopCities2022.png",bg="transparent",height=6,width=10,units="in",res=1000)
print(p)
dev.off()


# Get top 200, generate data, combine data
tot_rep <- 50
up2022 <- aggregate(cbind(weight,tot) ~ ori,data=vic[vic$year == 2022,],FUN=sum)
up2022 <- up2022[order(up2022$weight),]
rownames(ori_pop) <- ori_pop$ori
up2022$agency <- ori_pop[up2022$ori,c("agency")]
up2022 <- up2022[,c("ori","agency","weight","tot")]
up2022 <- up2022[up2022$tot > tot_rep,]

tot_n <- dim(up2022)[1]
res <- vector(mode="list",length=tot_n)
for (i in 1:tot_n){
    ori <- up2022$ori[i]
    ld <- prep_ori(ori)
    ld$ori <- ori
    res[[i]] <- ld
}

res_topk <- do.call("rbind",res)
write.csv(res_topk,"TrendsOver50.csv",row.names=FALSE)

# quite ugly
ggplot(res_topk, aes(x = year, y = WeightRate, group = agency)) + geom_line() + theme_andy()
