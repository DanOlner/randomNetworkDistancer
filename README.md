randomNetworkDistancer
======================

![route factor](https://github.com/DanOlner/randomNetworkDistancer/blob/master/images/routefactor_vs_distance_straightline_over_route.png)

> "Route factor" for the UK, calculated from data collected using randomNetworkDistancer. "Route factor" here is road network route over Euclidean (actually Great Circle) distance, so it's "how much further are road routes than the crow flys?" The route factor for a range of distances clearly shows how longer journeys get more efficient. Code for this plot is in routeFactor.R

Using R to find and save random routes in a given shapefile using Google's distance matrix API. 
It will output a CSV containing origin/destination details, the road network distance between them 
and the time taken to travel, according to Google. Each CSV is date/time-stamped in the filename so they won't overwrite each other.

Read [Google's distance matrix API page](https://developers.google.com/maps/documentation/distancematrix/) 
for full details of how it works. You can only get a maximum of 2500 routes per day without paying them. 
To get the maximum daily number, the API calls need to stay below 5 per second 
(using 2 `elements' as this code does; see link above for explanation of elements). 
It will take about 8 minutes if you want to collect your daily allowance in one code run.

The API doesn't appear to require a key or a specific IP address, though the API page suggests it does. 
I'd be interested in hearing if it works for others.

To get it going, open the script in R and do the following:

* Set your working directory appropriately
* check the list of libraries are installed
* Put a single shapefile into the same folder, change the file name/location at:
```
gbmerge <- readOGR(dsn="GB_merged", "GB_merged") 
```
* (A shapefile for Great Britain is included).
* Depending on where you are, check you're converting to the right coordinate system
(currently UK national grid is being converted to lat-long):
```
randomPointOrigins <- spTransform(randomPointOrigins, CRS("+init=epsg:4326"))
randomPointDestinations <- spTransform(randomPointDestinations, CRS("+init=epsg:4326"))
```
* Change the proxy settings in the GET method (i.e. comment it out if not needed; currently set up for Leeds University LAN).
* Choose the number of random routes to pick on this run with:
```
pairNum = ...
```
* As mentioned above, Google says its daily limit is 2500 without having a business account. Note also, the CSV currently doesn't save until the end of the process.

Failed route finding attempts are stripped out so you'll probably get slightly less than the requested number. 
R will tell you how many failed when it finishes running.
