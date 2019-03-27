library(raster)


r0 <- raster('b2000_id.tif') # This raster has the id
r1 <- raster('b2005.tif')
r2 <- raster('b2017.tif')

# This is only use for the first raster to get the original 
# patched areas

oriArea <- function(ras){
  area <- tapply(area(ras), ras[], function(x) sum(x) / 100^2)
  ans <- data.frame(names(area), area)
  names(ans) <- c('id', deparse(substitute(ras)))
  return(ans)
}

# This is for the rest.
NewArea <- function(ras){
  r <- ras * r0 / 2   # This fucking line is the real deal
  area <- tapply(area(r), r[], function(x) sum(x) / 100^2) 
  ans <- data.frame(names(area), area)
  names(ans) <- c('id', deparse(substitute(ras)))
  return(ans)
}


# So this function returns 
# a dataframe with the id and the patch area
# so you'll have to do it year by year
# PS: Don't worry about the warning, it's 
# because of using UTM.

                 
# To measure run time
start_time <- Sys.time()                
                 
               
a00 <- oriArea(r0)
a05 <- NewArea(r1)
a17 <- NewArea(r2)

end_time <- Sys.time()

print(start_time -end_time)                 
                 
all.areas <- list(a00, a05, a17)
                 
a <- Reduce(function(x, y) merge(x, y, by = 'id', all = T),
            all.areas)

# If it gave you NA, it means it's gone...
# If you don't like the NA try:
# a[is.na(a)] <- 0

# done
# I want a raise
