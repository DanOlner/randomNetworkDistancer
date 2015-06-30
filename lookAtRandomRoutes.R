#Look at random route data harvested from google's distance matrix API

#setwd("C:/Users/geodo/Dropbox/R/Workspace/randomNetworkDistancer")

library(ggplot2)
library(reshape)
library(scales)

#Get last two...
#routes <- rbind(read.csv("latestrbindOfMatrixOutputs.csv"), read.csv("GoogleDistanceMatrixRandomPathRresults_Wed_May_21_18_06_23_2014.csv"))

#write.csv(routes, "latestrbindOfMatrixOutputs.csv")

routes <- read.csv("latestrbindOfMatrixOutputs.csv")

#Lets just check the basics
output <- ggplot(routes, aes(x = factor(1), y = (distance/1000))) +
  geom_boxplot(outlier.size = 3) +
  ggtitle(" ") +
  theme(plot.title = element_text(lineheight=.8, face="bold")) +
  xlab(" ") +
  ylab("Distance")

output

histyprinty <- ggplot(routes, aes(x=distance/1000)) +
#   scale_x_continuous(trans=log2_trans()) +  
  #   coord_cartesian(xlim = c(0, 10)) +
  ggtitle(" ") +
  theme(plot.title = element_text(lineheight=1.5, face="bold")) +
  #   theme_classic() +
  xlab("distance (km)") +
#   ylab("number of individual flows") +
#   geom_histogram(colour="white", fill="black")
  geom_histogram(colour="white", fill="black", binwidth = 25) +
  geom_vline(xintercept=mean(routes$distance/1000), color="red")
#   geom_histogram(colour="white", fill="black", binwidth = 0.75)
#           geom_histogram(aes(fill = value))

histyprinty

ggsave(histyprinty, file="randomisedDistanceRoutesUK.png", width=6, height=4, dpi = 600)


#normalise time and distance for comparison
maxDist <- max(routes$distance)
maxTime <- max(routes$time)

normedDistTime <- routes

normedDistTime$distance <- normedDistTime$distance/maxDist
normedDistTime$time <- normedDistTime$time/maxTime

#melt is very clever!
normedDistTime <- melt(normedDistTime, id="X", measure=c("distance","time"))

output <- ggplot(normedDistTime, aes(x = variable, y = value)) +
  geom_boxplot(outlier.size = 3) +
  ggtitle(" ") +
  theme(plot.title = element_text(lineheight=.8, face="bold")) +
  xlab(" ") +
  ylab("normalised values") +
  coord_flip()

output