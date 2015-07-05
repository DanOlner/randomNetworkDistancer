library(rgdal)
library(rgeos)
library(httr)
library(jsonlite)
library(reshape2)

#apikey <- read.csv("apikey.csv")
#apikey <- apikey[1,]

#Base URL, will knock query together below
testURL <- "https://maps.googleapis.com/maps/api/distancematrix/json"

venuesNPostcodes <- read.csv("tramlineVenues_n_Postcodes.csv")
postcodes <- venuesNPostcodes[,2]

postcodes <- gsub(" ", "", postcodes, fixed=TRUE)
venues <- venuesNPostcodes[,1]

#turn postcodes into a melted list of pairs
#(This is one way of avoiding the matrix API limits)
postcodematrix <- matrix(nrow=length(postcodes) , ncol=length(postcodes))
rownames(postcodematrix) <- postcodes
colnames(postcodematrix) <- postcodes

postcodepairs <- melt(postcodematrix)

results <- matrix(nrow=nrow(postcodepairs) , ncol=4)

#loop over pairs, thus only two `elements' per query
for(i in 1:nrow(postcodepairs)) {
  

#set google distance matrix query
#See https://developers.google.com/maps/documentation/distancematrix/ for option info
qry <- paste("origins=", postcodepairs$Var1[i],
             "&destinations=", postcodepairs$Var2[i] ,
             "&sensor=FALSE",
              "&mode=walking",
             #"&key=",
             #apikey,
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

#Being conservative: 0.3 seconds should hit ~66 elements per 10 seconds
Sys.sleep(0.3)

if(store$rows[[1]]$elements[[1]]$status=="OK") {
  results[i,1] <- store$rows[[1]]$elements[[1]]$distance$value
  results[i,2] <- store$rows[[1]]$elements[[1]]$duration$value
  results[i,3] <- store$rows[[1]]$elements[[1]]$distance$text
  results[i,4] <- store$rows[[1]]$elements[[1]]$duration$text
} else {
  results[i,1] <- "xxx"
  results[i,2] <- "xxx"
  results[i,3] <- "xxx"
  results[i42] <- "xxx"
}


}#end for

#just while I'm playing...
resultsBackup <- results

#get ride of odd diagonal. 1 minute to get to where I'm standing?
#results[results == "1 m"] <- "0"
#results[results == "1 min"] <- "0 min"

#Just verbal description of time and distance
textresults <- results[,3:4]

textresults <- data.frame(textresults)

#Foundry and fusion have the same postcode
#need to add unique identifier to deal with that
textresults$id <- rep(1:16, times = 16)

#join up postcodes. One matrix for distance, one for time
distance <- cbind(postcodepairs, textresults)
distance <- distance[,c(1,2,5,6)]

distancematrix <- dcast(distance, Var1 + id ~ Var2, value.var = "X2")






#Add postcode labels
rownames(distresultstext) <- postcodes
colnames(distresultstext) <- postcodes

rownames(timeresultstext) <- postcodes
colnames(timeresultstext) <- postcodes

#get ride of odd diagonal. 1 minute to get to where I'm standing?
distresultstext[distresultstext == "1 m"] <- "0"
timeresultstext[timeresultstext == "1 min"] <- "0 min"

write.csv(distresultstext, file="distresults.csv")
write.csv(timeresultstext, file="timeresults.csv")

#Or use venue names, more logically!
rownames(distresultstext) <- venues
colnames(distresultstext) <- venues

rownames(timeresultstext) <- venues
colnames(timeresultstext) <- venues

write.csv(distresultstext, file="distresults_venues.csv")
write.csv(timeresultstext, file="timeresults_venues.csv")