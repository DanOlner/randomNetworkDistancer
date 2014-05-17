#Pick random points inside shapefile polygon
#Use Google distance matrix API to fetch network distance/time and addresses
#https://developers.google.com/maps/documentation/distancematrix/
#Store and save results as CSV

setwd("C:/Users/geodo/Dropbox/R/Workspace/randomNetworkDistancer")

library(rgdal)
library(plyr)
library(rgeos)
library(httr)
library(jsonlite)

#Load properties file
#Nabbed from http://stackoverflow.com/questions/13681310/reading-configuration-from-text-file
# myProp <- read.table("config.txt", header=FALSE, sep="=", row.names=1, strip.white=TRUE, na.strings="NA", stringsAsFactors=FALSE)
# myProp <- setNames(myProp[,1],row.names(myProp))
# myProp["dateOfLastLimitBreach"]

#record of failed calls
fail = 0

#Base URL, will knock query together below
testURL <- "http://maps.googleapis.com/maps/api/distancematrix/json"

#Use single shapefile of Great Britain
gbmerge <- readOGR(dsn="GB_merged", "GB_merged")

#Store the points
#Number of origin-destination pairs to create and fetch
#Note there's a pause of at least 0.2 seconds between each
#so getting >2000 of your daily google API allowance
#Might be around 7 minutes
#The csv won't be saved until the end of the process
#Job: add option to save regularly so's not to risk wasting API call limit
#DAILY ALLOWANCE IS 2500.
pairNum = 2

#http://casoilresource.lawr.ucdavis.edu/drupal/book/export/html/644
#sp package has specific tool for spatial sampling within polygons. Hooray!
randomPointOrigins <- spsample(gbmerge, n=pairNum, type='random')
randomPointDestinations <- spsample(gbmerge, n=pairNum, type='random')

#In case you wanna see em
#plot(gbmerge); points(randomPointDestinations, col='red', pch=3, cex=0.5); points(randomPointOrigins, col='blue', pch=3, cex=0.5)

#convert to lat long in prep for google query
randomPointOrigins <- spTransform(randomPointOrigins, CRS("+init=epsg:4326"))
randomPointDestinations <- spTransform(randomPointDestinations, CRS("+init=epsg:4326"))

#Use dataframe, single row per origin-destination pair
randomPointOrigins <- data.frame(randomPointOrigins)
randomPointDestinations <- data.frame(randomPointDestinations)

#Distinguish x and y column names (for later CSV writing)
colnames(randomPointOrigins)[colnames(randomPointOrigins)=="x"] <- "origin_x"
colnames(randomPointOrigins)[colnames(randomPointOrigins)=="y"] <- "origin_y"
colnames(randomPointDestinations)[colnames(randomPointDestinations)=="x"] <- "dest_x"
colnames(randomPointDestinations)[colnames(randomPointDestinations)=="y"] <- "dest_y"

#Final set of origin-destination points
pointSet <- cbind(randomPointOrigins,randomPointDestinations)

#Create results matrix, one row per origin-destination pair
#Storing four results: distance and time of each route
#(Distance in metres, time in seconds)
#And also the strings for the address of origins and destinations
results <- matrix(nrow=pairNum , ncol=4)

#Iterate over required pair numbers, get data from google
for(i in 1:pairNum) {

#set google distance matrix query
#Google does y,x. Reverse order
#See https://developers.google.com/maps/documentation/distancematrix/ for option info
qry <- paste("origins=", pointSet[i,2] , "," , pointSet[i,1] ,
             "&destinations=" ,pointSet[i,4] , "," , pointSet[i,3] ,
             "&sensor=FALSE",
             "&avoid=ferries",#not going to any islands!
             sep=""#no spaces
)

#Get the JSON
gimme <- GET(
  testURL,  
  query = qry,
  #If using in Leeds University, obv: comment this out if not, or if using Leeds Uni wifi
  #Use this to see details of proxy connection: c(use_proxy("www-cache.leeds.ac.uk:3128", 8080), verbose())
  c(use_proxy("www-cache.leeds.ac.uk:3128", 8080))
)

#http://blog.rstudio.org/2014/03/21/httr-0-3/
stop_for_status(gimme)

store <- content(gimme)

#if result was OK, keep
# if(store$status=="OK") {
if(store$rows[[1]]$elements[[1]]$status=="OK") {
  results[i,1] <- store$rows[[1]]$elements[[1]]$distance$value
  results[i,2] <- store$rows[[1]]$elements[[1]]$duration$value
  results[i,3] <- store$origin_addresses[[1]]
  results[i,4] <- store$destination_addresses[[1]]
} else {
  fail <- fail + 1
}

#pause between API calls. We're aiming for:
# "100 elements per 10 seconds."
# "2500 elements per 24 hour period."
#Two elements per call (origin and destination)
#Being conservative: 0.3 seconds should hit ~66 elements per 10 seconds
Sys.sleep(0.3)

print(paste("API call", i, "complete, status: ", store$rows[[1]]$elements[[1]]$status))

}#end for

#Append the coordinates used
readyForWriting <- cbind(data.frame(results),pointSet)

colnames(readyForWriting)[colnames(readyForWriting)=="X1"] <- "distance"
colnames(readyForWriting)[colnames(readyForWriting)=="X2"] <- "time"
colnames(readyForWriting)[colnames(readyForWriting)=="X3"] <- "origin"
colnames(readyForWriting)[colnames(readyForWriting)=="X4"] <- "destination"

#Strip out failed calls
readyForWriting <- readyForWriting[ !is.na(readyForWriting$distance) ,]

#Write the final results file
write.csv(readyForWriting, "GoogleDistanceMatrixRandomPathRresults2.csv")

print(paste(pairNum, "attempts, ", (pairNum - fail), "successful."))