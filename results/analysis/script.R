setwd("~/ChainingStrategy/results")

# RANGE
metrics <- data.frame(mean_steps=0, sd_steps=0, mean_chain=0, sd_chain=0)

folders = c("300-30","250-30","200-30","175-30","150-30","300-40","300-25","300-22")
for (i in 1:6)
{
  data <- read.table(paste(folders[i],"/results.txt",sep=""))
  metrics[i,1] <- mean(data$V1)
  metrics[i,2] <- sd(data$V1)
  metrics[i,3] <- mean(data$V2)
  metrics[i,4] <-  sd(data$V2) 
}

###### NUMBER OF ROBOTS

folders = c("300-40","300-30","300-25","300-22")
for (i in 1:4)
{
  data <- read.table(paste(folders[i],"/results.txt",sep=""))
  metrics[i,1] <- mean(data$V1)
  metrics[i,2] <- sd(data$V1)
  metrics[i,3] <- mean(data$V2)
  metrics[i,4] <-  sd(data$V2) 
}
