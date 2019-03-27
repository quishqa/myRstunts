library(raster)
library(rgdal)
library(rasterVis)
library(sp)

r0 <- raster('b2000_id.tif')
r1 <- raster('b2005.tif')
r2 <- raster('b2017.tif')

# This is only use for the first raster to get the areas
oriArea <- function(ras){
  area <- tapply(area(ras), ras[], sum)
  ans <- data.frame(id = names(area), area = area)
  return(ans)
}

# This is for the rest.
NewArea <- function(ras){
  r <- ras * r0 / 2   # This fucking line is the real deal
  area <- tapply(area(r), r[], sum) # this 
  ans <- data.frame(id = names(area), area = area)
  return(ans)
}


# A muestra 
a00 <- oriArea(r0)
a05 <- NewArea(r1)
a17 <- NewArea(r2)
