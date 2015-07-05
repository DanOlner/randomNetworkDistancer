#compare straight-line (or Great Circle) distance to route distance
library(sp)
library(ggplot2)
library(Hmisc)#for binning distances

routes <- read.csv("latestrbindOfMatrixOutputs.csv")

#convert distance to kms
routes$distance <- routes$distance / 1000

#For ease of reading, let's subset to get the values we want
# origins <- subset(routes, select = c(origin_x, origin_y))
# dests <- subset(routes, select = c(dest_x, dest_y))
# justcoords <- subset(routes, select = c(origin_x, origin_y, dest_x, dest_y))
# justcoords <- data.matrix(justcoords)

origins <- data.matrix(subset(routes, select = c(origin_x, origin_y)))
dests <- data.matrix(subset(routes, select = c(dest_x, dest_y)))

routes$spDist <- 0

for (i in 1:nrow(origins)) {
  
  #get a single pair, turn into matrix for spDistN1
  #needs transposing. Not sure why it doesn't keep the original orientation
  orig <- t(data.matrix(origins[i,]))
  #spDistN1: first arg needs to be a matrix of points. Supplying it with a single-row matrix
  #Second argument has to be a single point.
  #If the first arg had more values it would find all dists between each of those and the single point
  #But we only want each origin-destination pair distance
  #http://rpackages.ianhowson.com/rforge/sp/man/spDistsN1.html
  routes$spDist[i] <- spDistsN1(orig,dests[i,], longlat=TRUE)
  
}

plot(routes$distance, routes$spDist)

#ROUTE FACTOR
#I think I might reverse the ratio from the one I say in the PhD.
#Euclidean over route will be < 1, with it going towards asymptotic (lim -> 1) as routes become perfect.

#routes$rf <- routes$spDist/routes$distance
#Or have the ratio mean "how much further route distance is than Euclidean/Great Circle
routes$rf <- routes$distance/routes$spDist

plot(routes$distance, routes$rf)

bins = 10

#Hypothesis: route factor varies depending on distance. Lower distances have lower route factors.
#Use following to split into distance bins
#Then correlate average route factor per bin to average distance per bin
#http://stackoverflow.com/questions/6104836/splitting-a-continuous-variable-into-equal-sized-groups
routes$distbins <- as.numeric(cut2(routes$spDist, g=bins))

distmean <- rep(0,bins)
rfmean <- rep(0,bins)

rfhypo <- data.frame(distmean, rfmean)

#Use these bins to get average distance...
rfhypo$distmean <- tapply(routes$spDist, routes$distbins, mean)
#... and average route factor
rfhypo$rfmean <- tapply(routes$rf, routes$distbins, mean)

plot(rfhypo, xlab="distance", ylab="mean route factor")
lines(rfhypo, col="green")

sub <- routes[,c(11,12)]

#What's the distribution in each of the distance bins?
output <- ggplot(routes, aes(factor(distbins), rf)) +
  geom_boxplot()

output

sub <- routes[routes$distbins == 10,]

output <- ggplot(sub, aes(factor(distbins), rf)) +
  geom_boxplot()

output



