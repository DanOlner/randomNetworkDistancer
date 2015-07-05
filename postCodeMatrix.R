library(rgdal)
library(rgeos)
library(httr)
library(jsonlite)

apikey <- read.csv("apikey.csv")
apikey <- apikey[1,]

#Base URL, will knock query together below
testURL <- "https://maps.googleapis.com/maps/api/distancematrix/json"

#venuesNPostcodes <- read.csv("tramlineVenues_n_Postcodes.csv")
postcodes <- venuesNPostcodes[,2]
#postcodes <- c("s118sa","s71bx","ls84dr")
#no whitespace
postcodes <- gsub(" ", "", postcodes, fixed=TRUE)
venues <- venuesNPostcodes[,1]

#OD matrix
distresults <- matrix(nrow=length(postcodes) , ncol=length(postcodes))
timeresults <- matrix(nrow=length(postcodes) , ncol=length(postcodes))

distresultstext <- matrix(nrow=length(postcodes) , ncol=length(postcodes))
timeresultstext <- matrix(nrow=length(postcodes) , ncol=length(postcodes))

#matrix API wants addresses separated by vertical bar
postcodeString <- paste(postcodes, collapse="|")

#set google distance matrix query
#See https://developers.google.com/maps/documentation/distancematrix/ for option info
qry <- paste("origins=", postcodeString,
             "&destinations=", postcodeString ,
             "&sensor=FALSE",
              "&mode=walking",
             "&key=",
             apikey,
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

#Parse postcodes
#"results are returned in rows, each row containing one origin paired with each destination"
#So assume origins are columns, cycle through each row and get elements
for(origins in 1:length(postcodes)) {
  
  for(dests in 1:length(postcodes)) {
    
    distresults[dests,origins] <- store$rows[[origins]]$elements[[dests]]$distance$value
    timeresults[dests,origins] <- store$rows[[origins]]$elements[[dests]]$duration$value
    
    distresultstext[dests,origins] <- store$rows[[origins]]$elements[[dests]]$distance$text
    timeresultstext[dests,origins] <- store$rows[[origins]]$elements[[dests]]$duration$text
    
    
  }
  
}

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